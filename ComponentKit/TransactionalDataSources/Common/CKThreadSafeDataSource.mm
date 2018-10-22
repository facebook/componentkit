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
#import "CKDataSourceItem.h"
#import "CKDataSourceListenerAnnouncer.h"
#import "CKDataSourceQOSHelper.h"
#import "CKDataSourceReloadModification.h"
#import "CKDataSourceStateInternal.h"
#import "CKDataSourceStateModifying.h"
#import "CKDataSourceUpdateConfigurationModification.h"
#import "CKDataSourceUpdateStateModification.h"
#import "CKMutex.h"

@interface CKThreadSafeDataSource () <CKComponentStateListener, CKComponentDebugReflowListener>
{
  CKDataSourceState *_state;
  CK::Mutex _stateMutex;

  CKComponentStateUpdatesMap _pendingAsynchronousStateUpdates;
  CKComponentStateUpdatesMap _pendingSynchronousStateUpdates;
  CK::Mutex _pendingStateUpdatesMutex;

  CK::Mutex _processingMutex;

  CKDataSourceListenerAnnouncer *_announcer;
  dispatch_queue_t _workQueue;
}
@end

@implementation CKThreadSafeDataSource

- (instancetype)initWithConfiguration:(CKDataSourceConfiguration *)configuration
{
  CKAssertNotNil(configuration, @"Configuration is required");
  if (self = [super init]) {
    _state = [[CKDataSourceState alloc] initWithConfiguration:configuration sections:@[]];
    _announcer = [[CKDataSourceListenerAnnouncer alloc] init];
    _workQueue = dispatch_queue_create("org.componentkit.CKThreadSafeDataSource", DISPATCH_QUEUE_SERIAL);

    [CKComponentDebugController registerReflowListener:self];
  }
  return self;
}

- (void)dealloc
{
  // We want to ensure that controller invalidation is called on the main thread
  // The chain of ownership is following: CKDataSourceState -> array of CKDataSourceItem-> ScopeRoot -> controllers.
  // We delay desctruction of DataSourceState to guarantee that controllers are alive.
  auto const state = self.state;
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
  CK::MutexLocker lock(_stateMutex);
  return _state;
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
  CK::MutexLocker lock(_pendingStateUpdatesMutex);
  if (_pendingAsynchronousStateUpdates.empty() && _pendingSynchronousStateUpdates.empty()) {
    dispatch_async(_workQueue, ^{
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

- (void)_applyModificationAsync:(id<CKDataSourceStateModifying>)modification
{
  _processingMutex.lock();
  dispatch_async(_workQueue, blockUsingDataSourceQOS(^{
    [_announcer componentDataSourceWillGenerateNewState:self userInfo:modification.userInfo];
    auto change = [self _changeFromModification:modification];
    [_announcer componentDataSource:self
                didGenerateNewState:[change state]
                            changes:[change appliedChanges]];
    [self _applyChange:change];
    _processingMutex.unlock();
  }, [modification qos]));
}

- (void)_applyModificationSync:(id<CKDataSourceStateModifying>)modification
{
  CK::MutexLocker lock(_processingMutex);
  dispatch_async(dispatch_get_main_queue(), ^{
    [_announcer componentDataSource:self willSyncApplyModificationWithUserInfo:[modification userInfo]];
  });
  auto change = [self _changeFromModification:modification];
  [self _applyChange:change];
}

- (CKDataSourceChange *)_changeFromModification:(id<CKDataSourceStateModifying>)modification
{
#if CK_ASSERTIONS_ENABLED
  if ([modification isKindOfClass:[CKDataSourceChangesetModification class]]) {
    verifyChangeset(((CKDataSourceChangesetModification *)modification).changeset, self.state);
  }
#endif

  auto const state = self.state;
  CKDataSourceChange *change = nil;
  @autoreleasepool {
    change = [modification changeFromState:state];
  }
  return change;
}

- (void)_applyChange:(CKDataSourceChange *)change
{
  auto const previousState = self.state;
  auto const newState = change.state;
  {
    CK::MutexLocker lock(_stateMutex);
    _state = newState;
  }

  dispatch_async(dispatch_get_main_queue(), ^{
    auto const appliedChanges = change.appliedChanges;
    // Announce 'invalidateController'.
    for (NSIndexPath *const removedIndex in appliedChanges.removedIndexPaths) {
      CKDataSourceItem *removedItem = [previousState objectAtIndexPath:removedIndex];
      CKComponentScopeRootAnnounceControllerInvalidation([removedItem scopeRoot]);
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
  CKDataSourceUpdateStateModification *asyncStateUpdateModification = nil;
  CKDataSourceUpdateStateModification *syncStateUpdateModification = nil;
  {
    CK::MutexLocker lock(_pendingStateUpdatesMutex);
    if (!_pendingAsynchronousStateUpdates.empty()) {
      asyncStateUpdateModification =
      [[CKDataSourceUpdateStateModification alloc] initWithStateUpdates:_pendingAsynchronousStateUpdates];
      _pendingAsynchronousStateUpdates.clear();
    }
    if (!_pendingSynchronousStateUpdates.empty()) {
      syncStateUpdateModification =
      [[CKDataSourceUpdateStateModification alloc] initWithStateUpdates:_pendingSynchronousStateUpdates];
      _pendingSynchronousStateUpdates.clear();
    }
  }
  
  if (asyncStateUpdateModification != nil) {
    [self _applyModificationAsync:asyncStateUpdateModification];
  }
  if (syncStateUpdateModification != nil) {
    [self _applyModificationSync:syncStateUpdateModification];
  }
}

#if CK_ASSERTIONS_ENABLED
static void verifyChangeset(CKDataSourceChangeset *changeset,
                            CKDataSourceState *state)
{
  const CKInvalidChangesetInfo invalidChangesetInfo = CKIsValidChangesetForState(changeset,
                                                                                 state,
                                                                                 @[]);
  if (invalidChangesetInfo.operationType != CKInvalidChangesetOperationTypeNone) {
    NSString *const humanReadableInvalidChangesetOperationType = CKHumanReadableInvalidChangesetOperationType(invalidChangesetInfo.operationType);
    CKCFatalWithCategory(humanReadableInvalidChangesetOperationType, @"Invalid changeset: %@\n*** Changeset:\n%@\n*** Data source state:\n%@\n*** Invalid section:\n%ld\n*** Invalid item:\n%ld", humanReadableInvalidChangesetOperationType, changeset, state, (long)invalidChangesetInfo.section, (long)invalidChangesetInfo.item);
  }
}
#endif

@end
