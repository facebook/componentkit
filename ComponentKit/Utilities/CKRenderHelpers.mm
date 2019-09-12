/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKRenderHelpers.h"

#import <ComponentKit/CKRenderComponent.h>
#import <ComponentKit/CKComponentContextHelper.h>
#import <ComponentKit/CKComponentScopeFrame.h>
#import <ComponentKit/CKComponentScopeRoot.h>
#import <ComponentKit/CKMutex.h>
#import <ComponentKit/CKOptional.h>
#import <ComponentKit/CKTreeNodeProtocol.h>
#import <ComponentKit/CKTreeNodeWithChild.h>
#import <ComponentKit/CKTreeNodeWithChildren.h>

#import "CKScopeTreeNode.h"
#import "CKRenderTreeNode.h"

namespace CKRenderInternal {

  namespace ScopeEvents {

    static auto willBuildComponentTree(id<CKTreeNodeProtocol> node, const CKBuildComponentTreeParams &params) {
      // Update the scope frame of the reuse of this component in order to transfer the render scope frame.
      if (params.unifyComponentTreeConfig.enable) {
        // if `useRenderNodes` equals to 'YES', the base constructor of the `CKRenderTreeNode` will push itself to the stack.
        if (!params.unifyComponentTreeConfig.useRenderNodes) {
          [CKScopeTreeNode willBuildComponentTreeWithTreeNode:node];
        }
      } else {
        [CKComponentScopeFrame willBuildComponentTreeWithTreeNode:node];
      }
    }

    static auto didBuildComponentTree(id<CKTreeNodeProtocol> node, const CKBuildComponentTreeParams &params) {
      if (params.unifyComponentTreeConfig.enable) {
        if (params.unifyComponentTreeConfig.useRenderNodes) {
          [CKRenderTreeNode didBuildComponentTreeWithNode:node];
        } else {
          [CKScopeTreeNode didBuildComponentTreeWithNode:node];
        }
      } else {
        [CKComponentScopeFrame didBuildComponentTreeWithNode:node];
      }
    }

    static auto didReuseNode(id<CKTreeNodeWithChildProtocol> node,
                             id<CKTreeNodeWithChildProtocol> previousNode,
                             const CKBuildComponentTreeParams &params) {
      // Update the scope frame of the reuse of this component in order to transfer the render scope frame.
      if (params.unifyComponentTreeConfig.enable) {
        if (params.unifyComponentTreeConfig.useRenderNodes) {
          [(CKRenderTreeNode *)node didReuseNode:(CKRenderTreeNode *)previousNode];
        } else {
          [CKScopeTreeNode didReuseRenderWithTreeNode:node];
        }
      } else {
        [CKComponentScopeFrame didReuseRenderWithTreeNode:node];
      }
    }
  }

  // Reuse the previous component generation and its component tree and notify the previous component about it.
  static auto reusePreviousComponent(id<CKRenderComponentProtocol> component,
                                     __strong id<CKTreeNodeComponentProtocol> *childComponent,
                                     id<CKTreeNodeWithChildProtocol> node,
                                     id<CKTreeNodeWithChildProtocol> previousNode,
                                     const CKBuildComponentTreeParams &params,
                                     CKRenderDidReuseComponentBlock didReuseBlock) -> void {
    auto const reusedChild = previousNode.child;
    // Set the child from the previous tree node.
    node.child = reusedChild;
    // Save the reused node in the scope root for the next component creation.
    [reusedChild didReuseInScopeRoot:params.scopeRoot fromPreviousScopeRoot:params.previousScopeRoot];
    // Update the new parent in the new scope root
    params.scopeRoot.rootNode.registerNode(reusedChild, node);

    // Update the scope frame of the reuse of this node.
    ScopeEvents::didReuseNode(node, previousNode, params);

    auto const prevChildComponent = [(id<CKTreeNodeWithChildProtocol>)previousNode child].component;

    if (childComponent != nullptr) {
      // Link the previous child component to the the new component.
      *childComponent = prevChildComponent;
    }

    auto const previousComponent = (id<CKRenderComponentProtocol>)previousNode.component;
    if (didReuseBlock) {
      didReuseBlock(previousComponent);
    }
    // Notify the new component about the reuse of the previous component.
    [component didReuseComponent:previousComponent];

    // Notify scope root listener
    [params.scopeRoot.analyticsListener didReuseNode:node inScopeRoot:params.scopeRoot fromPreviousScopeRoot:params.previousScopeRoot];
  }

