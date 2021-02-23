/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKTreeNode.h"

#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKComponentInternal.h>
#import <ComponentKit/CKComponentSubclass.h>
#import <ComponentKit/CKInternalHelpers.h>
#import <ComponentKit/CKRenderComponentProtocol.h>
#import <ComponentKit/CKRootTreeNode.h>
#import <ComponentKit/CKMutex.h>

#include <tuple>

#import "CKThreadLocalComponentScope.h"
#import "CKRenderHelpers.h"

namespace CK {
namespace TreeNode {
  CKTreeNode *nodeForComponent(id<CKComponentProtocol> component)
  {
    CKThreadLocalComponentScope *currentScope = CKThreadLocalComponentScope::currentScope();
    if (currentScope == nullptr) {
      return nil;
    }

    // `nodeForComponent` is being called for every non-render component from the base constructor of `CKComponent`.
    // We can rely on this infomration to increase the `componentAllocations` counter.
    currentScope->componentAllocations++;

    CKTreeNode *node = currentScope->stack.top().node;
    if ([node.scopeHandle acquireFromComponent:component]) {
      return node;
    }
    RCCAssertWithCategory([component.class controllerClass] == nil ||
                          CKSubclassOverridesInstanceMethod([CKComponent class], component.class, @selector(buildController)) ||
                          [component conformsToProtocol:@protocol(CKRenderComponentProtocol)],
                          NSStringFromClass([component class]),
      @"Component has a controller but no scope! Make sure you construct your scope(self) "
      "before constructing the component or CKComponentTestRootScope at the start of the test.");

    return nil;
  }
}
}


@interface CKTreeNode ()
@property (nonatomic, weak, readwrite) id<CKTreeNodeComponentProtocol> component;
@property (nonatomic, strong, readwrite) CKComponentScopeHandle *scopeHandle;
@property (nonatomic, assign, readwrite) CKTreeNodeIdentifier nodeIdentifier;
@end

@implementation CKTreeNode

// Base initializer
- (instancetype)initWithPreviousNode:(CKTreeNode *)previousNode
                         scopeHandle:(CKComponentScopeHandle *)scopeHandle
{
  static int32_t nextGlobalIdentifier = 0;
  if (self = [super init]) {
    _scopeHandle = scopeHandle;
    _nodeIdentifier = previousNode ? previousNode.nodeIdentifier : OSAtomicIncrement32(&nextGlobalIdentifier);
  }
  return self;
}

// Render initializer
- (instancetype)initWithComponent:(id<CKRenderComponentProtocol>)component
                           parent:(CKTreeNode *)parent
                   previousParent:(CKTreeNode *)previousParent
                        scopeRoot:(CKComponentScopeRoot *)scopeRoot
                     stateUpdates:(const CKComponentStateUpdateMap &)stateUpdates
{
  auto const componentKey = [parent createParentKeyForComponentTypeName:component.typeName
                                                             identifier:[component componentIdentifier]
                                                                   keys:{}];

  auto const previousNode = [previousParent childForComponentKey:componentKey];

  // For Render Layout components, the component might have a scope handle already.
  CKComponentScopeHandle *scopeHandle = component.scopeHandle;
  if (scopeHandle == nil) {
    scopeHandle = CKRender::ScopeHandle::Render::create(component, previousNode, scopeRoot, stateUpdates);
  }

  if (self = [self initWithPreviousNode:previousNode scopeHandle:scopeHandle]) {
    _component = component;
    _componentKey = componentKey;
    // Set the link between the parent and the child.
    [parent setChild:self forComponentKey:_componentKey];
    // Register the node-parent link in the scope root (we use it to mark dirty branch on a state update).
    scopeRoot.rootNode.registerNode(self, parent);
    // Set the link between the tree node and the scope handle.
    [scopeHandle setTreeNode:self];
    // Update the treeNode on the component
    [component acquireTreeNode:self];
    // Finalize the node/scope registration.
    [scopeHandle forceAcquireFromComponent:component];
    [scopeHandle resolveAndRegisterInScopeRoot:scopeRoot];
  }
  return self;
}

- (void)linkComponent:(id<CKTreeNodeComponentProtocol>)component
             toParent:(CKTreeNode *)parent
       previousParent:(CKTreeNode *_Nullable)previousParent
               params:(const CKBuildComponentTreeParams &)params
{
  // The existing `_componentKey` that was created by the scope, is an owner based key;
  // hence, we extract the `unique identifer` and the `keys` vector from it and recreate a parent based key based on this information.
  auto const componentKey = [parent createParentKeyForComponentTypeName:component.typeName
                                                             identifier:_componentKey.identifier
                                                                   keys:_componentKey.keys];
  _componentKey = componentKey;

  // Set the link between the parent and the child.
  [parent setChild:self forComponentKey:_componentKey];

  _component = component;
  // Register the node-parent link in the scope root (we use it to mark dirty branch on a state update).
  params.scopeRoot.rootNode.registerNode(self, parent);
}

