/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKDataSource.h"
#import "CKDataSourceInternal.h"

#import "CKAssert.h"
#import "CKComponentControllerEvents.h"
#import "CKComponentEvents.h"
#import "CKComponentControllerInternal.h"
#import "CKComponentDebugController.h"
#import "CKComponentScopeRoot.h"
#import "CKComponentSubclass.h"
#import "CKDataSourceAppliedChanges.h"
#import "CKDataSourceChange.h"
#import "CKDataSourceChangesetModification.h"
#import "CKDataSourceChangesetVerification.h"
#import "CKDataSourceConfiguration.h"
#import "CKDataSourceConfigurationInternal.h"
#import "CKDataSourceItem.h"
#import "CKDataSourceListenerAnnouncer.h"
#import "CKDataSourceReloadModification.h"
#import "CKDataSourceStateInternal.h"
#import "CKDataSourceStateModifying.h"
#import "CKDataSourceUpdateConfigurationModification.h"
#import "CKDataSourceUpdateStateModification.h"

typedef NS_ENUM(NSInteger, NextPipelineState) {
  NextPipelineStateEmpty,
  NextPipelineStateCancelled,
  NextPipelineStateContinue,
};

@interface CKDataSourceModificationPair : NSObject

@property (nonatomic, strong, readonly) id<CKDataSourceStateModifying> modification;
@property (nonatomic, strong, readonly) CKDataSourceState *state;

- (instancetype)initWithModification:(id<CKDataSourceStateModifying>)modification
                               state:(CKDataSourceState *)state;

@end

@interface CKDataSource () <CKComponentStateListener, CKComponentDebugReflowListener>
{
  CKDataSourceState *_state;
  CKDataSourceListenerAnnouncer *_announcer;

  CKComponentStateUpdatesMap _pendingAsynchronousStateUpdates;
  CKComponentStateUpdatesMap _pendingSynchronousStateUpdates;

  NSMutableArray<id<CKDataSourceStateModifying>> *_pendingAsynchronousModifications;

  dispatch_queue_t _concurrentQueue;
}
@end

@implementation CKDataSource

- (instancetype)initWithConfiguration:(CKDataSourceConfiguration *)configuration
{
  CKAssertNotNil(configuration, @"Configuration is required");
  if (self = [super init]) {
    _state = [[CKDataSourceState alloc] initWithConfiguration:configuration sections:@[]];
    _announcer = [[CKDataSourceListenerAnnouncer alloc] init];

    if (!configuration.qosOptions.enabled) {
      _workQueue = dispatch_queue_create("org.componentkit.CKDataSource", DISPATCH_QUEUE_SERIAL);
    } else {
      auto const workQueueAttributes =
      dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, qosClassFromDataSourceQOS(configuration.qosOptions.workQueueQOS), 0);
      _workQueue = dispatch_queue_create("org.componentkit.CKDataSource", workQueueAttributes);
    }

    _pendingAsynchronousModifications = [NSMutableArray array];
    [CKComponentDebugController registerReflowListener:self];
    if (configuration.parallelInsertBuildAndLayout ||
        configuration.parallelUpdateBuildAndLayout) {
      if (!configuration.qosOptions.enabled) {
        _concurrentQueue = dispatch_queue_create("org.componentkit.CKDataSource.concurrent", DISPATCH_QUEUE_CONCURRENT);
      } else {
        auto const concurrentQueueAttributes =
        dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_CONCURRENT, qosClassFromDataSourceQOS(configuration.qosOptions.concurrentQueueQOS), 0);
        _concurrentQueue = dispatch_queue_create("org.componentkit.CKDataSource.concurrent", concurrentQueueAttributes);
      }
    }
  }
  return self;
}

