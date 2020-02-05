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


#import <ComponentKit/CKMutex.h>
#import <ComponentKit/CKRootTreeNode.h>

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
#import "CKDataSourceConfiguration.h"
#import "CKDataSourceConfigurationInternal.h"
#import "CKDataSourceItem.h"
#import "CKDataSourceListenerAnnouncer.h"
#import "CKDataSourceQOSHelper.h"
#import "CKDataSourceReloadModification.h"
#import "CKDataSourceSplitChangesetModification.h"
#import "CKDataSourceStateInternal.h"
#import "CKDataSourceStateModifying.h"
#import "CKDataSourceUpdateConfigurationModification.h"
#import "CKDataSourceUpdateStateModification.h"
#import "CKSystraceScope.h"

@interface CKDataSourceModificationPair : NSObject

@property (nonatomic, strong, readonly) id<CKDataSourceStateModifying> modification;
@property (nonatomic, strong, readonly) CKDataSourceState *state;

- (instancetype)initWithModification:(id<CKDataSourceStateModifying>)modification
                               state:(CKDataSourceState *)state;

@end

@interface CKDataSource () <CKComponentDebugReflowListener>
{
  CKDataSourceState *_state;
  CKDataSourceListenerAnnouncer *_announcer;

  CKComponentStateUpdatesMap _pendingAsynchronousStateUpdates;
  CKComponentStateUpdatesMap _pendingSynchronousStateUpdates;
  NSMutableArray<id<CKDataSourceStateModifying>> *_pendingAsynchronousModifications;
  BOOL _processingAsynchronousModification;
  BOOL _shouldPauseStateUpdates;
  BOOL _isBackgroundMode;
  dispatch_queue_t _workQueue;

  CKDataSourceViewport _viewport;
  BOOL _changesetSplittingEnabled;
}
@end

@implementation CKDataSource

- (instancetype)initWithConfiguration:(CKDataSourceConfiguration *)configuration
{
  return [self initWithState:[[CKDataSourceState alloc] initWithConfiguration:configuration sections:@[]]];
}