  // Reuse the previous component generation and its component tree and notify the previous component about it.
  static auto reusePreviousComponent(id<CKRenderComponentProtocol> component,
                                     __strong id<CKTreeNodeComponentProtocol> *childComponent,
                                     CKTreeNodeWithChild *node,
                                     id<CKTreeNodeWithChildrenProtocol> parent,
                                     id<CKTreeNodeWithChildrenProtocol> previousParent,
                                     const CKBuildComponentTreeParams &params,
                                     CKRenderDidReuseComponentBlock didReuseBlock) -> BOOL {
    auto const previousNode = (CKTreeNodeWithChild *)[previousParent childForComponentKey:node.componentKey];
    if (previousNode) {
      CKRenderInternal::reusePreviousComponent(component, childComponent, node, previousNode, params, didReuseBlock);
      return YES;
    }
    return NO;
  }

  // Check if shouldComponentUpdate returns `NO`; if it does, reuse the previous component generation and its component tree and notify the previous component about it.
  static auto reusePreviousComponentIfComponentsAreEqual(id<CKRenderComponentProtocol> component,
                                                         __strong id<CKTreeNodeComponentProtocol> *childComponent,
                                                         CKTreeNodeWithChild *node,
                                                         id<CKTreeNodeWithChildrenProtocol> parent,
                                                         id<CKTreeNodeWithChildrenProtocol> previousParent,
                                                         const CKBuildComponentTreeParams &params,
                                                         CKRenderDidReuseComponentBlock didReuseBlock) -> BOOL {
    auto const previousNode = (CKTreeNodeWithChild *)[previousParent childForComponentKey:node.componentKey];
    auto const previousComponent = (id<CKRenderComponentProtocol>)previousNode.component;
    // If there is no previous compononet, there is nothing to reuse.
    if (previousComponent) {
      // We check if the component node is dirty in the **previous** scope root.
      auto const dirtyNodeIdsForPropsUpdates = params.previousScopeRoot.rootNode.dirtyNodeIdsForPropsUpdates();
      auto const dirtyNodeId = dirtyNodeIdsForPropsUpdates.find(node.nodeIdentifier);
      if (dirtyNodeId == params.treeNodeDirtyIds.end()) {
        [params.systraceListener willCheckShouldComponentUpdate:component];
        auto const shouldComponentUpdate = [component shouldComponentUpdate:previousComponent];
        [params.systraceListener didCheckShouldComponentUpdate:component];
        if (!shouldComponentUpdate) {
          CKRenderInternal::reusePreviousComponent(component, childComponent, node, previousNode, params, didReuseBlock);
          return YES;
        }
      }
    }
    return NO;
  }

  static auto reusePreviousComponentForSingleChild(CKTreeNodeWithChild *node,
                                                   id<CKRenderWithChildComponentProtocol> component,
                                                   __strong id<CKTreeNodeComponentProtocol> *childComponent,
                                                   id<CKTreeNodeWithChildrenProtocol> parent,
                                                   id<CKTreeNodeWithChildrenProtocol> previousParent,
                                                   const CKBuildComponentTreeParams &params,
                                                   BOOL parentHasStateUpdate,
                                                   CKRenderDidReuseComponentBlock didReuseBlock) -> BOOL {

    // If there is no previous parent or no childComponent, we bail early.
    if (previousParent == nil || childComponent == nullptr) {
      return NO;
    }

    // Check if the reuse components optimizations are off.
    if (params.ignoreComponentReuseOptimizations) {
      return NO;
    }

    // State update branch:
    if (params.buildTrigger == BuildTrigger::StateUpdate) {
      // Check if the tree node is not dirty (not in a branch of a state update).
      auto const dirtyNodeId = params.treeNodeDirtyIds.find(node.nodeIdentifier);
      if (dirtyNodeId == params.treeNodeDirtyIds.end()) {
        // We reuse the component without checking `shouldComponentUpdate:` in the following conditions:
        // 1. The component is not dirty (on a state update branch)
        // 2. No direct parent has a state update
        if (!parentHasStateUpdate) {
          // Faster state update optimizations.
          return CKRenderInternal::reusePreviousComponent(component, childComponent, node, parent, previousParent, params, didReuseBlock);
        }
        // We fallback to the props update optimization in the follwing case:
        // - The component is not dirty, but the parent has a state update.
        return (CKRenderInternal::reusePreviousComponentIfComponentsAreEqual(component, childComponent, node, parent, previousParent, params, didReuseBlock));
      }
    }
    // Props update branch:
    else if (params.buildTrigger == BuildTrigger::PropsUpdate) {
      return CKRenderInternal::reusePreviousComponentIfComponentsAreEqual(component, childComponent, node, parent, previousParent, params, didReuseBlock);
    }

    return NO;
  }