- (void)dealloc
{
  // We want to ensure that controller invalidation is called on the main thread
  // The chain of ownership is following: CKDataSourceState -> array of CKDataSourceItem-> ScopeRoot -> controllers.
  // We delay desctruction of DataSourceState to guarantee that controllers are alive.
  CKDataSourceState *state = _state;
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

- (CKDataSourceState *)state
{
  CKAssertMainThread();
  return _state;
}

- (void)applyChangeset:(CKDataSourceChangeset *)changeset
                  mode:(CKUpdateMode)mode
              userInfo:(NSDictionary *)userInfo
{
  CKAssertMainThread();

  verifyChangeset(changeset, _state, _pendingAsynchronousModifications);

  id<CKDataSourceStateModifying> modification =
  [[CKDataSourceChangesetModification alloc] initWithChangeset:changeset
                                                 stateListener:self
                                                      userInfo:userInfo
                                                         queue:_concurrentQueue];
  switch (mode) {
    case CKUpdateModeAsynchronous:
      [self _enqueueModification:modification];
      break;
    case CKUpdateModeSynchronous:
      // We need to keep FIFO ordering of changesets, so cancel & synchronously apply any queued async modifications.
      NSArray *enqueuedChangesets = [self _cancelEnqueuedModificationsOfType:[modification class]];
      for (id<CKDataSourceStateModifying> pendingChangesetModification in enqueuedChangesets) {
        [self _synchronouslyApplyModification:pendingChangesetModification];
      }
      [self _synchronouslyApplyModification:modification];
      break;
  }
}

- (void)updateConfiguration:(CKDataSourceConfiguration *)configuration
                       mode:(CKUpdateMode)mode
                   userInfo:(NSDictionary *)userInfo
{
  CKAssertMainThread();
  id<CKDataSourceStateModifying> modification =
  [[CKDataSourceUpdateConfigurationModification alloc] initWithConfiguration:configuration userInfo:userInfo];
  switch (mode) {
    case CKUpdateModeAsynchronous:
      [self _enqueueModification:modification];
      break;
    case CKUpdateModeSynchronous:
      // Cancel all enqueued asynchronous configuration updates or they'll complete later and overwrite this one.
      [self _cancelEnqueuedModificationsOfType:[modification class]];
      [self _synchronouslyApplyModification:modification];
      break;
  }
}

- (void)reloadWithMode:(CKUpdateMode)mode
              userInfo:(NSDictionary *)userInfo
{
  CKAssertMainThread();
  id<CKDataSourceStateModifying> modification =
  [[CKDataSourceReloadModification alloc] initWithUserInfo:userInfo];
  switch (mode) {
    case CKUpdateModeAsynchronous:
      [self _enqueueModification:modification];
      break;
    case CKUpdateModeSynchronous:
      // Cancel previously enqueued reloads; we're reloading right now, so no need to subsequently reload again.
      [self _cancelEnqueuedModificationsOfType:[modification class]];
      [self _synchronouslyApplyModification:modification];
      break;
  }
}

- (void)addListener:(id<CKDataSourceListener>)listener
{
  CKAssertMainThread();
  [_announcer addListener:listener];
}

- (void)removeListener:(id<CKDataSourceListener>)listener
{
  CKAssertMainThread();
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

#pragma mark - Internal

- (void)_enqueueModification:(id<CKDataSourceStateModifying>)modification
{
  CKAssertMainThread();

  [_pendingAsynchronousModifications addObject:modification];
  if (_pendingAsynchronousModifications.count == 1) {
    [self _startAsynchronousModificationIfNeeded];
  }
}

- (void)_startAsynchronousModificationIfNeeded
{
  CKAssertMainThread();

  if (_pendingAsynchronousModifications.count > 0) {
    CKDataSourceModificationPair *modificationPair =
    [[CKDataSourceModificationPair alloc]
     initWithModification:_pendingAsynchronousModifications.firstObject
     state:_state];
    dispatch_async(_workQueue, ^{
      [self _applyModificationPair:modificationPair];
    });
  }
}

/** Returns the canceled matching modifications, in the order they would have been applied. */
- (NSArray *)_cancelEnqueuedModificationsOfType:(Class)modificationType
{
  CKAssertMainThread();

  NSIndexSet *indexes = [_pendingAsynchronousModifications indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
    return [obj isKindOfClass:modificationType];
  }];
  NSArray *modifications = [_pendingAsynchronousModifications objectsAtIndexes:indexes];
  [_pendingAsynchronousModifications removeObjectsAtIndexes:indexes];

  return modifications;
}

- (void)_synchronouslyApplyModification:(id<CKDataSourceStateModifying>)modification
{
  [_announcer componentDataSource:self willSyncApplyModificationWithUserInfo:[modification userInfo]];
  [self _synchronouslyApplyChange:[modification changeFromState:_state]];
}

- (void)_synchronouslyApplyChange:(CKDataSourceChange *)change
{
  CKAssertMainThread();
  CKDataSourceState *previousState = _state;
  _state = [change state];

  // Announce 'invalidateController'.
  for (NSIndexPath *removedIndex in [[change appliedChanges] removedIndexPaths]) {
    CKDataSourceItem *removedItem = [previousState objectAtIndexPath:removedIndex];
    CKComponentScopeRootAnnounceControllerInvalidation([removedItem scopeRoot]);
  }

  [_announcer componentDataSource:self
           didModifyPreviousState:previousState
                byApplyingChanges:[change appliedChanges]];

  // Announce 'didPrepareLayoutForComponent:'.
  auto const appliedChanges = [change appliedChanges];
  sendDidPrepareLayoutForComponentWithIndexPaths([[appliedChanges finalUpdatedIndexPaths] allValues], _state);
  sendDidPrepareLayoutForComponentWithIndexPaths([appliedChanges insertedIndexPaths], _state);
}

- (void)_processStateUpdates
{
  CKAssertMainThread();
  if (!_pendingAsynchronousStateUpdates.empty()) {
    CKDataSourceUpdateStateModification *sm =
    [[CKDataSourceUpdateStateModification alloc] initWithStateUpdates:_pendingAsynchronousStateUpdates];
    _pendingAsynchronousStateUpdates.clear();
    [self _enqueueModification:sm];
  }
  if (!_pendingSynchronousStateUpdates.empty()) {
    CKDataSourceUpdateStateModification *sm =
    [[CKDataSourceUpdateStateModification alloc] initWithStateUpdates:_pendingSynchronousStateUpdates];
    _pendingSynchronousStateUpdates.clear();
    [self _synchronouslyApplyModification:sm];
  }
}

- (void)_applyModificationPair:(CKDataSourceModificationPair *)modificationPair
{
  [_announcer componentDataSourceWillGenerateNewState:self userInfo:modificationPair.modification.userInfo];
  CKDataSourceChange *change;
  @autoreleasepool {
    change = [modificationPair.modification changeFromState:modificationPair.state];
  }
  [_announcer componentDataSource:self
              didGenerateNewState:[change state]
                          changes:[change appliedChanges]];

  dispatch_async(dispatch_get_main_queue(), ^{
    // If the first object in _pendingAsynchronousModifications is not still the modification,
    // it may have been canceled; don't apply it.
    if ([_pendingAsynchronousModifications firstObject] == modificationPair.modification && self->_state == modificationPair.state) {
      [_pendingAsynchronousModifications removeObjectAtIndex:0];
      [self _synchronouslyApplyChange:change];
    }

    [self _startAsynchronousModificationIfNeeded];
  });
}

static void verifyChangeset(CKDataSourceChangeset *changeset,
                            CKDataSourceState *state,
                            NSArray<id<CKDataSourceStateModifying>> *pendingAsynchronousModifications)
{
#if CK_ASSERTIONS_ENABLED
  const CKInvalidChangesetInfo invalidChangesetInfo = CKIsValidChangesetForState(changeset,
                                                                                 state,
                                                                                 pendingAsynchronousModifications);
  if (invalidChangesetInfo.operationType != CKInvalidChangesetOperationTypeNone) {
    NSString *const humanReadableInvalidChangesetOperationType = CKHumanReadableInvalidChangesetOperationType(invalidChangesetInfo.operationType);
    NSString *const humanReadablePendingAsynchronousModifications = readableStringForArray(pendingAsynchronousModifications);
    CKCFatalWithCategory(humanReadableInvalidChangesetOperationType, @"Invalid changeset: %@\n*** Changeset:\n%@\n*** Data source state:\n%@\n*** Pending data source modifications:\n%@\n*** Invalid section:\n%ld\n*** Invalid item:\n%ld", humanReadableInvalidChangesetOperationType, changeset, state, humanReadablePendingAsynchronousModifications, (long)invalidChangesetInfo.section, (long)invalidChangesetInfo.item);
  }
#endif
}

#if CK_ASSERTIONS_ENABLED
static NSString *readableStringForArray(NSArray *array)
{
  if (!array || array.count == 0) {
    return @"()";
  }
  NSMutableString *mutableString = [NSMutableString new];
  [mutableString appendFormat:@"(\n"];
  for (id value in array) {
    [mutableString appendFormat:@"\t%@,\n", value];
  }
  [mutableString appendString:@")\n"];
  return mutableString;
}
#endif

static void sendDidPrepareLayoutForComponentWithIndexPaths(id<NSFastEnumeration> indexPaths,
                                                           CKDataSourceState*state)
{
  for (NSIndexPath *indexPath in indexPaths) {
    CKDataSourceItem *item = [state objectAtIndexPath:indexPath];
    CKComponentSendDidPrepareLayoutForComponent(item.scopeRoot, item.rootLayout);
  }
}

static qos_class_t qosClassFromDataSourceQOS(CKDataSourceQOS qos)
{
  switch (qos) {
    case CKDataSourceQOSUserInteractive:
      return QOS_CLASS_USER_INTERACTIVE;
    case CKDataSourceQOSUserInitiated:
      return QOS_CLASS_USER_INITIATED;
    case CKDataSourceQOSDefault:
      return QOS_CLASS_DEFAULT;
  }
}

@end

@implementation CKDataSourceModificationPair

- (instancetype)initWithModification:(id<CKDataSourceStateModifying>)modification
                               state:(CKDataSourceState *)state
{
  if (self = [super init]) {
    _modification = modification;
    _state = state;
  }
  return self;
}

@end
