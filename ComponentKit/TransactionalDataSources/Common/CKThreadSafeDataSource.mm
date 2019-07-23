/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKThreadSafeDataSource.h"

#import "CKThreadSafeDataSourceInternal.h"
#import "CKComponentControllerEvents.h"
#import "CKComponentEvents.h"
#import "CKComponentControllerInternal.h"
#import "CKComponentDebugController.h"
#import "CKComponentScopeRoot.h"
#import "CKComponentSubclass.h"
#import "CKDataSourceAppliedChanges.h"
#import "CKDataSourceChange.h"
#import "CKDataSourceChangeset.h"
#import "CKDataSourceChangesetModification.h"
#import "CKDataSourceChangesetVerification.h"
#import "CKDataSourceConfigurationInternal.h"
#import "CKDataSourceItem.h"
#import "CKDataSourceListenerAnnouncer.h"
#import "CKDataSourceQOSHelper.h"
#import "CKDataSourceReloadModification.h"
#import "CKDataSourceStateInternal.h"
#import "CKDataSourceStateModifying.h"
#import "CKDataSourceUpdateConfigurationModification.h"
#import "CKDataSourceUpdateStateModification.h"
#import "CKMutex.h"

#if CK_ASSERTIONS_ENABLED
static void *kWorkQueueKey = &kWorkQueueKey;
#define CKAssertWorkQueue() CKAssert(dispatch_get_specific(kWorkQueueKey) == kWorkQueueKey, @"This method must be called on the work queue")
#else
#define CKAssertWorkQueue()
#endif

@interface CKThreadSafeDataSource () <CKComponentDebugReflowListener>
{
  CKDataSourceState *_state;

  CKComponentStateUpdatesMap _pendingAsynchronousStateUpdates;
  CKComponentStateUpdatesMap _pendingSynchronousStateUpdates;

  CKDataSourceListenerAnnouncer *_announcer;
  dispatch_queue_t _workQueue;
}
@end

@implementation CKThreadSafeDataSource

- (instancetype)initWithConfiguration:(CKDataSourceConfiguration *)configuration
{
  return [self initWithState:[[CKDataSourceState alloc] initWithConfiguration:configuration sections:@[]]];
}

- (instancetype)initWithState:(CKDataSourceState *)state
{
  CKAssertNotNil(state, @"Initial state is required");
  CKAssertNotNil(state.configuration, @"Configuration is required");
  CKAssert(!state.configuration.options.splitChangesetOptions.enabled, @"CKThreadSafeDataSource doesn't support `splitChangesetOptions`");
  if (self = [super init]) {
    _state = state;
    _announcer = [[CKDataSourceListenerAnnouncer alloc] init];
    _workQueue = dispatch_queue_create("org.componentkit.CKThreadSafeDataSource", DISPATCH_QUEUE_SERIAL);

    [CKComponentDebugController registerReflowListener:self];

#if CK_ASSERTIONS_ENABLED
    dispatch_queue_set_specific(_workQueue, kWorkQueueKey, kWorkQueueKey, NULL);
#endif
  }
  return self;
}

- (void)dealloc
{
  // We want to ensure that controller invalidation is called on the main thread
  // The chain of ownership is following: CKDataSourceState -> array of CKDataSourceItem-> ScopeRoot -> controllers.
  // We delay desctruction of DataSourceState to guarantee that controllers are alive.
  auto const state = _state;
  void (^completion)() = ^() {
    [state enumerateObjectsUsingBlock:^(CKDataSourceItem *item, NSIndexPath *, BOOL *stop) {
      CKComponentScopeRootAnnounceControllerInvalidation([item scopeRoot]);
    }];
  };
  if ([NSThread isMainThread]) {
    completion();
  } else {
    dispatch_async(dispatch_get_main_queue(), completion);
  }
}

- (void)applyChangeset:(CKDataSourceChangeset *)changeset
                  mode:(CKUpdateMode)mode
              userInfo:(NSDictionary *)userInfo
{
  [self applyChangeset:changeset mode:mode qos:CKDataSourceQOSDefault userInfo:userInfo];
}