  static auto willBuildComponentTreeWithChild(id<CKTreeNodeProtocol> node,
                                              id<CKTreeNodeComponentProtocol> component,
                                              const CKBuildComponentTreeParams &params) -> void {
    // Context support
    CKComponentContextHelper::willBuildComponentTree(component);

    // Faster Props updates and context support
    params.scopeRoot.rootNode.willBuildComponentTree(node);

    // Systrace logging
    [params.systraceListener willBuildComponent:component.class];
  }

  static auto didBuildComponentTreeWithChild(id<CKTreeNodeProtocol> node,
                                             id<CKTreeNodeComponentProtocol> component,
                                             const CKBuildComponentTreeParams &params) -> void {
    // Context support
    CKComponentContextHelper::didBuildComponentTree(component);

    // Props updates and context support
    params.scopeRoot.rootNode.didBuildComponentTree(node);

    // Systrace logging
    [params.systraceListener didBuildComponent:component.class];
  }

}

namespace CKRender {
  auto buildComponentTreeWithPrecomputedChild(id<CKTreeNodeComponentProtocol> component,
                                              id<CKTreeNodeComponentProtocol> childComponent,
                                              id<CKTreeNodeWithChildrenProtocol> parent,
                                              id<CKTreeNodeWithChildrenProtocol> previousParent,
                                              const CKBuildComponentTreeParams &params,
                                              BOOL parentHasStateUpdate) -> void
  {
    CKCAssert(component, @"component cannot be nil");

    // Check if the component already have tree node (Tree Unification Mode).
    auto node = component.scopeHandle.treeNode;
    if (node) {
      [node linkComponent:component toParent:parent scopeRoot:params.scopeRoot];
    } else {
      node = [[CKTreeNodeWithChild alloc]
              initWithComponent:component
              parent:parent
              previousParent:previousParent
              scopeRoot:params.scopeRoot
              stateUpdates:params.stateUpdates];
    }

    // Update the `parentHasStateUpdate` param for Faster state/props updates.
    if (!parentHasStateUpdate && CKRender::componentHasStateUpdate(node, previousParent, params)) {
      parentHasStateUpdate = YES;
    }

    // Report information to `debugAnalyticsListener`.
    if (params.shouldCollectTreeNodeCreationInformation) {
      [params.scopeRoot.analyticsListener didBuildTreeNodeForPrecomputedChild:component
                                                                         node:node
                                                                       parent:parent
                                                                       params:params
                                                         parentHasStateUpdate:parentHasStateUpdate];
    }

    if (childComponent) {
      [childComponent buildComponentTree:(id<CKTreeNodeWithChildrenProtocol>)node
                          previousParent:(id<CKTreeNodeWithChildrenProtocol>)[previousParent childForComponentKey:[node componentKey]]
                                  params:params
                    parentHasStateUpdate:parentHasStateUpdate];
    }
  }

  auto buildComponentTreeWithPrecomputedChildren(id<CKTreeNodeComponentProtocol> component,
                                                 std::vector<id<CKTreeNodeComponentProtocol>> childrenComponents,
                                                 id<CKTreeNodeWithChildrenProtocol> parent,
                                                 id<CKTreeNodeWithChildrenProtocol> previousParent,
                                                 const CKBuildComponentTreeParams &params,
                                                 BOOL parentHasStateUpdate) -> void
  {
    CKCAssert(component, @"component cannot be nil");
    // Check if the component already have tree node (Tree Unification Mode).
    auto node = component.scopeHandle.treeNode;
    if (node) {
      [node linkComponent:component toParent:parent scopeRoot:params.scopeRoot];
    } else {
      node = [[CKTreeNodeWithChildren alloc]
              initWithComponent:component
              parent:parent
              previousParent:previousParent
              scopeRoot:params.scopeRoot
              stateUpdates:params.stateUpdates];
    }

    // Update the `parentHasStateUpdate` param for Faster state/props updates.
    if (!parentHasStateUpdate && CKRender::componentHasStateUpdate(node, previousParent, params)) {
      parentHasStateUpdate = YES;
    }

    for (auto const childComponent : childrenComponents) {
      if (childComponent) {
        [childComponent buildComponentTree:(id<CKTreeNodeWithChildrenProtocol>)node
                            previousParent:(id<CKTreeNodeWithChildrenProtocol>)[previousParent childForComponentKey:[node componentKey]]
                                    params:params
                      parentHasStateUpdate:parentHasStateUpdate];
      }
    }
  }