- (id)state
{
  return _scopeHandle.state;
}

- (const CKTreeNodeComponentKey &)componentKey
{
  return _componentKey;
}

- (void)didReuseWithParent:(CKTreeNode *)parent
               inScopeRoot:(CKComponentScopeRoot *)scopeRoot
{
  // In case that CKComponentScope was created, but not acquired from the component (for example: early nil return) ,
  // the component was never linked to the scope handle/tree node, hence, we should stop the recursion here.
  if (self.component == nil) {
    return;
  }

  RCAssert(parent != nil, @"The parent cannot be nil; every node should have a valid parent.");
  scopeRoot.rootNode.registerNode(self, parent);
  if (_scopeHandle) {
    // Register the reused comopnent in the new scope root.
    [scopeRoot registerComponent:_component];
    auto const controller = _scopeHandle.controller;
    if (controller) {
      // Register the controller in the new scope root.
      [scopeRoot registerComponentController:controller];
    }
  }

  for (auto const &child : _children) {
    if (child.key.type() == CKTreeNodeComponentKey::Type::parent) {
      [child.node didReuseWithParent:self inScopeRoot:scopeRoot];
    }
  }
}

- (std::vector<CKTreeNode *>)children
{
  std::vector<CKTreeNode *> children;
  for (auto const &child : _children) {
    if (child.key.type() == CKTreeNodeComponentKey::Type::parent) {
      children.push_back(child.node);
    }
  }
  return children;
}

- (size_t)childrenSize
{
  return _children.size();
}

- (CKTreeNode *)childForComponentKey:(const CKTreeNodeComponentKey &)key
{
  for (auto const &child : _children) {
    if (child.key == key) {
      return child.node;
    }
  }
  return nil;
}

- (CKTreeNodeComponentKey)createParentKeyForComponentTypeName:(const char *)componentTypeName
                                                   identifier:(id<NSObject>)identifier
                                                         keys:(const std::vector<id<NSObject>> &)keys
{
  // Create **parent** based key counter.
  NSUInteger keyCounter = CKTreeNodeComponentKey::kCounterParentOffset;
  for (auto const &child : _children) {
    if (child.key.componentTypeName == componentTypeName && RCObjectIsEqual(child.key.identifier, identifier)) {
      keyCounter += 2;
    }
  }

  return CKTreeNodeComponentKey{componentTypeName, keyCounter, identifier, keys};
}

- (void)setChild:(CKTreeNode *)child forComponentKey:(const CKTreeNodeComponentKey &)componentKey
{
  _children.push_back(CKTreeNodeComponentKeyToNode{.key = componentKey, .node = child});
}

- (CKTreeNodeComponentKey)createKeyForComponentTypeName:(const char *)componentTypeName
                                             identifier:(id)identifier
                                                   keys:(const std::vector<id<NSObject>> &)keys
{
  // Create **owner** based key counter.
  NSUInteger keyCounter = CKTreeNodeComponentKey::kCounterOwnerOffset;
  for (auto const &child : _children) {
    if (child.key.componentTypeName == componentTypeName && RCObjectIsEqual(child.key.identifier, identifier)) {
      keyCounter += 2;
    }
  }
  // Update the stateKey with the type name key counter to make sure we don't have collisions.
  return CKTreeNodeComponentKey{componentTypeName, keyCounter, identifier, keys};
}

static CKComponentScopeHandle *_createScopeHandle(CKComponentScopeRoot *scopeRoot,
                                                  CKTreeNode *previousNode,
                                                  const char *componentTypeName,
                                                  id (^initialStateCreator)(void),
                                                  const CKComponentStateUpdateMap &stateUpdates,
                                                  BOOL requiresScopeHandle) {
  RCCAssertNotNil(initialStateCreator, @"Must have an initial state creator");

  if (requiresScopeHandle == NO) {
    RCCAssertNil(previousNode.scopeHandle, @"requiresScopeHandle is false but previous node has scope handle");
    return nil;
  }

  if (previousNode != nil) {
    RCCAssertNotNil(previousNode.scopeHandle, @"requiresScopeHandle is true but no scopeHandle on previous node");
    return [previousNode.scopeHandle newHandleWithStateUpdates:stateUpdates];
  } else {
    return [[CKComponentScopeHandle alloc] initWithListener:scopeRoot.listener
                                             rootIdentifier:scopeRoot.globalIdentifier
                                          componentTypeName:componentTypeName
                                               initialState:(initialStateCreator ? initialStateCreator() : nil)];
  }
}

