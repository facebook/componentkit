/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKDataSourceChangesetApplicator.h"

#import <libkern/OSAtomic.h>
#import <vector>

#import <ComponentKit/CKDataSourceAppliedChanges.h>
#import <ComponentKit/CKDataSourceChange.h>
#import <ComponentKit/CKDataSourceChangesetModification.h>
#import <ComponentKit/CKDataSourceInternal.h>
#import <ComponentKit/CKDataSourceListener.h>
#import <ComponentKit/CKDataSourceModificationHelper.h>
#import <ComponentKit/CKDataSourceQOSHelper.h>
#import <ComponentKit/CKDataSourceState.h>

static void *kQueueKey = &kQueueKey;
static NSString *const kChangesetApplicatorIdUserInfoKey = @"CKDataSourceChangesetApplicator.Id";
static int32_t globalChangesetApplicatorId = 0;

struct CKDataSourceChangesetApplicatorPipelineItem {
  CKDataSourceChangeset *changeset;
  NSDictionary *userInfo;
  CKDataSourceQOS qos;
};

@interface CKDataSourceChangesetApplicator () <CKDataSourceChangesetModificationItemGenerator, CKDataSourceListener>

@end

@implementation CKDataSourceChangesetApplicator
{
  __weak CKDataSource *_dataSource;
  CKDataSourceState *_dataSourceState;
  dispatch_queue_t _queue;
  NSNumber *_changesetApplicatorId;

  std::vector<CKDataSourceChangesetApplicatorPipelineItem> _pipeline;
  NSUInteger _pipelineId;

  NSMapTable<CKDataSourceChangeset *, NSMapTable<id, CKDataSourceItem *> *> *_dataSourceItemCache;
  CKDataSourceChangeset *_currentChangeset;
}

- (instancetype)initWithDataSource:(CKDataSource *)dataSource
                   dataSourceState:(CKDataSourceState *)dataSourceState
                             queue:(dispatch_queue_t)queue
{
  if (self = [super init]) {
    _dataSource = dataSource;
    _dataSourceState = dataSourceState;
    _queue = queue;
    _changesetApplicatorId = @(OSAtomicIncrement32(&globalChangesetApplicatorId));
    [_dataSource addListener:self];

    CKAssertNotNil(_queue, @"A dispatch queue must be specified for changeset applicator.");
    CKAssert(dispatch_queue_get_specific(_queue, kQueueKey) == NULL,
             @"Sharing queue between changeset applicators is not allowed.");
    dispatch_queue_set_specific(_queue, kQueueKey, kQueueKey, NULL);

    _dataSourceItemCache = _createMapTable();
  }
  return self;
}

- (void)dealloc
{
  dispatch_queue_set_specific(_queue, kQueueKey, NULL, NULL);
}

- (void)applyChangeset:(CKDataSourceChangeset *)changeset
              userInfo:(NSDictionary *)userInfo
                   qos:(CKDataSourceQOS)qos
{
  if (!_isRunningOnQueue()) {
    dispatch_async(_queue, blockUsingDataSourceQOS(^{
      [self applyChangeset:changeset userInfo:userInfo qos:qos];
    }, qos));
    return;
  }

  dispatch_async(dispatch_get_main_queue(), ^{
    self->_dataSource.shouldPauseStateUpdates = YES;
  });

  _pipeline.push_back({changeset, userInfo, qos});
  userInfo = _mergeUserInfoWithChangesetApplicatorId(userInfo, _changesetApplicatorId);

  // `_currentChangeset` is used in `buildDataSourceItemForPreviousRoot` for querying item cache for inserted items.
  _currentChangeset = changeset;
  CKDataSourceChange *change = nil;
  {
    const auto modification =
    [[CKDataSourceChangesetModification alloc]
     initWithChangeset:changeset
     stateListener:_dataSource
     userInfo:userInfo qos:qos
     shouldValidateChangeset:NO];
    [modification setItemGenerator:self];
    @autoreleasepool {
      change = [modification changeFromState:_dataSourceState];
    }
  }
  _currentChangeset = nil;
  _dataSourceState = change.state;

  NSUInteger pipelineId = _pipelineId;
  dispatch_async(dispatch_get_main_queue(), ^{
    const auto dataSource = self->_dataSource;
    if (!dataSource) {
      // We should stop processing changesets if `dataSource` is already deallocated.
      return;
    }
    const auto isValid = [dataSource verifyChange:change];
    const auto newState = dataSource.state;
    dispatch_async(self->_queue, blockUsingDataSourceQOS(^{
      if (self->_pipelineId != pipelineId) {
        // We don't need to handle the result since the current pipeline was discarded.
        return;
      }
      if (isValid) {
        self->_pipeline.erase(self->_pipeline.begin());
        [self->_dataSourceItemCache removeObjectForKey:changeset];
        if (self->_pipeline.size() == 0) {
          dispatch_async(dispatch_get_main_queue(), ^{
            self->_dataSource.shouldPauseStateUpdates = NO;
          });
        }
      } else {
        [self createNewPipelineWithNewDataSourceState:newState];
      }
    }, qos));
    __unused const auto isApplied = [dataSource applyChange:change];
    CKCAssert(isApplied == isValid, @"`CKDataSourceChange` is verified but not able to be applied.");
  });
}

