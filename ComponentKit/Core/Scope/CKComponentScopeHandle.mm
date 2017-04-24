/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentScopeHandle.h"

#import "CKComponentScopeRoot.h"
#import "CKComponentSubclass.h"
#import "CKComponentInternal.h"
#import "CKInternalHelpers.h"
#import "CKMutex.h"
#import "CKScopedComponent.h"
#import "CKScopedComponentController.h"
#import "CKThreadLocalComponentScope.h"

@implementation CKComponentScopeHandle
{
  id<CKComponentStateListener> __weak _listener;
  id<CKScopedComponentController> _controller;
  CKComponentScopeRootIdentifier _rootIdentifier;
  BOOL _acquired;
  BOOL _resolved;
  CKComponent *__weak _acquiredComponent;
}

+ (CKComponentScopeHandle *)handleForComponent:(id<CKScopedComponent>)component
{
  CKThreadLocalComponentScope *currentScope = CKThreadLocalComponentScope::currentScope();
  if (currentScope == nullptr) {
    return nil;
  }

  CKComponentScopeHandle *handle = currentScope->stack.top().frame.handle;
  if ([handle acquireFromComponent:component]) {
    [currentScope->newScopeRoot registerComponent:component];
    return handle;
  }

  if (handle) {
    CKAssertNil([component.class controllerClass], @"%@ has a controller but no scope! "
                 "Make sure you construct your scope(self) before constructing the component or CKComponentTestRootScope "
                 "at the start of the test.", [component class]);
  }

  return nil;
}

- (instancetype)initWithListener:(id<CKComponentStateListener>)listener
                  rootIdentifier:(CKComponentScopeRootIdentifier)rootIdentifier
                  componentClass:(Class)componentClass
             initialStateCreator:(id (^)(void))initialStateCreator
{
  static int32_t nextGlobalIdentifier = 0;
  return [self initWithListener:listener
               globalIdentifier:OSAtomicIncrement32(&nextGlobalIdentifier)
                 rootIdentifier:rootIdentifier
                 componentClass:componentClass
                          state:initialStateCreator ? initialStateCreator() : [componentClass initialState]
                     controller:nil]; // controllers are built on resolution of the handle
}

- (instancetype)initWithListener:(id<CKComponentStateListener>)listener
                globalIdentifier:(CKComponentScopeHandleIdentifier)globalIdentifier
                  rootIdentifier:(CKComponentScopeRootIdentifier)rootIdentifier
                  componentClass:(Class)componentClass
                           state:(id)state
                      controller:(id<CKScopedComponentController>)controller
{
  if (self = [super init]) {
    _listener = listener;
    _globalIdentifier = globalIdentifier;
    _rootIdentifier = rootIdentifier;
    _componentClass = componentClass;
    _state = state;
    _controller = controller;
  }
  return self;
}

- (instancetype)newHandleWithStateUpdates:(const CKComponentStateUpdateMap &)stateUpdates
                       componentScopeRoot:(CKComponentScopeRoot *)componentScopeRoot
{
  id updatedState = _state;
  const auto range = stateUpdates.equal_range(_globalIdentifier);
  for (auto it = range.first; it != range.second; ++it) {
    updatedState = it->second(updatedState);
  }
  [componentScopeRoot registerComponentController:_controller];
  return [[CKComponentScopeHandle alloc] initWithListener:_listener
                                         globalIdentifier:_globalIdentifier
                                           rootIdentifier:_rootIdentifier
                                           componentClass:_componentClass
                                                    state:updatedState
                                               controller:_controller];
}

- (instancetype)newHandleToBeReacquiredDueToScopeCollision
{
  return [[CKComponentScopeHandle alloc] initWithListener:_listener
                                         globalIdentifier:_globalIdentifier
                                           rootIdentifier:_rootIdentifier
                                           componentClass:_componentClass
                                                    state:_state
                                               controller:_controller];
}

- (id<CKScopedComponentController>)controller
{
  CKAssert(_resolved, @"Requesting controller from scope handle before resolution. The controller will be nil.");
  return _controller;
}

- (void)dealloc
{
  CKAssert(_resolved, @"Must be resolved before deallocation.");
}

#pragma mark - State

- (void)updateState:(id (^)(id))updateBlock mode:(CKUpdateMode)mode
{
  CKAssertNotNil(updateBlock, @"The update block cannot be nil");
  if (![NSThread isMainThread]) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self updateState:updateBlock mode:mode];
    });
    return;
  }
  [_listener componentScopeHandleWithIdentifier:_globalIdentifier
                                 rootIdentifier:_rootIdentifier
                          didReceiveStateUpdate:updateBlock
                                           mode:mode];
}

#pragma mark - Component Scope Handle Acquisition

- (BOOL)acquireFromComponent:(id<CKScopedComponent>)component
{
  if (!_acquired && [component isMemberOfClass:_componentClass]) {
    _acquired = YES;
    _acquiredComponent = component;
    return YES;
  } else {
    return NO;
  }
}

- (void)resolve
{
  CKAssertFalse(_resolved);
  // _acquiredComponent may be nil if a component scope was declared before an early return. In that case, the scope
  // handle will not be acquired, and we should avoid creating a component controller for the nil component.
  if (!_controller && _acquiredComponent) {
    CKThreadLocalComponentScope *currentScope = CKThreadLocalComponentScope::currentScope();
    CKAssert(currentScope != nullptr, @"Current scope should never be null here. Thread-local stack is corrupted.");

    const Class<CKScopedComponentController> controllerClass = [_acquiredComponent.class controllerClass];
    if (controllerClass) {
      // The compiler is not happy when I don't explicitly cast as (Class)
      // See: http://stackoverflow.com/questions/21699755/create-an-instance-from-a-class-that-conforms-to-a-protocol
      _controller = [[(Class)controllerClass alloc] initWithComponent:_acquiredComponent];
      [currentScope->newScopeRoot registerComponentController:_controller];
    }
  }
  _resolved = YES;
}

- (id)responder
{
  CKAssert(_resolved, @"Asking for responder from scope handle before resolution:%@", NSStringFromClass(_componentClass));
  return _acquiredComponent;
}

@end
