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

@interface CKTreeNode ()
@property (nonatomic, strong, readwrite) id<CKTreeNodeComponentProtocol> component;
@property (nonatomic, strong, readwrite) CKComponentScopeHandle *scopeHandle;
@property (nonatomic, assign, readwrite) CKTreeNodeIdentifier nodeIdentifier;
@end

@implementation CKTreeNode

// Base initializer
- (instancetype)initWithPreviousNode:(id<CKTreeNodeProtocol>)previousNode
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
                           parent:(id<CKTreeNodeWithChildrenProtocol>)parent
                   previousParent:(id<CKTreeNodeWithChildrenProtocol>)previousParent
                        scopeRoot:(CKComponentScopeRoot *)scopeRoot
                     stateUpdates:(const CKComponentStateUpdateMap &)stateUpdates
{
  Class componentClass = [component class];
  auto const componentKey = [parent createComponentKeyForChildWithClass:componentClass identifier:[component componentIdentifier]];
  auto const previousNode = [previousParent childForComponentKey:componentKey];

  // For Render Layout components, the component might have a scope handle already.
  CKComponentScopeHandle *scopeHandle = component.scopeHandle;
  if (scopeHandle == nil) {
    scopeHandle = CKRender::ScopeHandle::Render::create(component, componentClass, previousNode, scopeRoot, stateUpdates);
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
#if DEBUG
    [component acquireTreeNode:self];
#endif
  }
  return self;
}

- (void)linkComponent:(id<CKTreeNodeComponentProtocol>)component
             toParent:(id<CKTreeNodeWithChildrenProtocol>)parent
       previousParent:(id<CKTreeNodeWithChildrenProtocol> _Nullable)previousParent
               params:(const CKBuildComponentTreeParams &)params
{
  if (!params.mergeTreeNodesLinks)
  {
    auto const componentKey = [parent createComponentKeyForChildWithClass:[component class] identifier:nil];
    _componentKey = componentKey;
  }
  _component = component;
  // Set the link between the parent and the child.
  [parent setChild:self forComponentKey:_componentKey];
  // Register the node-parent link in the scope root (we use it to mark dirty branch on a state update).
  params.scopeRoot.rootNode.registerNode(self, parent);
#if DEBUG
  [component acquireTreeNode:self];
#endif
}

- (id)state
{
  return _scopeHandle.state;
}

- (const CKTreeNodeComponentKey &)componentKey
{
  return _componentKey;
}

- (void)didReuseInScopeRoot:(CKComponentScopeRoot *)scopeRoot
      fromPreviousScopeRoot:(CKComponentScopeRoot *)previousScopeRoot
        mergeTreeNodesLinks:(BOOL)mergeTreeNodesLinks
{
  auto const parent = previousScopeRoot.rootNode.parentForNodeIdentifier(_nodeIdentifier);
  CKAssert(parent != nil, @"The parent cannot be nil; every node should have a valid parent.");
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
}

#if DEBUG
/** Returns a multi-line string describing this node and its children nodes */
- (NSString *)debugDescription
{
  return [[self debugDescriptionNodes] componentsJoinedByString:@"\n"];
}

- (NSArray<NSString *> *)debugDescriptionNodes
{
  return @[[NSString stringWithFormat:@"- %@ %d - %@",
            [_component class],
            _nodeIdentifier,
            self]];
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
