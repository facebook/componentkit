/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant 
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKTransactionalComponentDataSource.h"
#import "CKTransactionalComponentDataSourceInternal.h"

#import "CKAssert.h"
#import "CKComponentControllerEvents.h"
#import "CKComponentControllerInternal.h"
#import "CKComponentDebugController.h"
#import "CKComponentScopeRoot.h"
#import "CKComponentSubclass.h"
#import "CKTransactionalComponentDataSourceAppliedChanges.h"
#import "CKTransactionalComponentDataSourceChange.h"
#import "CKTransactionalComponentDataSourceChangesetModification.h"
#import "CKTransactionalComponentDataSourceChangesetVerification.h"
#import "CKTransactionalComponentDataSourceConfiguration.h"
#import "CKTransactionalComponentDataSourceConfigurationInternal.h"
#import "CKTransactionalComponentDataSourceItem.h"
#import "CKTransactionalComponentDataSourceListenerAnnouncer.h"
#import "CKTransactionalComponentDataSourceReloadModification.h"
#import "CKTransactionalComponentDataSourceStateInternal.h"
#import "CKTransactionalComponentDataSourceStateModifying.h"
#import "CKTransactionalComponentDataSourceUpdateConfigurationModification.h"
#import "CKTransactionalComponentDataSourceUpdateStateModification.h"

@interface CKTransactionalComponentDataSourceModificationPair : NSObject

@property (nonatomic, strong, readonly) id<CKTransactionalComponentDataSourceStateModifying> modification;
@property (nonatomic, strong, readonly) CKTransactionalComponentDataSourceState *state;

- (instancetype)initWithModification:(id<CKTransactionalComponentDataSourceStateModifying>)modification
                               state:(CKTransactionalComponentDataSourceState *)state;

@end

@interface CKTransactionalComponentDataSource () <CKComponentStateListener, CKComponentDebugReflowListener>
{
  CKTransactionalComponentDataSourceState *_state;
  CKTransactionalComponentDataSourceListenerAnnouncer *_announcer;

  CKComponentStateUpdatesMap _pendingAsynchronousStateUpdates;
  CKComponentStateUpdatesMap _pendingSynchronousStateUpdates;

  NSMutableArray<id<CKTransactionalComponentDataSourceStateModifying>> *_pendingAsynchronousModifications;

  NSThread *_workThreadOverride;
}
@end

@implementation CKTransactionalComponentDataSource

- (instancetype)initWithConfiguration:(CKTransactionalComponentDataSourceConfiguration *)configuration
{
  CKAssertNotNil(configuration, @"Configuration is required");
  if (self = [super init]) {
    _state = [[CKTransactionalComponentDataSourceState alloc] initWithConfiguration:configuration sections:@[]];
    _announcer = [[CKTransactionalComponentDataSourceListenerAnnouncer alloc] init];
    _workQueue = dispatch_queue_create("org.componentkit.CKTransactionalComponentDataSource", DISPATCH_QUEUE_SERIAL);
    _pendingAsynchronousModifications = [NSMutableArray array];
    _workThreadOverride = configuration.workThreadOverride;
    [CKComponentDebugController registerReflowListener:self];
  }
  return self;
}

- (void)dealloc
{
  [_state enumerateObjectsUsingBlock:^(CKTransactionalComponentDataSourceItem *item, NSIndexPath *, BOOL *stop) {
    CKComponentScopeRootAnnounceControllerInvalidation([item scopeRoot]);
  }];
}

- (CKTransactionalComponentDataSourceState *)state
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
  id<CKTransactionalComponentDataSourceStateModifying> modification =
  [[CKTransactionalComponentDataSourceChangesetModification alloc] initWithChangeset:changeset stateListener:self userInfo:userInfo];
  switch (mode) {
    case CKUpdateModeAsynchronous:
      [self _enqueueModification:modification];
      break;
    case CKUpdateModeSynchronous:
      // We need to keep FIFO ordering of changesets, so cancel & synchronously apply any queued async modifications.
      NSArray *enqueuedChangesets = [self _cancelEnqueuedModificationsOfType:[modification class]];
      for (id<CKTransactionalComponentDataSourceStateModifying> pendingChangesetModification in enqueuedChangesets) {
        [self _synchronouslyApplyChange:[pendingChangesetModification changeFromState:_state]];
      }
      [self _synchronouslyApplyChange:[modification changeFromState:_state]];
      break;
  }
}