- (void)applyChangeset:(CKDataSourceChangeset *)changeset
                  mode:(CKUpdateMode)mode
                   qos:(CKDataSourceQOS)qos
              userInfo:(NSDictionary *)userInfo
{
  auto const modification = [[CKDataSourceChangesetModification alloc]
                             initWithChangeset:changeset
                             stateListener:self
                             userInfo:userInfo
                             qos:qos];
  switch (mode) {
    case CKUpdateModeAsynchronous:
      [self _applyModificationAsync:modification];
      break;
    case CKUpdateModeSynchronous:
      [self _applyModificationSync:modification];
      break;
  }
}

- (void)updateConfiguration:(CKDataSourceConfiguration *)configuration
                       mode:(CKUpdateMode)mode
                   userInfo:(NSDictionary *)userInfo
{
  auto const modification = [[CKDataSourceUpdateConfigurationModification alloc]
                             initWithConfiguration:configuration
                             userInfo:userInfo];
  switch (mode) {
    case CKUpdateModeAsynchronous:
      [self _applyModificationAsync:modification];
      break;
    case CKUpdateModeSynchronous:
      [self _applyModificationSync:modification];
      break;
  }
}

- (void)reloadWithMode:(CKUpdateMode)mode
              userInfo:(NSDictionary *)userInfo
{
  auto const modification = [[CKDataSourceReloadModification alloc]
                             initWithUserInfo:userInfo];
  switch (mode) {
    case CKUpdateModeAsynchronous:
      [self _applyModificationAsync:modification];
      break;
    case CKUpdateModeSynchronous:
      [self _applyModificationSync:modification];
      break;
  }
}

- (BOOL)applyChange:(CKDataSourceChange *)change
{
  __block BOOL isApplied = NO;
  dispatch_sync(_workQueue, ^{
    if (_state != change.previousState) {
      return;
    }
    [self _applyChange:change];
    isApplied = YES;
  });
  return isApplied;
}

- (BOOL)verifyChange:(CKDataSourceChange *)change
{
  __block BOOL isValid = NO;
  dispatch_sync(_workQueue, ^{
    isValid = _state == change.previousState;
  });
  return isValid;
}

- (void)setViewport:(CKDataSourceViewport)viewport {}

- (void)addListener:(id<CKDataSourceListener>)listener
{
  [_announcer addListener:listener];
}

- (void)removeListener:(id<CKDataSourceListener>)listener
{
  [_announcer removeListener:listener];
}

#pragma mark - State Listener

- (void)componentScopeHandle:(CKComponentScopeHandle *)handle
              rootIdentifier:(CKComponentScopeRootIdentifier)rootIdentifier
       didReceiveStateUpdate:(id (^)(id))stateUpdate
                    metadata:(const CKStateUpdateMetadata)metadata
                        mode:(CKUpdateMode)mode
{
  CKAssertMainThread();
  if (_pendingAsynchronousStateUpdates.empty() && _pendingSynchronousStateUpdates.empty()) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self _processStateUpdates];
    });
  }
  if (mode == CKUpdateModeAsynchronous) {
    _pendingAsynchronousStateUpdates[rootIdentifier][handle].push_back(stateUpdate);
  } else {
    _pendingSynchronousStateUpdates[rootIdentifier][handle].push_back(stateUpdate);
  }
}

#pragma mark - CKComponentDebugReflowListener

- (void)didReceiveReflowComponentsRequest
{
  [self reloadWithMode:CKUpdateModeAsynchronous userInfo:nil];
}

- (void)didReceiveReflowComponentsRequestWithTreeNodeIdentifier:(CKTreeNodeIdentifier)treeNodeIdentifier
{
  __block NSIndexPath *ip = nil;
  __block id model = nil;
  dispatch_sync(_workQueue, ^{
    [_state enumerateObjectsUsingBlock:^(CKDataSourceItem *item, NSIndexPath *indexPath, BOOL *stop) {
      if (item.scopeRoot.rootNode.parentForNodeIdentifier(treeNodeIdentifier) != nil) {
        ip = indexPath;
        model = item.model;
        *stop = YES;
      }
    }];
  });
  if (ip != nil) {
    const auto changeset = [[[CKDataSourceChangesetBuilder dataSourceChangeset] withUpdatedItems:@{ip: model}] build];
    [self applyChangeset:changeset mode:CKUpdateModeSynchronous userInfo:@{}];
  }
}