+ (CKComponentScopePair)childPairForPair:(const CKComponentScopePair &)pair
                                 newRoot:(CKComponentScopeRoot *)newRoot
                       componentTypeName:(const char *)componentTypeName
                              identifier:(id)identifier
                                    keys:(const std::vector<id<NSObject>> &)keys
                     initialStateCreator:(id (^)(void))initialStateCreator
                            stateUpdates:(const CKComponentStateUpdateMap &)stateUpdates
                     requiresScopeHandle:(BOOL)requiresScopeHandle
{
  RCAssertNotNil(pair.node, @"Must have a node");
  RCAssertNotNil(initialStateCreator, @"Must has an initial state creator");

  // Generate key inside the new parent
  CKTreeNodeComponentKey componentKey = [pair.node createKeyForComponentTypeName:componentTypeName
                                                                      identifier:identifier
                                                                            keys:keys];
  // Get the child from the previous equivalent scope.
  CKTreeNode *childScopeFromPreviousScope = [pair.previousNode childForComponentKey:componentKey];

  return [self childPairForPair:pair
                        newRoot:newRoot
              componentTypeName:componentTypeName
                   componentKey:componentKey
    childScopeFromPreviousNode:childScopeFromPreviousScope
            initialStateCreator:initialStateCreator
                   stateUpdates:stateUpdates
            requiresScopeHandle:requiresScopeHandle];
}

+ (CKComponentScopePair)childPairForPair:(const CKComponentScopePair &)pair
                                 newRoot:(CKComponentScopeRoot *)newRoot
                       componentTypeName:(const char *)componentTypeName
                            componentKey:(const CKTreeNodeComponentKey &)componentKey
              childScopeFromPreviousNode:(CKTreeNode *)childScopeFromPreviousScope
                     initialStateCreator:(id (^)(void))initialStateCreator
                            stateUpdates:(const CKComponentStateUpdateMap &)stateUpdates
                     requiresScopeHandle:(BOOL)requiresScopeHandle
{
  RCAssertNotNil(pair.node, @"Must have a node");
  RCAssertNotNil(initialStateCreator, @"Must has an initial state creator");

  // Create new handle.
  CKComponentScopeHandle *newHandle = _createScopeHandle(newRoot, childScopeFromPreviousScope, componentTypeName, initialStateCreator, stateUpdates, requiresScopeHandle);

  // Create new node.
  CKTreeNode *newChild = [[CKTreeNode alloc]
                               initWithPreviousNode:childScopeFromPreviousScope
                               scopeHandle:newHandle];

  // Link the tree node to the scope handle.
  [newHandle setTreeNode:newChild];

  // Insert the new node to its parent map.
  [pair.node setChild:newChild forComponentKey:componentKey];

  // Update the component key on the new child.
  newChild->_componentKey = componentKey;
  return {.node = newChild, .previousNode = childScopeFromPreviousScope};
}

#pragma mark - Helpers

#if DEBUG
// Iterate threw the nodes according to the **parent** based key
- (NSArray<NSString *> *)debugDescriptionNodes
{
  NSString *const selfDescription = [NSString stringWithFormat:@"- %s %d - %@",
                                     _component.typeName,
                                     _nodeIdentifier,
                                     self];
  NSMutableArray<NSString *> *debugDescriptionNodes = [NSMutableArray arrayWithArray:@[selfDescription]];
  for (auto const &child : _children) {
    if (child.key.type() == CKTreeNodeComponentKey::Type::parent) {
      for (NSString *s in [child.node debugDescriptionNodes]) {
        [debugDescriptionNodes addObject:[@"  " stringByAppendingString:s]];
      }
    }
  }
  return debugDescriptionNodes;
}

// Iterate threw the nodes according to the **owner** based key
- (NSArray<NSString *> *)debugDescriptionComponents
{
  NSMutableArray<NSString *> *childrenDebugDescriptions = [NSMutableArray new];
  for (auto const &child : _children) {
    if (child.key.type() == CKTreeNodeComponentKey::Type::owner) {
      auto const description = [NSString stringWithFormat:@"- %s%@%@",
                                child.key.componentTypeName,
                                (child.key.identifier
                                 ? [NSString stringWithFormat:@":%@", child.key.identifier]
                                 : @""),
                                child.key.keys.empty() ? @"" : formatKeys(child.key.keys)];
      [childrenDebugDescriptions addObject:description];
      for (NSString *s in [(CKTreeNode *)child.node debugDescriptionComponents]) {
        [childrenDebugDescriptions addObject:[@"  " stringByAppendingString:s]];
      }
    }
  }
  return childrenDebugDescriptions;
}

static NSString *formatKeys(const std::vector<id<NSObject>> &keys)
{
  NSMutableArray<NSString *> *a = [NSMutableArray new];
  for (auto key : keys) {
    [a addObject:[key description] ?: @"(null)"];
  }
  return [a componentsJoinedByString:@", "];
}

/** Returns a multi-line string describing this node and its children nodes */
- (NSString *)debugDescription
{
  return [[self debugDescriptionNodes] componentsJoinedByString:@"\n"];
}

#endif

@end

id CKTreeNodeEmptyState(void)
{
  static dispatch_once_t onceToken;
  static id emptyState;
  dispatch_once(&onceToken, ^{
    emptyState = [NSObject new];
  });
  return emptyState;
}
