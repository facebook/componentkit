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

#include <tuple>

#import "CKMutex.h"
#import "CKThreadLocalComponentScope.h"

@interface CKTreeNode ()
@property (nonatomic, strong, readwrite) id<CKTreeNodeComponentProtocol> component;
@property (nonatomic, strong, readwrite) CKComponentScopeHandle *handle;
@property (nonatomic, assign, readwrite) CKTreeNodeIdentifier nodeIdentifier;
@end

@implementation CKTreeNode
{
  CKTreeNodeComponentKey _componentKey;
}

// Base initializer
- (instancetype)initWithPreviousNode:(id<CKTreeNodeProtocol>)previousNode
                              handle:(CKComponentScopeHandle *)handle
{
  static int32_t nextGlobalIdentifier = 0;
  if (self = [super init]) {
    _handle = handle;
    _nodeIdentifier = previousNode ? previousNode.nodeIdentifier : OSAtomicIncrement32(&nextGlobalIdentifier);
    // Set the link between the tree node and the scope handle.
    [handle setTreeNode:self];
  }
  return self;
}

// Non-Render initializer
- (instancetype)initWithComponent:(id<CKTreeNodeComponentProtocol>)component
                           parent:(id<CKTreeNodeWithChildrenProtocol>)parent
                   previousParent:(id<CKTreeNodeWithChildrenProtocol>)previousParent
                        scopeRoot:(CKComponentScopeRoot *)scopeRoot
                     stateUpdates:(const CKComponentStateUpdateMap &)stateUpdates
{
  auto const componentKey = [parent createComponentKeyForChildWithClass:[component class] identifier:nil];
  auto const previousNode = [previousParent childForComponentKey:componentKey];
  // For non-render components, the scope handle will be aquired from the component's base initializer.
  if (self = [self initWithPreviousNode:previousNode handle:component.scopeHandle]) {
    _component = component;
    _componentKey = componentKey;
    // Set the link between the parent and the child.
    [parent setChild:self forComponentKey:_componentKey];
    // Register the node-parent link in the scope root (we use it to mark dirty branch on a state update).
    scopeRoot.rootNode.registerNode(self, parent);
#if DEBUG
    [component acquireTreeNode:self];
#endif
  }
  return self;
}

// Render initializer
- (instancetype)initWithRenderComponent:(id<CKRenderComponentProtocol>)component
                                 parent:(id<CKTreeNodeWithChildrenProtocol>)parent
                         previousParent:(id<CKTreeNodeWithChildrenProtocol>)previousParent
                              scopeRoot:(CKComponentScopeRoot *)scopeRoot
                           stateUpdates:(const CKComponentStateUpdateMap &)stateUpdates
{
  Class componentClass = [component class];
  auto const componentKey = [parent createComponentKeyForChildWithClass:componentClass identifier:[component componentIdentifier]];
  auto const previousNode = [previousParent childForComponentKey:componentKey];

  // For Render Layout components, the component might have a scope handle already.
  CKComponentScopeHandle *handle = component.scopeHandle;
  if (handle == nil) {
    // If there is a previous node, we just duplicate the scope handle.
    if (previousNode) {
      handle = [previousNode.handle newHandleWithStateUpdates:stateUpdates
                                           componentScopeRoot:scopeRoot];
    } else {
      // The component needs a scope handle in few cases:
      // 1. Has an initial state
      // 2. Has a controller
      // 3. Returns `YES` from `requiresScopeHandle`
      id initialState = [componentClass initialStateWithComponent:component];
      if (initialState != [CKTreeNodeEmptyState emptyState] ||
          [componentClass controllerClass] ||
          [componentClass requiresScopeHandle]) {
        handle = [[CKComponentScopeHandle alloc] initWithListener:scopeRoot.listener
                                                   rootIdentifier:scopeRoot.globalIdentifier
                                                   componentClass:componentClass
                                                     initialState:initialState];
      }
    }

    // Finalize the node/scope regsitration.
    if (handle) {
      [component acquireScopeHandle:handle];
      [scopeRoot registerComponent:component];
      [handle resolve];
    }
  }

  if (self = [self initWithPreviousNode:previousNode handle:component.scopeHandle]) {
    _component = component;
    _componentKey = componentKey;
    // Set the link between the parent and the child.
    [parent setChild:self forComponentKey:_componentKey];
    // Register the node-parent link in the scope root (we use it to mark dirty branch on a state update).
    scopeRoot.rootNode.registerNode(self, parent);
#if DEBUG
    [component acquireTreeNode:self];
#endif
  }
  return self;
}

- (id)state
{
  return _handle.state;
}

- (const CKTreeNodeComponentKey &)componentKey
{
  return _componentKey;
}

- (void)didReuseInScopeRoot:(CKComponentScopeRoot *)scopeRoot fromPreviousScopeRoot:(CKComponentScopeRoot *)previousScopeRoot
{
  auto const parent = previousScopeRoot.rootNode.parentForNodeIdentifier(_nodeIdentifier);
  CKAssert(parent != nil, @"The parent cannot be nil; every node should have a valid parent.");
  scopeRoot.rootNode.registerNode(self, parent);
  if (_handle) {
    // Register the reused comopnent in the new scope root.
    [scopeRoot registerComponent:_component];
    auto const controller = _handle.controller;
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

/**
 Implement a singletone empty state here.
 */
@implementation CKTreeNodeEmptyState
+ (id)emptyState
{
  static dispatch_once_t onceToken;
  static CKTreeNodeEmptyState *emptyState;
  dispatch_once(&onceToken, ^{
    emptyState = [CKTreeNodeEmptyState new];
  });
  return emptyState;
}
@end