#pragma mark - Internal

- (void)_applyModificationAsync:(id<CKDataSourceStateModifying>)modification
{
  dispatch_async(_workQueue, blockUsingDataSourceQOS(^{
    [_announcer componentDataSourceWillGenerateNewState:self userInfo:modification.userInfo];
    auto change = [self _changeFromModification:modification];
    [_announcer componentDataSource:self
                didGenerateNewState:[change state]
                            changes:[change appliedChanges]];
    [self _applyChange:change];
  }, [modification qos]));
}

- (void)_applyModificationSync:(id<CKDataSourceStateModifying>)modification
{
  dispatch_sync(_workQueue, blockUsingDataSourceQOS(^{
    dispatch_async(dispatch_get_main_queue(), ^{
      [_announcer componentDataSource:self willSyncApplyModificationWithUserInfo:[modification userInfo]];
    });
    auto change = [self _changeFromModification:modification];
    [self _applyChange:change];
  }, [modification qos]));
}

- (CKDataSourceChange *)_changeFromModification:(id<CKDataSourceStateModifying>)modification
{
#if CK_ASSERTIONS_ENABLED
  if ([modification isKindOfClass:[CKDataSourceChangesetModification class]]) {
    CKVerifyChangeset(((CKDataSourceChangesetModification *)modification).changeset, _state, @[]);
  }
#endif
  CKDataSourceChange *change = nil;
  @autoreleasepool {
    change = [modification changeFromState:_state];
  }
  return change;
}

- (void)_applyChange:(CKDataSourceChange *)change
{
  CKAssertWorkQueue();
  
  auto const previousState = _state;
  auto const newState = change.state;
  _state = newState;

  dispatch_async(dispatch_get_main_queue(), ^{
    auto const appliedChanges = change.appliedChanges;
    // Announce 'invalidateController'.
    for (CKComponentController *const componentController in change.invalidComponentControllers) {
      [componentController invalidateController];
    }
    for (NSIndexPath *const removedIndex in appliedChanges.removedIndexPaths) {
      CKDataSourceItem *removedItem = [previousState objectAtIndexPath:removedIndex];
      CKComponentScopeRootAnnounceControllerInvalidation([removedItem scopeRoot]);
    }
    if (newState.configuration.options.updateComponentInControllerAfterBuild) {
      CKComponentUpdateComponentForComponentControllerWithIndexPaths(appliedChanges.finalUpdatedIndexPaths.allValues, newState);
    }

    [_announcer componentDataSource:self
             didModifyPreviousState:previousState
                          withState:newState
                  byApplyingChanges:appliedChanges];

    // Announce 'didPrepareLayoutForComponent:'.
    CKComponentSendDidPrepareLayoutForComponentsWithIndexPaths([[appliedChanges finalUpdatedIndexPaths] allValues], newState);
    CKComponentSendDidPrepareLayoutForComponentsWithIndexPaths([appliedChanges insertedIndexPaths], newState);
  });
}

- (void)_processStateUpdates
{
  if (!_pendingAsynchronousStateUpdates.empty()) {
    CKDataSourceUpdateStateModification *asyncStateUpdateModification =
    [[CKDataSourceUpdateStateModification alloc] initWithStateUpdates:_pendingAsynchronousStateUpdates];
    _pendingAsynchronousStateUpdates.clear();
    [self _applyModificationAsync:asyncStateUpdateModification];
  }
  if (!_pendingSynchronousStateUpdates.empty()) {
    CKDataSourceUpdateStateModification *syncStateUpdateModification =
    [[CKDataSourceUpdateStateModification alloc] initWithStateUpdates:_pendingSynchronousStateUpdates];
    _pendingSynchronousStateUpdates.clear();
    [self _applyModificationSync:syncStateUpdateModification];
  }
}

@end
