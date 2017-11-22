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
#import "CKMutex.h"

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

  CK::Mutex _pendingAsynchronousModificationsMutex;
  NSMutableArray<id<CKDataSourceStateModifying>> *_pendingAsynchronousModifications;
  BOOL _forceAutorelease;
  BOOL _pipelinePreparationEnabled;
}
@end

@implementation CKDataSource

- (instancetype)initWithConfiguration:(CKDataSourceConfiguration *)configuration
{
  CKAssertNotNil(configuration, @"Configuration is required");
  if (self = [super init]) {
    _state = [[CKDataSourceState alloc] initWithConfiguration:configuration sections:@[]];
    _announcer = [[CKDataSourceListenerAnnouncer alloc] init];
    _workQueue = dispatch_queue_create("org.componentkit.CKDataSource", DISPATCH_QUEUE_SERIAL);
    _pendingAsynchronousModifications = [NSMutableArray array];
    _forceAutorelease = configuration.forceAutorelease;
    [CKComponentDebugController registerReflowListener:self];
    
    _pipelinePreparationEnabled = configuration.pipelinePreparationEnabled;
  }
  return self;
}

- (void)dealloc
{
  [_state enumerateObjectsUsingBlock:^(CKDataSourceItem *item, NSIndexPath *, BOOL *stop) {
    CKComponentScopeRootAnnounceControllerInvalidation([item scopeRoot]);
  }];
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
  {
    CK::MutexLocker l(_pendingAsynchronousModificationsMutex);
    verifyChangeset(changeset, _state, _pendingAsynchronousModifications);
  }
  id<CKDataSourceStateModifying> modification =
  [[CKDataSourceChangesetModification alloc] initWithChangeset:changeset stateListener:self userInfo:userInfo];
  switch (mode) {
    case CKUpdateModeAsynchronous:
      [self _enqueueModification:modification];
      break;
    case CKUpdateModeSynchronous:
      // We need to keep FIFO ordering of changesets, so cancel & synchronously apply any queued async modifications.
      NSArray *enqueuedChangesets = [self _cancelEnqueuedModificationsOfType:[modification class]];
      for (id<CKDataSourceStateModifying> pendingChangesetModification in enqueuedChangesets) {
        [self _synchronouslyApplyChange:[pendingChangesetModification changeFromState:_state]];
      }
      [self _synchronouslyApplyChange:[modification changeFromState:_state]];
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
      [self _synchronouslyApplyChange:[modification changeFromState:_state]];
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
      [self _synchronouslyApplyChange:[modification changeFromState:_state]];
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
  BOOL shouldStart = NO;
  {
    CK::MutexLocker l(_pendingAsynchronousModificationsMutex);
    [_pendingAsynchronousModifications addObject:modification];
    shouldStart = _pendingAsynchronousModifications.count == 1;
  }
  if (shouldStart) {
    [self _startAsynchronousModificationIfNeeded];
  }
}

- (void)_startAsynchronousModificationIfNeeded
{
  CKAssertMainThread();

  CKDataSourceModificationPair *modificationPair = nil;
  {
    CK::MutexLocker l(_pendingAsynchronousModificationsMutex);
    if (_pendingAsynchronousModifications.count > 0) {
      modificationPair = [[CKDataSourceModificationPair alloc]
                          initWithModification:_pendingAsynchronousModifications.firstObject
                          state:_state];
    }
  }
  
  if (modificationPair) {
    dispatch_async(_workQueue, ^{
      [self _applyModificationPair:modificationPair];
    });
  }
}

/** Returns the canceled matching modifications, in the order they would have been applied. */
- (NSArray *)_cancelEnqueuedModificationsOfType:(Class)modificationType
{
  CKAssertMainThread();
  
  CK::MutexLocker l(_pendingAsynchronousModificationsMutex);
  
  NSIndexSet *indexes = [_pendingAsynchronousModifications indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
    return [obj isKindOfClass:modificationType];
  }];
  NSArray *modifications = [_pendingAsynchronousModifications objectsAtIndexes:indexes];
  [_pendingAsynchronousModifications removeObjectsAtIndexes:indexes];

  return modifications;
}

- (void)_synchronouslyApplyChange:(CKDataSourceChange *)appliedChange
{
  CKAssertMainThread();
  void (^ applyChangeBlock)(CKDataSourceChange *) = ^(CKDataSourceChange *change) {
    CKDataSourceState *previousState = _state;
    _state = [change state];

    for (NSIndexPath *removedIndex in [[change appliedChanges] removedIndexPaths]) {
      CKDataSourceItem *removedItem = [previousState objectAtIndexPath:removedIndex];
      CKComponentScopeRootAnnounceControllerInvalidation([removedItem scopeRoot]);
    }

    std::vector<CKComponent *> updatedComponents;
    if ([_state.configuration alwaysSendComponentUpdate]) {
      NSDictionary *finalIndexPathsForUpdatedItems = [[change appliedChanges] finalUpdatedIndexPaths];
      for (NSIndexPath *updatedIndex in finalIndexPathsForUpdatedItems) {
        CKDataSourceItem *item = [_state objectAtIndexPath:updatedIndex];
        getComponentsFromLayout(item.layout, updatedComponents);
      }

      for (auto updatedComponent: updatedComponents) {
        [updatedComponent.controller willStartUpdateToComponent:updatedComponent];
      }
    }

    [_announcer transactionalComponentDataSource:self
                          didModifyPreviousState:previousState
                               byApplyingChanges:[change appliedChanges]];

    if ([_state.configuration alwaysSendComponentUpdate]) {
      for (auto updatedComponent: updatedComponents) {
        [updatedComponent.controller didFinishComponentUpdate];
      }
    }
  };

  if (_forceAutorelease) {
    @autoreleasepool {
      applyChangeBlock(appliedChange);
    }
  } else {
    applyChangeBlock(appliedChange);
  }
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
    [self _synchronouslyApplyChange:[sm changeFromState:_state]];
  }
}

