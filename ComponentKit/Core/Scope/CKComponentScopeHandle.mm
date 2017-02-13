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

#import "CKComponentController.h"
#import "CKComponentControllerInternal.h"
#import "CKComponentScopeRootInternal.h"
#import "CKComponentSubclass.h"
#import "CKComponentInternal.h"
#import "CKInternalHelpers.h"
#import "CKMutex.h"
#import "CKThreadLocalComponentScope.h"

@implementation CKComponentScopeHandle
{
  id<CKComponentStateListener> __weak _listener;
  CKComponentController *_controller;
  CKComponentScopeRootIdentifier _rootIdentifier;
  BOOL _acquired;
  BOOL _resolved;
  CKComponent *__weak _acquiredComponent;
}

+ (CKComponentScopeHandle *)handleForComponent:(CKComponent *)component
{
  CKThreadLocalComponentScope *currentScope = CKThreadLocalComponentScope::currentScope();
  if (currentScope == nullptr) {
    return nil;
  }

  CKComponentScopeHandle *handle = currentScope->stack.top().frame.handle;
  if ([handle acquireFromComponent:component]) {
    if (CKSubclassOverridesSelector([CKComponent class], [component class], @selector(boundsAnimationFromPreviousComponent:))) {
      [currentScope->newScopeRoot registerBoundsAnimationComponent:component];
    }
    return handle;
  }
  CKCAssertNil(CKComponentControllerClassFromComponentClass([component class]), @"%@ has a controller but no scope! "
               "Use CKComponentScope scope(self) before constructing the component or CKComponentTestRootScope "
               "at the start of the test.", [component class]);
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
                      controller:(CKComponentController *)controller
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
  [componentScopeRoot registerAnnounceableEventsForController:_controller];
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

- (CKComponentController *)controller
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
             didReceiveStateUpdateToBeScheduled:updateBlock
                                           mode:mode];
}

- (void)enqueueState:(id (^)(id))updateBlock mode:(CKUpdateMode)mode
{
  CKAssertNotNil(updateBlock, @"The update block cannot be nil");
  if (![NSThread isMainThread]) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self enqueueState:updateBlock mode:mode];
    });
    return;
  }
  [_listener componentScopeHandleWithIdentifier:_globalIdentifier
                                 rootIdentifier:_rootIdentifier
              didReceiveStateUpdateToBeEnqueued:updateBlock
                                           mode:mode];
}

#pragma mark - Component Scope Handle Acquisition

- (BOOL)acquireFromComponent:(CKComponent *)component
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

    // A controller can be non-nil at this callsite during component re-generation because a new scope handle is
    // generated in a new tree, that is acquired by a new component. We pass in the original component controller
    // in that case, and we should avoid re-generating a new controller in that case.
    _controller = newController(_acquiredComponent, currentScope->newScopeRoot);
  }
  _resolved = YES;
}

- (id)responder
{
  CKAssert(_resolved, @"Asking for responder from scope handle before resolution:%@", NSStringFromClass(_componentClass));
  return _acquiredComponent;
}

#pragma mark Controllers

static CKComponentController *newController(CKComponent *component, CKComponentScopeRoot *root)
{
  Class controllerClass = CKComponentControllerClassFromComponentClass([component class]);
  if (controllerClass) {
    CKCAssert([controllerClass isSubclassOfClass:[CKComponentController class]],
              @"%@ must inherit from CKComponentController", controllerClass);
    CKComponentController *controller = [[controllerClass alloc] initWithComponent:component];
    [root registerAnnounceableEventsForController:controller];
    return controller;
  }
  return nil;
}

@end