- (void)updateConfiguration:(CKTransactionalComponentDataSourceConfiguration *)configuration
                       mode:(CKUpdateMode)mode
                   userInfo:(NSDictionary *)userInfo
{
  CKAssertMainThread();
  id<CKTransactionalComponentDataSourceStateModifying> modification =
  [[CKTransactionalComponentDataSourceUpdateConfigurationModification alloc] initWithConfiguration:configuration userInfo:userInfo];
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
  id<CKTransactionalComponentDataSourceStateModifying> modification =
  [[CKTransactionalComponentDataSourceReloadModification alloc] initWithUserInfo:userInfo];
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

- (void)addListener:(id<CKTransactionalComponentDataSourceListener>)listener
{
  CKAssertMainThread();
  [_announcer addListener:listener];
}

- (void)removeListener:(id<CKTransactionalComponentDataSourceListener>)listener
{
  CKAssertMainThread();
  [_announcer removeListener:listener];
}

#pragma mark - State Listener

- (void)componentScopeHandleWithIdentifier:(CKComponentScopeHandleIdentifier)globalIdentifier
                            rootIdentifier:(CKComponentScopeRootIdentifier)rootIdentifier
                     didReceiveStateUpdate:(id (^)(id))stateUpdate
                                  userInfo:(NSDictionary<NSString *,NSString *> *)userInfo
                                      mode:(CKUpdateMode)mode
{
  CKAssertMainThread();
  if (_pendingAsynchronousStateUpdates.empty() && _pendingSynchronousStateUpdates.empty()) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self _processStateUpdates];
    });
  }

  if (mode == CKUpdateModeAsynchronous) {
    _pendingAsynchronousStateUpdates[rootIdentifier][globalIdentifier].push_back(stateUpdate);
  } else {
    _pendingSynchronousStateUpdates[rootIdentifier][globalIdentifier].push_back(stateUpdate);
  }
}

#pragma mark - CKComponentDebugReflowListener

- (void)didReceiveReflowComponentsRequest
{
  [self reloadWithMode:CKUpdateModeAsynchronous userInfo:nil];
}

#pragma mark - Internal

- (void)_enqueueModification:(id<CKTransactionalComponentDataSourceStateModifying>)modification
{
  CKAssertMainThread();
  [_pendingAsynchronousModifications addObject:modification];
  if ([_pendingAsynchronousModifications count] == 1) {
    [self _startFirstAsynchronousModification];
  }
}

- (void)_startFirstAsynchronousModification
{
  CKAssertMainThread();
  CKTransactionalComponentDataSourceModificationPair *modificationPair =
  [[CKTransactionalComponentDataSourceModificationPair alloc] initWithModification:_pendingAsynchronousModifications[0]
                                                                             state:_state];
  if (_workThreadOverride) {
    [self performSelector:@selector(_applyModificationPair:)
                 onThread:_workThreadOverride
               withObject:modificationPair
            waitUntilDone:NO];
  } else {
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

- (void)_synchronouslyApplyChange:(CKTransactionalComponentDataSourceChange *)change
{
  CKAssertMainThread();
  CKTransactionalComponentDataSourceState *previousState = _state;
  _state = [change state];
  
  for (NSIndexPath *removedIndex in [[change appliedChanges] removedIndexPaths]) {
    CKTransactionalComponentDataSourceItem *removedItem = [previousState objectAtIndexPath:removedIndex];
    CKComponentScopeRootAnnounceControllerInvalidation([removedItem scopeRoot]);
  }
  
  std::vector<CKComponent *> updatedComponents;
  if ([_state.configuration alwaysSendComponentUpdate]) {
    NSDictionary *finalIndexPathsForUpdatedItems = [[change appliedChanges] finalUpdatedIndexPaths];
    for (NSIndexPath *updatedIndex in finalIndexPathsForUpdatedItems) {
      CKTransactionalComponentDataSourceItem *item = [_state objectAtIndexPath:updatedIndex];
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
}

- (void)_processStateUpdates
{
  CKAssertMainThread();
  if (!_pendingAsynchronousStateUpdates.empty()) {
    CKTransactionalComponentDataSourceUpdateStateModification *sm =
    [[CKTransactionalComponentDataSourceUpdateStateModification alloc] initWithStateUpdates:_pendingAsynchronousStateUpdates];
    _pendingAsynchronousStateUpdates.clear();
    [self _enqueueModification:sm];
  }
  if (!_pendingSynchronousStateUpdates.empty()) {
    CKTransactionalComponentDataSourceUpdateStateModification *sm =
    [[CKTransactionalComponentDataSourceUpdateStateModification alloc] initWithStateUpdates:_pendingSynchronousStateUpdates];
    _pendingSynchronousStateUpdates.clear();
    [self _synchronouslyApplyChange:[sm changeFromState:_state]];
  }
}

- (void)_applyModificationPair:(CKTransactionalComponentDataSourceModificationPair *)modificationPair
{
  CKTransactionalComponentDataSourceChange *change = [modificationPair.modification changeFromState:modificationPair.state];
  dispatch_async(dispatch_get_main_queue(), ^{
    // If the first object in _pendingAsynchronousModifications is not still the modification,
    // it may have been canceled; don't apply it.
    if ([_pendingAsynchronousModifications firstObject] == modificationPair.modification && self->_state == modificationPair.state) {
      [self _synchronouslyApplyChange:change];
      [_pendingAsynchronousModifications removeObjectAtIndex:0];
    }
    if ([_pendingAsynchronousModifications count] != 0) {
      [self _startFirstAsynchronousModification];
    }
  });
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
                            CKTransactionalComponentDataSourceState *state,
                            NSArray<id<CKTransactionalComponentDataSourceStateModifying>> *pendingAsynchronousModifications)
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

@implementation CKTransactionalComponentDataSourceModificationPair

- (instancetype)initWithModification:(id<CKTransactionalComponentDataSourceStateModifying>)modification
                               state:(CKTransactionalComponentDataSourceState *)state
{
  if (self = [super init]) {
    _modification = modification;
    _state = state;
  }
  return self;
}

@end