- (void)_applyModificationPair:(CKDataSourceModificationPair *)modificationPair
{
  CKDataSourceChange *change;
  @autoreleasepool {
    change = [modificationPair.modification changeFromState:modificationPair.state];
  }
  
  dispatch_async(dispatch_get_main_queue(), ^{
    // If the first object in _pendingAsynchronousModifications is not still the modification,
    // it may have been canceled; don't apply it.
    BOOL shouldApplyChange = NO;
    {
      CK::MutexLocker l(_pendingAsynchronousModificationsMutex);
      if ([_pendingAsynchronousModifications firstObject] == modificationPair.modification && self->_state == modificationPair.state) {
        shouldApplyChange = YES;
        [_pendingAsynchronousModifications removeObjectAtIndex:0];
      }
    }
    
    if (shouldApplyChange) {
      [self _synchronouslyApplyChange:change];
    }
    
    if (!_pipelinePreparationEnabled) {
      [self _startAsynchronousModificationIfNeeded];
    } else {
      // In pipeline world, as soon as encounter an invalid modification,
      // we optimistically cancel following modification and restart it from main thread
      if (!shouldApplyChange) {
        [self _startAsynchronousModificationIfNeeded];
      }
    }
  });
  
  if (_pipelinePreparationEnabled) {
    // After processing the Nth modification, we speculatively find the (N+1)th modification in queue to process
    // without hopping back to main queue to reduce latency
    const auto nextModificationState = [self _nextModificationStateFor:modificationPair.modification];
    switch (nextModificationState.first) {
      case NextPipelineStateEmpty:
        // No more items to process, done.
        // Mutation of modification queue is always done on main thread,
        // and when a modification is enqueued to an empty queue, async operation always kicks off.
        break;
      case NextPipelineStateCancelled: {
        // We need to restart from main thread
        dispatch_async(dispatch_get_main_queue(), ^{
          [self _startAsynchronousModificationIfNeeded];
        });
        break;
      }
      case NextPipelineStateContinue: {
        // Speculatively proceed to prepare the next one.
        // Note that we are not 100% sure here that the next one has not been cancelled due to
        // its predecessors being cancelled, but the sanity check on main thread before application
        // guarantees that we don't apply a cancelled modification
        [self
         _applyModificationPair:
         [[CKDataSourceModificationPair alloc]
          initWithModification:nextModificationState.second
          state:change.state]];
        break;
      }
    }
  }
}

- (std::pair<NextPipelineState, id<CKDataSourceStateModifying>>)_nextModificationStateFor:(id<CKDataSourceStateModifying>)modification
{
  CK::MutexLocker l(_pendingAsynchronousModificationsMutex);
  
  NSUInteger index = [_pendingAsynchronousModifications indexOfObject:modification];
  if (index == NSNotFound) {
    // The modification has been cancelled
    return {NextPipelineStateCancelled, nil};
  } else if (index < _pendingAsynchronousModifications.count - 1) {
    // Found the (N+1)th modification to process
    return {NextPipelineStateContinue, _pendingAsynchronousModifications[index + 1]};
  } else {
    // No more modifications to process
    return {NextPipelineStateEmpty, nil};
  }
}

static void getComponentsFromLayout(CKComponentLayout layout, std::vector<CKComponent *> &updatedComponents)
{
  updatedComponents.push_back(layout.component);
  if (layout.children) {
    for (const auto child : *layout.children) {
      getComponentsFromLayout(child.layout, updatedComponents);
    }
  }
}

static void verifyChangeset(CKDataSourceChangeset *changeset,
                            CKDataSourceState *state,
                            NSArray<id<CKDataSourceStateModifying>> *pendingAsynchronousModifications)
{
#if CK_ASSERTIONS_ENABLED
  const CKInvalidChangesetOperationType invalidChangesetOperationType = CKIsValidChangesetForState(changeset,
                                                                                                   state,
                                                                                                   pendingAsynchronousModifications);
  if (invalidChangesetOperationType != CKInvalidChangesetOperationTypeNone) {
    NSString *const humanReadableInvalidChangesetOperationType = CKHumanReadableInvalidChangesetOperationType(invalidChangesetOperationType);
    NSString *const humanReadablePendingAsynchronousModifications = readableStringForArray(pendingAsynchronousModifications);
    CKCFatal(@"Invalid changeset: %@\n*** Changeset:\n%@\n*** Data source state:\n%@\n*** Pending data source modifications:\n%@", humanReadableInvalidChangesetOperationType, changeset, state, humanReadablePendingAsynchronousModifications);
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
