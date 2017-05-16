/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentScopeRoot.h"

#import <libkern/OSAtomic.h>
#import <mutex>

#import "CKScopedComponent.h"
#import "CKScopedComponentController.h"
#import "CKScopedResponderManager.h"
#import "CKInternalHelpers.h"
#import "CKThreadLocalComponentScope.h"

typedef std::unordered_multimap<CKComponentScopePredicate, __weak id<CKScopedComponent>> _CKRegisteredComponentsMap;
typedef std::unordered_multimap<CKComponentControllerScopePredicate, __weak id<CKScopedComponentController>> _CKRegisteredComponentControllerMap;

@implementation CKComponentScopeRoot
{
  std::unordered_set<CKComponentScopePredicate> _componentPredicates;
  std::unordered_set<CKComponentControllerScopePredicate> _componentControllerPredicates;
  
  _CKRegisteredComponentsMap _registeredComponents;
  _CKRegisteredComponentControllerMap _registeredComponentControllers;
  
  std::mutex _pendingMapAccess;
  CKHandleToResponderMap _pendingHandleToResponderMap;
  CKScopedResponderManager *_responderManager;
}

+ (instancetype)rootWithListener:(id<CKComponentStateListener>)listener
             componentPredicates:(const std::unordered_set<CKComponentScopePredicate> &)componentPredicates
   componentControllerPredicates:(const std::unordered_set<CKComponentControllerScopePredicate> &)componentControllerPredicates
{
  static int32_t nextGlobalIdentifier = 0;
  CKScopedResponderManager *const responderManager = [CKScopedResponderManager new];
  return [[CKComponentScopeRoot alloc] initWithListener:listener
                                       globalIdentifier:OSAtomicIncrement32(&nextGlobalIdentifier)
                                    componentPredicates:componentPredicates
                          componentControllerPredicates:componentControllerPredicates
                                       responderManager:responderManager];
}

- (instancetype)newRoot
{
  return [[CKComponentScopeRoot alloc] initWithListener:_listener
                                       globalIdentifier:_globalIdentifier
                                    componentPredicates:_componentPredicates
                          componentControllerPredicates:_componentControllerPredicates
                                       responderManager:_responderManager];
}

- (instancetype)initWithListener:(id<CKComponentStateListener>)listener
                globalIdentifier:(CKComponentScopeRootIdentifier)globalIdentifier
             componentPredicates:(const std::unordered_set<CKComponentScopePredicate> &)componentPredicates
   componentControllerPredicates:(const std::unordered_set<CKComponentControllerScopePredicate> &)componentControllerPredicates
                responderManager:(CKScopedResponderManager *)responderManager
{
  if (self = [super init]) {
    _listener = listener;
    _globalIdentifier = globalIdentifier;
    _rootFrame = [[CKComponentScopeFrame alloc] initWithHandle:nil];
    _componentPredicates = componentPredicates;
    _componentControllerPredicates = componentControllerPredicates;
    _responderManager = responderManager;
  }
  return self;
}

- (void)registerComponent:(id<CKScopedComponent>)component withHandleIdentifier:(CKComponentScopeHandleIdentifier)identifier
{
  if (!component) {
    // Handle this gracefully so we don't have a bunch of nils being passed to predicates.
    return;
  }
  
  {
    std::lock_guard<std::mutex> l(_pendingMapAccess);
    _pendingHandleToResponderMap.insert({identifier, component});
  }
  
  for (const auto &predicate : _componentPredicates) {
    if (predicate(component)) {
      _registeredComponents.insert({predicate, component});
    }
  }
}

- (void)registerComponentController:(id<CKScopedComponentController>)componentController
{
  if (!componentController) {
    // As above, handle a nil component controller gracefully instead of passing through to predicate.
    return;
  }
  for (const auto &predicate : _componentControllerPredicates) {
    if (predicate(componentController)) {
      _registeredComponentControllers.insert({predicate, componentController});
    }
  }
}

- (void)enumerateComponentsMatchingPredicate:(CKComponentScopePredicate)predicate
                                       block:(CKComponentScopeEnumerator)block
{
  if (!block) {
    CKFailAssert(@"Must be given a block to enumerate.");
    return;
  }
  CKAssert(_componentPredicates.find(predicate) != _componentPredicates.end(), @"Scope root must be initialized with predicate to enumerate.");
  for (auto it = _registeredComponents.find(predicate); it != _registeredComponents.end(); ++it) {
    block(it->second);
  }
}

- (void)enumerateComponentControllersMatchingPredicate:(CKComponentControllerScopePredicate)predicate
                                                 block:(CKComponentControllerScopeEnumerator)block
{
  if (!block) {
    CKFailAssert(@"Must be given a block to enumerate.");
    return;
  }
  CKAssert(_componentControllerPredicates.find(predicate) != _componentControllerPredicates.end(), @"Scope root must be initialized with predicate to enumerate.");
  for (auto it = _registeredComponentControllers.find(predicate); it != _registeredComponentControllers.end(); ++it) {
    block(it->second);
  }
}

- (CKScopedResponderManager *)responderManager
{
  return _responderManager;
}

- (void)applyPendingResponderMap
{
  std::lock_guard<std::mutex> l(_pendingMapAccess);
  [_responderManager setResponderMap:_pendingHandleToResponderMap];
  _pendingHandleToResponderMap.clear();
}

@end
