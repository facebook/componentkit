  /*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant 
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentScope.h"
#import "CKComponentScopeInternal.h"

#import <unordered_map>
#import <vector>

#import "CKInternalHelpers.h"
#import "CKMutex.h"
#import "CKComponentController.h"
#import "CKComponentInternal.h"
#import "CKComponentScopeFrame.h"
#import "CKComponentSubclass.h"
#import "CKCompositeComponent.h"
#import "CKThreadLocalComponentScope.h"

#pragma mark - State Scope

CKBuildComponentResult CKBuildComponent(id<CKComponentStateListener> listener,
                                        CKComponentScopeFrame *previousRootFrame,
                                        CKComponent *(^function)(void))
{
  CKThreadLocalComponentScope threadScope(listener, previousRootFrame);
  // Order of operations matters, so first store into locals and then return a struct.
  CKComponent *component = function();
  CKComponentScopeFrame *newRootFrame = CKThreadLocalComponentScope::cursor()->currentFrame();
  return {
    .component = component,
    .scopeFrame = newRootFrame,
    .boundsAnimation = [newRootFrame boundsAnimationFromPreviousFrame:previousRootFrame],
  };
}

CKComponentScope::~CKComponentScope()
{
  CKThreadLocalComponentScope::cursor()->popFrame();
}

static Class CKComponentControllerClassForComponentClass(Class componentClass)
{
  static CK::StaticMutex mutex = CK_MUTEX_INITIALIZER; // protects cache
  CK::StaticMutexLocker l(mutex);

  static std::unordered_map<Class, Class> *cache = new std::unordered_map<Class, Class>();
  const auto &it = cache->find(componentClass);
  if (it == cache->end()) {
    Class c = NSClassFromString([NSStringFromClass(componentClass) stringByAppendingString:@"Controller"]);
    cache->insert({componentClass, c});
    return c;
  }
  return it->second;
}

static CKComponentController *_newController(Class componentClass)
{
  if (componentClass == [CKComponent class]) {
    return nil; // Don't create root CKComponentControllers as it does nothing interesting.
  }

  Class controllerClass = CKComponentControllerClassForComponentClass(componentClass);
  if (controllerClass) {
    CKCAssert([controllerClass isSubclassOfClass:[CKComponentController class]],
              @"%@ must inherit from CKComponentController", controllerClass);
    return [[controllerClass alloc] init];
  }

  // This is kinda hacky: if you override animationsFromPreviousComponent: then we need a controller.
  if (CKSubclassOverridesSelector([CKComponent class], componentClass, @selector(animationsFromPreviousComponent:))) {
    return [[CKComponentController alloc] init];
  }

  return nil;
}

CKComponentScope::CKComponentScope(Class __unsafe_unretained componentClass, id identifier, id (^initialStateCreator)(void))
{
  CKCAssert([componentClass isSubclassOfClass:[CKComponent class]],
            @"The componentClass must be a component but it is %@.", NSStringFromClass(componentClass));

  auto cursor = CKThreadLocalComponentScope::cursor();
  CKComponentScopeFrame *currentFrame = cursor->currentFrame();
  CKComponentScopeFrame *equivalentFrame = cursor->equivalentPreviousFrame();

  // Look for an equivalent scope in the previous scope tree matching the input identifiers.
  CKComponentScopeFrame *equivalentPreviousFrame =
  equivalentFrame ? [equivalentFrame existingChildFrameWithClass:componentClass identifier:identifier] : nil;

  id state = equivalentPreviousFrame ? equivalentPreviousFrame.updatedState : (initialStateCreator ? initialStateCreator() : [componentClass initialState]);
  CKComponentController *controller = equivalentPreviousFrame ? equivalentPreviousFrame.controller : _newController(componentClass);

  // Create the new scope.
  CKComponentScopeFrame *scopeFrame = [currentFrame childFrameWithComponentClass:componentClass
                                                                      identifier:identifier
                                                                           state:state
                                                                      controller:controller];

  // Set the new scope to be the "current", top-level scope.
  CKThreadLocalComponentScope::cursor()->pushFrameAndEquivalentPreviousFrame(scopeFrame, equivalentPreviousFrame);

  _scopeFrame = scopeFrame;
}

#pragma mark - State

id CKComponentScope::state() const
{
  return _scopeFrame.state;
}

CKComponentScopeFrame *CKComponentScopeFrameForComponent(CKComponent *component)
{
  CKComponentScopeFrame *currentFrame = CKThreadLocalComponentScope::cursor()->currentFrame();
  if (currentFrame.componentClass == [component class]) {
    if (!currentFrame.acquired) {
      [currentFrame markAcquiredByComponent:component];
      return currentFrame;
    }
  }

  CKCAssert([component class] == [CKComponent class] || CKComponentControllerClassForComponentClass([component class]) == Nil,
            @"%@ has a controller but no scope! Use CKComponentScope(self) before constructing the component or CKComponentTestRootScope at the start of the test.",
            [component class]);
  CKCAssert(!CKSubclassOverridesSelector([CKComponent class], [component class], @selector(animationsFromPreviousComponent:)),
            @"%@ has a controller but no scope! Use CKComponentScope(self) before constructing the component or CKComponentTestRootScope at the start of the test.",
            [component class]);
  return nil;
}