  auto buildComponentTreeForRenderLayoutComponent(id<CKRenderWithChildComponentProtocol> component,
                                                  id<CKTreeNodeWithChildrenProtocol> parent,
                                                  id<CKTreeNodeWithChildrenProtocol> previousParent,
                                                  const CKBuildComponentTreeParams &params,
                                                  BOOL parentHasStateUpdate) -> id<CKTreeNodeProtocol>
  {
    CKCAssert(component, @"component cannot be nil");
    id<CKTreeNodeWithChildrenProtocol> node = (id<CKTreeNodeWithChildrenProtocol>)component.scopeHandle.treeNode;
    if (node == nil) {
      node = [[CKTreeNodeWithChild alloc]
              initWithRenderComponent:component
              parent:parent
              previousParent:previousParent
              scopeRoot:params.scopeRoot
              stateUpdates:params.stateUpdates];
    } else {
      [node linkComponent:component toParent:parent scopeRoot:params.scopeRoot];
    }

    // Update the `parentHasStateUpdate` param for Faster state/props updates.
    if (!parentHasStateUpdate && CKRender::componentHasStateUpdate(node, previousParent, params)) {
      parentHasStateUpdate = YES;
    }

    auto const child = [component render:node.state];
    if (child) {
      // Call build component tree on the child component.
      [child buildComponentTree:node
                 previousParent:(id<CKTreeNodeWithChildrenProtocol>)[previousParent childForComponentKey:[node componentKey]]
                         params:params
           parentHasStateUpdate:parentHasStateUpdate];
    }

    return node;
  }

  auto buildComponentTreeForRenderComponent(id<CKRenderWithChildComponentProtocol> component,
                                            __strong id<CKTreeNodeComponentProtocol> *childComponent,
                                            id<CKTreeNodeWithChildrenProtocol> parent,
                                            id<CKTreeNodeWithChildrenProtocol> previousParent,
                                            const CKBuildComponentTreeParams &params,
                                            BOOL parentHasStateUpdate,
                                            CKRenderDidReuseComponentBlock didReuseBlock) -> id<CKTreeNodeProtocol>
  {
    CKCAssert(component, @"component cannot be nil");
    id<CKTreeNodeWithChildrenProtocol> node;
    if (params.unifyComponentTreeConfig.useRenderNodes) {
      node = [[CKRenderTreeNode alloc]
              initWithRenderComponent:component
              parent:parent
              previousParent:previousParent
              scopeRoot:params.scopeRoot
              stateUpdates:params.stateUpdates];
    } else {
      node = [[CKTreeNodeWithChild alloc]
              initWithRenderComponent:component
              parent:parent
              previousParent:previousParent
              scopeRoot:params.scopeRoot
              stateUpdates:params.stateUpdates];
    }

    CKRenderInternal::willBuildComponentTreeWithChild(node, component, params);

    // Faster state/props optimizations require previous parent.
    if (CKRenderInternal::reusePreviousComponentForSingleChild((id<CKTreeNodeWithChildProtocol>)node, component, childComponent, parent, previousParent, params, parentHasStateUpdate, didReuseBlock)) {
      CKRenderInternal::didBuildComponentTreeWithChild(node, component, params);
      return node;
    }

    // Update the `parentHasStateUpdate` param for Faster state/props updates.
    if (!parentHasStateUpdate && CKRender::componentHasStateUpdate(node, previousParent, params)) {
      parentHasStateUpdate = YES;
    }

    CKRenderInternal::ScopeEvents::willBuildComponentTree(node, params);

    auto const child = [component render:node.state];
    if (child) {
      if (childComponent != nullptr) {
        // Set the link between the parent to its child.
        *childComponent = child;
      }
      // Call build component tree on the child component.
      [child buildComponentTree:node
                 previousParent:(id<CKTreeNodeWithChildrenProtocol>)[previousParent childForComponentKey:[node componentKey]]
                         params:params
           parentHasStateUpdate:parentHasStateUpdate];
    }

    CKRenderInternal::ScopeEvents::didBuildComponentTree(node, params);
    CKRenderInternal::didBuildComponentTreeWithChild(node, component, params);

    return node;
  }

