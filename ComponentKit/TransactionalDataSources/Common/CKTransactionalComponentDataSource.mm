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
#import "CKComponentDebugController.h"
#import "CKComponentScopeRoot.h"
#import "CKTransactionalComponentDataSourceChange.h"
#import "CKTransactionalComponentDataSourceChangesetModification.h"
#import "CKTransactionalComponentDataSourceChangesetVerification.h"
#import "CKTransactionalComponentDataSourceConfiguration.h"
#import "CKTransactionalComponentDataSourceConfigurationInternal.h"
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
  BOOL _crashOnBadChangesetOperation;
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
    _crashOnBadChangesetOperation = configuration.crashOnBadChangesetOperation;
    [CKComponentDebugController registerReflowListener:self];
  }
  return self;
}

- (CKTransactionalComponentDataSourceState *)state
{
  CKAssertMainThread();
  return _state;
}

- (void)applyChangeset:(CKTransactionalComponentDataSourceChangeset *)changeset
                  mode:(CKUpdateMode)mode
              userInfo:(NSDictionary *)userInfo
{
  CKAssertMainThread();
  verifyChangeset(changeset, _state, _pendingAsynchronousModifications, _crashOnBadChangesetOperation);
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
                                      mode:(CKUpdateMode)mode
{
  CKAssertMainThread();
  if (_pendingAsynchronousStateUpdates.empty() && _pendingSynchronousStateUpdates.empty()) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self _processStateUpdates];
    });
  }

  if (mode == CKUpdateModeAsynchronous) {
    _pendingAsynchronousStateUpdates[rootIdentifier].insert({globalIdentifier, stateUpdate});
  } else {
    _pendingSynchronousStateUpdates[rootIdentifier].insert({globalIdentifier, stateUpdate});
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
  [_announcer transactionalComponentDataSource:self
                        didModifyPreviousState:previousState
                             byApplyingChanges:[change appliedChanges]];
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

static void verifyChangeset(CKTransactionalComponentDataSourceChangeset *changeset,
                            CKTransactionalComponentDataSourceState *state,
                            NSArray<id<CKTransactionalComponentDataSourceStateModifying>> *pendingAsynchronousModifications,
                            const BOOL crashOnBadChangesetOperation)
{
  NSString *(^badOperationDescriptionForType)(CKBadChangesetOperationType badChangesetOperationType) =
  ^NSString *(CKBadChangesetOperationType badChangesetOperationType) {
    NSString *const humanReadableBadChangesetOperationType = CKHumanReadableBadChangesetOperationType(badChangesetOperationType);
    NSString *const humanReadablePendingAsynchronousModifications = readableStringForArray(pendingAsynchronousModifications);
    return [NSString stringWithFormat:@"Bad operation: %@\n*** Changeset:\n%@\n*** Data source state:\n%@\n*** Pending data source modifications:\n%@", humanReadableBadChangesetOperationType, changeset, state, humanReadablePendingAsynchronousModifications];
  };
  if (crashOnBadChangesetOperation) {
    const CKBadChangesetOperationType badChangesetOperationType = CKIsValidChangesetForState(changeset, state, pendingAsynchronousModifications);
    if (badChangesetOperationType != CKBadChangesetOperationTypeNone) {
      [[NSException
        exceptionWithName:NSInternalInconsistencyException
        reason:badOperationDescriptionForType(badChangesetOperationType)
        userInfo:nil]
       raise];

    }
  } else {
#if CK_ASSERTIONS_ENABLED
    const CKBadChangesetOperationType badChangesetOperationType = CKIsValidChangesetForState(changeset, state, pendingAsynchronousModifications);
    CKCAssert(badChangesetOperationType == CKBadChangesetOperationTypeNone, badOperationDescriptionForType(badChangesetOperationType));
#endif
  }
}

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
