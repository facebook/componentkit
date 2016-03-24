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
#import "CKComponentScopeRoot.h"
#import "CKTransactionalComponentDataSourceChange.h"
#import "CKTransactionalComponentDataSourceChangesetModification.h"
#import "CKTransactionalComponentDataSourceConfiguration.h"
#import "CKTransactionalComponentDataSourceListenerAnnouncer.h"
#import "CKTransactionalComponentDataSourceReloadModification.h"
#import "CKTransactionalComponentDataSourceStateInternal.h"
#import "CKTransactionalComponentDataSourceStateModifying.h"
#import "CKTransactionalComponentDataSourceUpdateConfigurationModification.h"
#import "CKTransactionalComponentDataSourceUpdateStateModification.h"

@interface CKTransactionalComponentDataSource () <CKComponentStateListener>
{
  CKTransactionalComponentDataSourceState *_state;
  CKTransactionalComponentDataSourceListenerAnnouncer *_announcer;

  CKComponentStateUpdatesMap _pendingAsynchronousStateUpdates;
  CKComponentStateUpdatesMap _pendingSynchronousStateUpdates;

  NSMutableArray *_pendingAsynchronousModifications;
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
  id<CKTransactionalComponentDataSourceStateModifying> modification = _pendingAsynchronousModifications[0];
  CKTransactionalComponentDataSourceState *baseState = _state;
  dispatch_async(_workQueue, ^{
    CKTransactionalComponentDataSourceChange *change = [modification changeFromState:baseState];
    dispatch_async(dispatch_get_main_queue(), ^{
      // If the first object in _pendingAsynchronousModifications is not still the modification,
      // it may have been canceled; don't apply it.
      if ([_pendingAsynchronousModifications firstObject] == modification && _state == baseState) {
        [self _synchronouslyApplyChange:change];
        [_pendingAsynchronousModifications removeObjectAtIndex:0];
      }
      if ([_pendingAsynchronousModifications count] != 0) {
        [self _startFirstAsynchronousModification];
      }
    });
  });
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

@end