  auto buildComponentTreeWithChildren(id<CKRenderWithChildrenComponentProtocol> component,
                                      id<CKTreeNodeWithChildrenProtocol> parent,
                                      id<CKTreeNodeWithChildrenProtocol> previousParent,
                                      const CKBuildComponentTreeParams &params,
                                      BOOL parentHasStateUpdate,
                                      BOOL isBridgeComponent) -> id<CKTreeNodeProtocol>
  {
    id<CKTreeNodeWithChildrenProtocol> node;
    // Bridge components might have a scope - hence might have tree node already.
    if (isBridgeComponent) {
      node = (id<CKTreeNodeWithChildrenProtocol>)component.scopeHandle.treeNode;
      [node linkComponent:component toParent:parent scopeRoot:params.scopeRoot];
    }
    if (node == nil) {
      node = [[CKTreeNodeWithChildren alloc]
              initWithRenderComponent:component
              parent:parent
              previousParent:previousParent
              scopeRoot:params.scopeRoot
              stateUpdates:params.stateUpdates];
    }

    if (!isBridgeComponent) {
      CKComponentContextHelper::willBuildComponentTree(component);
    }

    // Update the `parentHasStateUpdate` param for Faster state/props updates.
    if (!parentHasStateUpdate && CKRender::componentHasStateUpdate(node, previousParent, params)) {
      parentHasStateUpdate = YES;
    }

    auto const children = [component renderChildren:node.state];
    auto const previousParentForChild = (id<CKTreeNodeWithChildrenProtocol>)[previousParent childForComponentKey:[node componentKey]];
    for (auto const child : children) {
      if (child) {
        [child buildComponentTree:node
                   previousParent:previousParentForChild
                           params:params
             parentHasStateUpdate:parentHasStateUpdate];
      }
    }

    if (!isBridgeComponent) {
      CKComponentContextHelper::didBuildComponentTree(component);
    }

    return node;
  }

  auto buildComponentTreeForLeafComponent(id<CKTreeNodeComponentProtocol> component,
                                          id<CKTreeNodeWithChildrenProtocol> parent,
                                          id<CKTreeNodeWithChildrenProtocol> previousParent,
                                          const CKBuildComponentTreeParams &params) -> void {
    auto node = component.scopeHandle.treeNode;
    if (node) {
      [node linkComponent:component toParent:parent scopeRoot:params.scopeRoot];
    } else {
      node = [[CKTreeNode alloc]
              initWithComponent:component
              parent:parent
              previousParent:previousParent
              scopeRoot:params.scopeRoot
              stateUpdates:params.stateUpdates];
    }
  }

  auto componentHasStateUpdate(id<CKTreeNodeProtocol> node,
                               id<CKTreeNodeWithChildrenProtocol> previousParent,
                               const CKBuildComponentTreeParams &params) -> BOOL {
    if (previousParent && params.buildTrigger == BuildTrigger::StateUpdate) {
      auto const scopeHandle = node.handle;
      if (scopeHandle != nil) {
        auto const stateUpdateBlock = params.stateUpdates.find(scopeHandle);
        return stateUpdateBlock != params.stateUpdates.end();
      }
    }
    return NO;
  }

  auto markTreeNodeDirtyIdsFromNodeUntilRoot(CKTreeNodeIdentifier nodeIdentifier,
                                             CKRootTreeNode &previousRootNode,
                                             CKTreeNodeDirtyIds &treeNodesDirtyIds) -> void
  {
    CKTreeNodeIdentifier currentNodeIdentifier = nodeIdentifier;
    while (currentNodeIdentifier != 0) {
      auto const insertPair = treeNodesDirtyIds.insert(currentNodeIdentifier);
      // If we got to a node that is already in the set, we can stop as the path to the root is already dirty.
      if (insertPair.second == false) {
        break;
      }
      auto const parentNode = previousRootNode.parentForNodeIdentifier(currentNodeIdentifier);
      CKCAssert((parentNode || nodeIdentifier == currentNodeIdentifier),
                @"The next parent cannot be nil unless it's a root component.");
      currentNodeIdentifier = parentNode.nodeIdentifier;
    }
  }

  auto treeNodeDirtyIdsFor(CKComponentScopeRoot *previousRoot,
                           const CKComponentStateUpdateMap &stateUpdates,
                           const BuildTrigger &buildTrigger) -> CKTreeNodeDirtyIds
  {
    CKTreeNodeDirtyIds treeNodesDirtyIds;
    // Compute the dirtyNodeIds in case of a state update only.
    if (buildTrigger == BuildTrigger::StateUpdate) {
      for (auto const & stateUpdate : stateUpdates) {
        CKRender::markTreeNodeDirtyIdsFromNodeUntilRoot(stateUpdate.first.treeNodeIdentifier, previousRoot.rootNode, treeNodesDirtyIds);
      }
    }
    return treeNodesDirtyIds;
  }
}
