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

#import "CKTreeNodeWithChild.h"
#import "CKComponentProtocol.h"
#import "CKComponentControllerProtocol.h"
#import "CKComponentScopeFrameInternal.h"
#import "CKInternalHelpers.h"
#import "CKThreadLocalComponentScope.h"
#import "CKRenderTreeNodeWithChildren.h"

typedef std::unordered_map<CKComponentPredicate, NSHashTable<id<CKComponentProtocol>> *> _CKRegisteredComponentsMap;
typedef std::unordered_map<CKComponentControllerPredicate, NSHashTable<id<CKComponentControllerProtocol>> *> _CKRegisteredComponentControllerMap;

@implementation CKComponentScopeRoot
{
  std::unordered_set<CKComponentPredicate> _componentPredicates;
  std::unordered_set<CKComponentControllerPredicate> _componentControllerPredicates;

  _CKRegisteredComponentsMap _registeredComponents;
  _CKRegisteredComponentControllerMap _registeredComponentControllers;
  // A map between a tree node identifier to its parent node.
  std::unordered_map<CKTreeNodeIdentifier, id<CKTreeNodeProtocol>> _nodesToParentNodes;
}

+ (instancetype)rootWithListener:(id<CKComponentStateListener>)listener
               analyticsListener:(id<CKAnalyticsListener>)analyticsListener
             componentPredicates:(const std::unordered_set<CKComponentPredicate> &)componentPredicates
   componentControllerPredicates:(const std::unordered_set<CKComponentControllerPredicate> &)componentControllerPredicates
{
  static int32_t nextGlobalIdentifier = 0;
  return [[CKComponentScopeRoot alloc] initWithListener:listener
                                      analyticsListener:analyticsListener
                                       globalIdentifier:OSAtomicIncrement32(&nextGlobalIdentifier)
                                    componentPredicates:componentPredicates
                          componentControllerPredicates:componentControllerPredicates];
}

- (instancetype)newRoot
{
  return [[CKComponentScopeRoot alloc] initWithListener:_listener
                                      analyticsListener:_analyticsListener
                                       globalIdentifier:_globalIdentifier
                                    componentPredicates:_componentPredicates
                          componentControllerPredicates:_componentControllerPredicates];
}

- (instancetype)initWithListener:(id<CKComponentStateListener>)listener
               analyticsListener:(id<CKAnalyticsListener>)analyticsListener
                globalIdentifier:(CKComponentScopeRootIdentifier)globalIdentifier
             componentPredicates:(const std::unordered_set<CKComponentPredicate> &)componentPredicates
   componentControllerPredicates:(const std::unordered_set<CKComponentControllerPredicate> &)componentControllerPredicates
{
  if (self = [super init]) {
    _listener = listener;
    _analyticsListener = analyticsListener;
    _globalIdentifier = globalIdentifier;
    _rootFrame = [[CKComponentScopeFrame alloc] initWithHandle:nil];
    _rootNode = [[CKRenderTreeNodeWithChildren alloc] init];
    _componentPredicates = componentPredicates;
    _componentControllerPredicates = componentControllerPredicates;
  }
  return self;
}

- (void)registerComponent:(id<CKComponentProtocol>)component
{
  if (!component) {
    // Handle this gracefully so we don't have a bunch of nils being passed to predicates.
    return;
  }
  for (const auto &predicate : _componentPredicates) {
    if (predicate(component)) {
      auto hashTable = _registeredComponents[predicate];
      if (!hashTable) {
        hashTable = [NSHashTable weakObjectsHashTable];
        _registeredComponents[predicate] = hashTable;
      }
      [hashTable addObject:component];
    }
  }
}

- (void)registerComponentController:(id<CKComponentControllerProtocol>)componentController
{
  if (!componentController) {
    // As above, handle a nil component controller gracefully instead of passing through to predicate.
    return;
  }
  for (const auto &predicate : _componentControllerPredicates) {
    if (predicate(componentController)) {
      auto hashTable = _registeredComponentControllers[predicate];
      if (!hashTable) {
        hashTable = [NSHashTable weakObjectsHashTable];
        _registeredComponentControllers[predicate] = hashTable;
      }
      [hashTable addObject:componentController];
    }
  }
}

- (void)registerNode:(id<CKTreeNodeProtocol>)node withParent:(id<CKTreeNodeProtocol>)parent
{
  CKAssert(parent != nil, @"Cannot register a nil parent node");
  if (node) {
    _nodesToParentNodes[node.nodeIdentifier] = parent;
  }
}

- (id<CKTreeNodeProtocol>)parentForNodeIdentifier:(CKTreeNodeIdentifier)nodeIdentifier
{
  CKAssert(nodeIdentifier != 0, @"Cannot retrieve parent for an empty node");
  auto const it = _nodesToParentNodes.find(nodeIdentifier);
  if (it != _nodesToParentNodes.end()) {
    return it->second;
  }
  return nil;
}

- (void)enumerateComponentsMatchingPredicate:(CKComponentPredicate)predicate
                                       block:(CKComponentScopeEnumerator)block
{
  if (!block) {
    CKFailAssert(@"Must be given a block to enumerate.");
    return;
  }
  CKAssert(_componentPredicates.find(predicate) != _componentPredicates.end(), @"Scope root must be initialized with predicate to enumerate.");

  const auto foundIter = _registeredComponents.find(predicate);
  if (foundIter != _registeredComponents.end()) {
    for (id<CKComponentProtocol> component in foundIter->second) {
      block(component);
    }
  }
}

- (CKCocoaCollectionAdapter<id<CKComponentProtocol>>)componentsMatchingPredicate:(CKComponentPredicate)predicate
{
  CKCAssert(CK::Collection::contains(_componentPredicates, predicate), @"Scope root must be initialized with predicate to enumerate.");
  const auto componentsIt = _registeredComponents.find(predicate);
  const auto components = componentsIt != _registeredComponents.end() ? componentsIt->second : @[];
  return CKCocoaCollectionAdapter<id<CKComponentProtocol>>(components);
}

- (void)enumerateComponentControllersMatchingPredicate:(CKComponentControllerPredicate)predicate
                                                 block:(CKComponentControllerScopeEnumerator)block
{
  if (!block) {
    CKFailAssert(@"Must be given a block to enumerate.");
    return;
  }
  CKAssert(_componentControllerPredicates.find(predicate) != _componentControllerPredicates.end(), @"Scope root must be initialized with predicate to enumerate.");

  const auto foundIter = _registeredComponentControllers.find(predicate);
  if (foundIter != _registeredComponentControllers.end()) {
    for (id<CKComponentControllerProtocol> componentController in foundIter->second) {
      block(componentController);
    }
  }
}

- (CKCocoaCollectionAdapter<id<CKComponentControllerProtocol>>)componentControllersMatchingPredicate:(CKComponentControllerPredicate)predicate
{
  CKAssert(_componentControllerPredicates.find(predicate) != _componentControllerPredicates.end(), @"Scope root must be initialized with predicate to enumerate.");
  const auto componentControllersIt = _registeredComponentControllers.find(predicate);
  const auto componentControllers = componentControllersIt != _registeredComponentControllers.end() ? componentControllersIt->second : @[];
  return CKCocoaCollectionAdapter<id<CKComponentControllerProtocol>>(componentControllers);
}

#if DEBUG
- (NSString *)debugDescription
{
  return [[_rootFrame debugDescriptionComponents] componentsJoinedByString:@"\n"];
}
#endif

@end