- (instancetype)initWithState:(CKDataSourceState *)state
{
  CKAssertNotNil(state, @"Initial state is required");
  CKAssertNotNil(state.configuration, @"Configuration is required");
  if (self = [super init]) {
    const auto configuration = state.configuration;
    _state = state;
    _announcer = [[CKDataSourceListenerAnnouncer alloc] init];

    _workQueue = dispatch_queue_create("org.componentkit.CKDataSource", DISPATCH_QUEUE_SERIAL);
    _pendingAsynchronousModifications = [NSMutableArray array];
    _changesetSplittingEnabled = configuration.options.splitChangesetOptions.enabled;
    [CKComponentDebugController registerReflowListener:self];
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
  [self applyChangeset:changeset mode:mode qos:CKDataSourceQOSDefault userInfo:userInfo];
}

- (void)applyChangeset:(CKDataSourceChangeset *)changeset
                  mode:(CKUpdateMode)mode
                   qos:(CKDataSourceQOS)qos
              userInfo:(NSDictionary *)userInfo
{
  CKAssertMainThread();

#if CK_ASSERTIONS_ENABLED
  CKVerifyChangeset(changeset, _state, _pendingAsynchronousModifications);
#endif

  id<CKDataSourceStateModifying> const modification =
  [self _changesetGenerationModificationForChangeset:changeset
                                            userInfo:userInfo
                                                 qos:qos
                                 isDeferredChangeset:NO];

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

- (BOOL)applyChange:(CKDataSourceChange *)change
{
  CKAssertMainThread();
  if (![self verifyChange:change]) {
    return NO;
  }
  [self _synchronouslyApplyChange:change qos:CKDataSourceQOSDefault];
  return YES;
}

- (BOOL)verifyChange:(CKDataSourceChange *)change
{
  CKAssertMainThread();
  // We don't check `_pendingAsynchronousModifications` here because we want pre-computed `CKDataSourceChange`
  // to have higher chance to be applied. Asynchronous modifications will be re-applied anyway if they fail.
  return change.previousState == _state;
}

- (void)setViewport:(CKDataSourceViewport)viewport
{
  CKAssertMainThread();
  if (!_changesetSplittingEnabled) {
    return;
  }
  _viewport = viewport;
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

- (void)setShouldPauseStateUpdates:(BOOL)shouldPauseStateUpdates
{
  CKAssertMainThread();
  _shouldPauseStateUpdates = shouldPauseStateUpdates;
  if (!_shouldPauseStateUpdates) {
    [self _processStateUpdates];
  }
}

- (BOOL)shouldPauseStateUpdates
{
  CKAssertMainThread();
  return _shouldPauseStateUpdates;
}

- (void)setIsBackgroundMode:(BOOL)isBackgroundMode
{
  CKAssertMainThread();
  _isBackgroundMode = isBackgroundMode;
}

- (BOOL)isBackgroundMode
{
  CKAssertMainThread();
  return _isBackgroundMode;
}

#pragma mark - State Listener

- (void)componentScopeHandle:(CKComponentScopeHandle *)handle
              rootIdentifier:(CKComponentScopeRootIdentifier)rootIdentifier
       didReceiveStateUpdate:(id (^)(id))stateUpdate
                    metadata:(const CKStateUpdateMetadata &)metadata
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
  [_state enumerateObjectsUsingBlock:^(CKDataSourceItem *item, NSIndexPath *indexPath, BOOL *stop) {
    if (item.scopeRoot.rootNode.parentForNodeIdentifier(treeNodeIdentifier) != nil) {
      ip = indexPath;
      model = item.model;
      *stop = YES;
    }
  }];
  if (ip != nil) {
    const auto changeset = [[[CKDataSourceChangesetBuilder dataSourceChangeset] withUpdatedItems:@{ip: model}] build];
    [self applyChangeset:changeset mode:CKUpdateModeSynchronous userInfo:@{}];
  }
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

  id<CKDataSourceStateModifying> modification = _pendingAsynchronousModifications.firstObject;
  if (!_processingAsynchronousModification && _pendingAsynchronousModifications.count > 0) {
    _processingAsynchronousModification = YES;
    CKDataSourceModificationPair *modificationPair =
    [[CKDataSourceModificationPair alloc]
     initWithModification:modification
     state:_state];

    auto const asyncModification = CK::Analytics::willStartAsyncBlock(CK::Analytics::BlockName::DataSourceWillStartModification);
    dispatch_block_t block = blockUsingDataSourceQOS(^{
      CKSystraceScope modificationScope(asyncModification);
      [self _applyModificationPair:modificationPair];
    }, [modification qos], _isBackgroundMode);

    dispatch_async(_workQueue, block);
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
  [_announcer dataSource:self willSyncApplyModificationWithUserInfo:[modification userInfo]];
  [self _synchronouslyApplyChange:[modification changeFromState:_state] qos:modification.qos];
}

- (void)_synchronouslyApplyChange:(CKDataSourceChange *)change qos:(CKDataSourceQOS)qos
{
  CKAssertMainThread();
  CKDataSourceAppliedChanges *const appliedChanges = [change appliedChanges];
  CKDataSourceState *const previousState = _state;
  CKDataSourceState *const newState = [change state];
  _state = newState;

  // Announce 'didInit'.
  for (CKComponentController *componentController in change.addedComponentControllers) {
    [componentController didInit];
  }
  for (NSIndexPath *insertedIndex in [appliedChanges insertedIndexPaths]) {
    CKDataSourceItem *insertedItem = [newState objectAtIndexPath:insertedIndex];
    CKComponentScopeRootAnnounceControllerInitialization([insertedItem scopeRoot]);
  }

  // Announce 'invalidateController'.
  for (CKComponentController *componentController in change.invalidComponentControllers) {
    [componentController invalidateController];
  }
  for (NSIndexPath *removedIndex in [appliedChanges removedIndexPaths]) {
    CKDataSourceItem *removedItem = [previousState objectAtIndexPath:removedIndex];
    CKComponentScopeRootAnnounceControllerInvalidation([removedItem scopeRoot]);
  }

  CKComponentUpdateComponentForComponentControllerWithIndexPaths(appliedChanges.finalUpdatedIndexPaths.allValues,
                                                                 newState,
                                                                 newState.configuration.options.updateComponentInControllerAfterBuild.valueOr(NO));

  [_announcer dataSource:self didModifyPreviousState:previousState withState:newState byApplyingChanges:appliedChanges];

  // Announce 'didPrepareLayoutForComponent:'.
  CKComponentSendDidPrepareLayoutForComponentsWithIndexPaths([[appliedChanges finalUpdatedIndexPaths] allValues], newState);
  CKComponentSendDidPrepareLayoutForComponentsWithIndexPaths([appliedChanges insertedIndexPaths], newState);

  // Handle deferred changeset (if there is one)
  auto const deferredChangeset = [change deferredChangeset];
  if (deferredChangeset != nil) {
    [_announcer dataSource:self willApplyDeferredChangeset:deferredChangeset];
    id<CKDataSourceStateModifying> const modification =
    [self _changesetGenerationModificationForChangeset:deferredChangeset
                                              userInfo:[appliedChanges userInfo]
                                                   qos:qos
                                   isDeferredChangeset:YES];

    // This needs to be applied asynchronously to avoid having both the first part of the changeset
    // and the deferred changeset be applied in the same runloop tick -- otherwise, the completion
    // of the first update will need to wait until the deferred changeset is applied and regress
    // overall performance.
    //
    // This is manually inserted at the front of the asynchronous modifications queue to avoid having
    // existing enqueued async modifications be applied against a mismatched data source state.
    [_pendingAsynchronousModifications insertObject:modification atIndex:0];
    if (_pendingAsynchronousModifications.count == 1) {
      [self _startAsynchronousModificationIfNeeded];
    }
  }
}

- (void)_processStateUpdates
{
  CKAssertMainThread();
  if (_shouldPauseStateUpdates) {
    return;
  }

  CKDataSourceUpdateStateModification *const asyncStateUpdateModification = [self _consumePendingAsynchronousStateUpdates];
  if (asyncStateUpdateModification != nil) {
    [self _enqueueModification:asyncStateUpdateModification];
  }

  CKDataSourceUpdateStateModification *const syncStateUpdateModification = [self _consumePendingSynchronousStateUpdates];
  if (syncStateUpdateModification != nil) {
    [self _synchronouslyApplyModification:syncStateUpdateModification];
  }
}

- (id<CKDataSourceStateModifying>)_consumePendingSynchronousStateUpdates
{
  CKAssertMainThread();
  if (_pendingSynchronousStateUpdates.empty()) {
    return nil;
  }

  CKDataSourceUpdateStateModification *const modification =
  [[CKDataSourceUpdateStateModification alloc] initWithStateUpdates:_pendingSynchronousStateUpdates];
  _pendingSynchronousStateUpdates.clear();
  return modification;
}

- (id<CKDataSourceStateModifying>)_consumePendingAsynchronousStateUpdates
{
  CKAssertMainThread();
  if (_pendingAsynchronousStateUpdates.empty()) {
    return nil;
  }

  CKDataSourceUpdateStateModification *const modification =
  [[CKDataSourceUpdateStateModification alloc] initWithStateUpdates:_pendingAsynchronousStateUpdates];
  _pendingAsynchronousStateUpdates.clear();
  return modification;
}

- (void)_applyModificationPair:(CKDataSourceModificationPair *)modificationPair
{
  [_announcer dataSource:self willGenerateNewStateWithUserInfo:modificationPair.modification.userInfo];
  CKDataSourceChange *change;
  @autoreleasepool {
    change = [modificationPair.modification changeFromState:modificationPair.state];
  }
  [_announcer dataSource:self didGenerateNewState:[change state] changes:[change appliedChanges]];

  auto const asyncApplyModification = CK::Analytics::willStartAsyncBlock(CK::Analytics::BlockName::DataSourceWillApplyModification);
  dispatch_async(dispatch_get_main_queue(), ^{
    CKSystraceScope applyModificationScope(asyncApplyModification);
    // If the first object in _pendingAsynchronousModifications is not still the modification,
    // it may have been canceled; don't apply it.
    if ([_pendingAsynchronousModifications firstObject] == modificationPair.modification && self->_state == modificationPair.state) {
      [_pendingAsynchronousModifications removeObjectAtIndex:0];
      [self _synchronouslyApplyChange:change qos:modificationPair.modification.qos];
    }

    _processingAsynchronousModification = NO;
    [self _startAsynchronousModificationIfNeeded];
  });
}

- (id<CKDataSourceStateModifying>)_changesetGenerationModificationForChangeset:(CKDataSourceChangeset *)changeset
                                                                    userInfo:(NSDictionary *)userInfo
                                                                         qos:(CKDataSourceQOS)qos
                                                         isDeferredChangeset:(BOOL)isDeferredChangeset
{
  if (!isDeferredChangeset && _changesetSplittingEnabled) {
    return
    [[CKDataSourceSplitChangesetModification alloc] initWithChangeset:changeset
                                                        stateListener:self
                                                             userInfo:userInfo
                                                             viewport:_viewport
                                                                  qos:qos];
  } else {
    return
    [[CKDataSourceChangesetModification alloc] initWithChangeset:changeset
                                                   stateListener:self
                                                        userInfo:userInfo
                                                             qos:qos
                                         shouldValidateChangeset:NO];
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