#pragma mark - Internal

static BOOL _isRunningOnQueue()
{
  return dispatch_get_specific(kQueueKey) == kQueueKey;
}

static NSMapTable *_createMapTable()
{
  return [[NSMapTable alloc]
          initWithKeyOptions:NSPointerFunctionsStrongMemory | NSPointerFunctionsObjectPointerPersonality
          valueOptions:NSPointerFunctionsStrongMemory
          capacity:10];
}

static NSDictionary *_mergeUserInfoWithChangesetApplicatorId(NSDictionary *userInfo,
                                                             NSNumber *changesetApplicatorId)
{
  NSMutableDictionary *mutableDictionary = [userInfo mutableCopy] ?: [NSMutableDictionary new];
  mutableDictionary[kChangesetApplicatorIdUserInfoKey] = changesetApplicatorId;
  return mutableDictionary;
}

- (void)createNewPipelineWithNewDataSourceState:(CKDataSourceState *)newState
{
  CKAssert(_isRunningOnQueue(), @"Pipeline must be created on process queue.");
  if (![_dataSourceState.configuration isEqual:newState.configuration]) {
    // Discard item cache if configuraiton is updated because `sizeRange` or `context` could affect layout.
    _dataSourceItemCache = _createMapTable();
  }
  _dataSourceState = newState;
  // A new pipeline is created and items in the existing pipeline are moved to the new one.
  _pipelineId++;
  const auto pipeline = _pipeline;
  _pipeline = {};
  for (const auto &item : pipeline) {
    [self applyChangeset:item.changeset userInfo:item.userInfo qos:item.qos];
  }
}

#pragma mark - CKDataSourceChangesetModificationItemGenerator

- (CKDataSourceItem *)buildDataSourceItemForPreviousRoot:(CKComponentScopeRoot *)previousRoot
                                            stateUpdates:(const CKComponentStateUpdateMap &)stateUpdates
                                               sizeRange:(const CKSizeRange &)sizeRange
                                           configuration:(CKDataSourceConfiguration *)configuration
                                                   model:(id)model
                                                 context:(id)context
                                                itemType:(CKDataSourceChangesetModificationItemType)itemType
{
  CKAssert(_isRunningOnQueue(), @"`CKDataSourceItem` should be generated on process queue.");
  if (itemType != CKDataSourceChangesetModificationItemTypeInsert) {
    return CKBuildDataSourceItem(previousRoot, stateUpdates, sizeRange, configuration, model, context);
  }
  auto itemCache = [_dataSourceItemCache objectForKey:_currentChangeset];
  if (!itemCache) {
    itemCache = _createMapTable();
    [_dataSourceItemCache setObject:itemCache forKey:_currentChangeset];
  }
  auto dataSourceItem = [itemCache objectForKey:model];
  if (!dataSourceItem) {
    dataSourceItem = CKBuildDataSourceItem(previousRoot, stateUpdates, sizeRange, configuration, model, context);
    [itemCache setObject:dataSourceItem forKey:model];
  }
  return dataSourceItem;
}

#pragma mark - CKDataSourceListener

- (void)dataSource:(CKDataSource *)dataSource
didModifyPreviousState:(CKDataSourceState *)previousState
         withState:(CKDataSourceState *)state
 byApplyingChanges:(CKDataSourceAppliedChanges *)changes
{
  // We don't need to handle new dataSource state that are coming from changeset applicator itself.
  if ([_changesetApplicatorId isEqual:changes.userInfo[kChangesetApplicatorIdUserInfoKey]]) {
    return;
  }
  dispatch_async(_queue, ^{
    [self createNewPipelineWithNewDataSourceState:state];
  });
}

- (void)dataSource:(CKDataSource *)dataSource
willApplyDeferredChangeset:(CKDataSourceChangeset *)deferredChangeset
{

}

@end
