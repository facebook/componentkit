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
#import "CKInternalHelpers.h"
#import "CKMutex.h"
#import "CKThreadLocalComponentScope.h"

@implementation CKComponentScopeHandle
{
  id<CKComponentStateListener> __weak _listener;
  Class _componentClass;
  CKComponentController *_controller;
  CKComponentScopeRootIdentifier _rootIdentifier;
  BOOL _acquired;
  // Temporarily stored reference to the specific component that acquired this handle. This forms a reference cycle
  // that is broken in `resolve`. This reference will always be partially initialized, and should not be used outside
  // the `resolve` call.
  CKComponent *_acquiredComponent;
  BOOL _resolved;
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
  CKCAssertNil(controllerClassForComponentClass([component class]), @"%@ has a controller but no scope! "
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
{
  id updatedState = _state;
  const auto range = stateUpdates.equal_range(_globalIdentifier);
  for (auto it = range.first; it != range.second; ++it) {
    updatedState = it->second(updatedState);
  }
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

- (void)updateState:(id (^)(id))updateFunction mode:(CKUpdateMode)mode
{
  CKAssertNotNil(updateFunction, @"The block for updating state cannot be nil");
  if (![NSThread isMainThread]) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self updateState:updateFunction mode:mode];
    });
    return;
  }
  [_listener componentScopeHandleWithIdentifier:_globalIdentifier
                                 rootIdentifier:_rootIdentifier
                          didReceiveStateUpdate:updateFunction
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
  if (!_controller) {
    CKThreadLocalComponentScope *currentScope = CKThreadLocalComponentScope::currentScope();
    CKAssert(currentScope != nullptr, @"Current scope should never be null here. Thread-local stack is corrupted.");

    // A controller can be non-nil at this callsite during component re-generation because a new scope handle is
    // generated in a new tree, that is acquired by a new component. We pass in the original component controller
    // in that case, and we should avoid re-generating a new controller in that case.
    _controller = newController(_acquiredComponent, currentScope->newScopeRoot);
  }
  // We break the retain cycle with the acquired component here.
  _acquiredComponent = nil;
  _resolved = YES;
}

#pragma mark Controllers

static Class controllerClassForComponentClass(Class componentClass)
{
  if (componentClass == [CKComponent class]) {
    return Nil; // Don't create root CKComponentControllers as it does nothing interesting.
  }

  static CK::StaticMutex mutex = CK_MUTEX_INITIALIZER; // protects cache
  CK::StaticMutexLocker l(mutex);

  static std::unordered_map<Class, Class> *cache = new std::unordered_map<Class, Class>();
  const auto &it = cache->find(componentClass);
  if (it == cache->end()) {
    Class c = NSClassFromString([NSStringFromClass(componentClass) stringByAppendingString:@"Controller"]);

    // If you override animationsFromPreviousComponent: or animationsOnInitialMount then we need a controller.
    if (c == nil &&
        (CKSubclassOverridesSelector([CKComponent class], componentClass, @selector(animationsFromPreviousComponent:)) ||
         CKSubclassOverridesSelector([CKComponent class], componentClass, @selector(animationsOnInitialMount)))) {
      c = [CKComponentController class];
    }

    cache->insert({componentClass, c});
    return c;
  }
  return it->second;
}

static CKComponentController *newController(CKComponent *component, CKComponentScopeRoot *root)
{
  Class controllerClass = controllerClassForComponentClass([component class]);
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
