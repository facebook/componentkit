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

#import <ComponentKit/CKAnalyticsListener.h>
#import <ComponentKit/CKRenderComponent.h>
#import <ComponentKit/CKComponentContextHelper.h>
#import <ComponentKit/CKComponentInternal.h>
#import <ComponentKit/CKComponentScopeRoot.h>
#import <ComponentKit/CKMutex.h>
#import <ComponentKit/CKOptional.h>
#import <ComponentKit/CKTreeNodeProtocol.h>

#import "CKScopeTreeNode.h"
#import "CKRenderTreeNode.h"

namespace CKRenderInternal {

  // Reuse the previous component generation and its component tree and notify the previous component about it.
  static auto reusePreviousComponent(id<CKRenderComponentProtocol> component,
                                     __strong id<CKTreeNodeComponentProtocol> *childComponent,
                                     CKRenderTreeNode *node,
                                     CKRenderTreeNode *previousNode,
                                     const CKBuildComponentTreeParams &params,
                                     CKRenderDidReuseComponentBlock didReuseBlock) -> void {

    id<CKTreeNodeComponentProtocol> prevChildComponent;

    // Update the previous component.
    prevChildComponent = [(id<CKRenderWithChildComponentProtocol>)previousNode.component child];
    // Update the render node of the component reuse.
    [node didReuseRenderNode:previousNode
                   scopeRoot:params.scopeRoot
           previousScopeRoot:params.previousScopeRoot
         mergeTreeNodesLinks:params.mergeTreeNodesLinks];

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
                                     CKRenderTreeNode *node,
                                     id<CKTreeNodeWithChildrenProtocol> parent,
                                     id<CKTreeNodeWithChildrenProtocol> previousParent,
                                     const CKBuildComponentTreeParams &params,
                                     CKRenderDidReuseComponentBlock didReuseBlock) -> BOOL {
    auto const previousNode = (CKRenderTreeNode *)[previousParent childForComponentKey:node.componentKey];
    if (previousNode) {
      CKRenderInternal::reusePreviousComponent(component, childComponent, node, previousNode, params, didReuseBlock);
      return YES;
    }
    return NO;
  }

  // Check if shouldComponentUpdate returns `NO`; if it does, reuse the previous component generation and its component tree and notify the previous component about it.
  static auto reusePreviousComponentIfComponentsAreEqual(id<CKRenderComponentProtocol> component,
                                                         __strong id<CKTreeNodeComponentProtocol> *childComponent,
                                                         CKRenderTreeNode *node,
                                                         id<CKTreeNodeWithChildrenProtocol> parent,
                                                         id<CKTreeNodeWithChildrenProtocol> previousParent,
                                                         const CKBuildComponentTreeParams &params,
                                                         CKRenderDidReuseComponentBlock didReuseBlock) -> BOOL {
    auto const previousNode = (CKRenderTreeNode *)[previousParent childForComponentKey:node.componentKey];
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

  static auto reusePreviousComponentForSingleChild(CKRenderTreeNode *node,
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
    if (!params.enableComponentReuseOptimizations) {
      return NO;
    }

    // State update branch:
    if (params.buildTrigger == CKBuildTrigger::StateUpdate) {
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
    else if (params.buildTrigger == CKBuildTrigger::PropsUpdate) {
      return CKRenderInternal::reusePreviousComponentIfComponentsAreEqual(component, childComponent, node, parent, previousParent, params, didReuseBlock);
    }

    return NO;
  }


static auto didBuildComponentTree(id<CKTreeNodeProtocol> node,
                                  id<CKTreeNodeComponentProtocol> component,
                                  const CKBuildComponentTreeParams &params) -> void {

    [CKRenderTreeNode didBuildComponentTree:node];

    // Context support
    CKComponentContextHelper::didBuildComponentTree(component);

    // Props updates and context support
    params.scopeRoot.rootNode.didBuildComponentTree(node);

    // Systrace logging
    [params.systraceListener didBuildComponent:component.class];
  }

}

namespace CKRender {
  namespace ComponentTree {
    namespace Iterable {
    auto build(id<CKTreeNodeComponentProtocol> component,
               id<CKTreeNodeWithChildrenProtocol> parent,
               id<CKTreeNodeWithChildrenProtocol> _Nullable previousParent,
               const CKBuildComponentTreeParams &params,
               BOOL parentHasStateUpdate) -> void
    {
      CKCAssertNotNil(component, @"component cannot be nil");
      CKCAssertNotNil(parent, @"parent cannot be nil");

      // Check if the component already has a tree node.
      id<CKTreeNodeProtocol> node = component.scopeHandle.treeNode;

      if (node) {
        [node linkComponent:component toParent:parent previousParent:previousParent params:params];
      }

      unsigned int numberOfChildren = [component numberOfChildren];
      if (numberOfChildren == 0) {
        return;
      }

      // Update the `parentHasStateUpdate` param for Faster state/props updates.
      if (!parentHasStateUpdate && CKRender::componentHasStateUpdate(component, previousParent, params)) {
        parentHasStateUpdate = YES;
      }

      // If there is a node, we update the parents' pointers to the next level in the tree.
      if (node) {
        parent = (id<CKTreeNodeWithChildrenProtocol>)node;
        previousParent = (id<CKTreeNodeWithChildrenProtocol>)[previousParent childForComponentKey:[node componentKey]];

        // Report information to `debugAnalyticsListener`.
        if (numberOfChildren == 1 && params.shouldCollectTreeNodeCreationInformation) {
          [params.scopeRoot.analyticsListener didBuildTreeNodeForPrecomputedChild:component
                                                                             node:node
                                                                           parent:parent
                                                                           params:params
                                                             parentHasStateUpdate:parentHasStateUpdate];
        }
      }

      for (int i=0; i<numberOfChildren; i++) {
        auto const childComponent = (id<CKTreeNodeComponentProtocol>)[component childAtIndex:i];
        if (childComponent) {
          [childComponent buildComponentTree:parent
                              previousParent:previousParent
                                      params:params
                        parentHasStateUpdate:parentHasStateUpdate];
        }
      }
    }
  }

    namespace Render {
      auto build(id<CKRenderWithChildComponentProtocol> component,
                 __strong id<CKTreeNodeComponentProtocol> *childComponent,
                 id<CKTreeNodeWithChildrenProtocol> parent,
                 id<CKTreeNodeWithChildrenProtocol> _Nullable previousParent,
                 const CKBuildComponentTreeParams &params,
                 BOOL parentHasStateUpdate,
                 CKRenderDidReuseComponentBlock didReuseBlock) -> id<CKTreeNodeProtocol>
      {
        CKCAssertNotNil(component, @"component cannot be nil");
        CKCAssertNotNil(parent, @"parent cannot be nil");

        // Context support
        CKComponentContextHelper::willBuildComponentTree(component);

        auto const node = [[CKRenderTreeNode alloc]
                           initWithComponent:component
                           parent:parent
                           previousParent:previousParent
                           scopeRoot:params.scopeRoot
                           stateUpdates:params.stateUpdates];;

        // Faster Props updates and context support
        params.scopeRoot.rootNode.willBuildComponentTree(node);

        // Systrace logging
        [params.systraceListener willBuildComponent:component.class];

        // Faster state/props optimizations require previous parent.
        if (CKRenderInternal::reusePreviousComponentForSingleChild(node, component, childComponent, parent, previousParent, params, parentHasStateUpdate, didReuseBlock)) {
          CKRenderInternal::didBuildComponentTree(node, component, params);
          return node;
        }

        // Update the `parentHasStateUpdate` param for Faster state/props updates.
        if (!parentHasStateUpdate && CKRender::nodeHasStateUpdate(node, previousParent, params)) {
          parentHasStateUpdate = YES;
        }

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

        CKRenderInternal::didBuildComponentTree(node, component, params);

        return node;
      }
    }

    namespace Root {
      auto build(id<CKTreeNodeComponentProtocol> component, const CKBuildComponentTreeParams &params) -> void {
        auto const rootNode = params.scopeRoot.rootNode.node();

        if (component) {
          // Build the component tree from the render function.
          [component buildComponentTree:rootNode
                         previousParent:params.previousScopeRoot.rootNode.node()
                                 params:params
                   parentHasStateUpdate:NO];
        }
      }
    }
  }

  namespace ScopeHandle {
    namespace Render {
      auto create(id<CKRenderComponentProtocol> component,
                  Class componentClass,
                  id<CKTreeNodeProtocol> previousNode,
                  CKComponentScopeRoot *scopeRoot,
                  const CKComponentStateUpdateMap &stateUpdates) -> CKComponentScopeHandle*
      {
        CKComponentScopeHandle *scopeHandle;
        // If there is a previous node, we just duplicate the scope handle.
        if (previousNode) {
          scopeHandle = [previousNode.scopeHandle newHandleWithStateUpdates:stateUpdates
                                                         componentScopeRoot:scopeRoot];
        } else {
          // The component needs a scope handle in few cases:
          // 1. Has an initial state
          // 2. Returns `YES` from `requiresScopeHandle`
          id initialState = [component initialState];
          if (initialState != CKTreeNodeEmptyState() || component.requiresScopeHandle) {
            scopeHandle = [[CKComponentScopeHandle alloc] initWithListener:scopeRoot.listener
                                                            rootIdentifier:scopeRoot.globalIdentifier
                                                            componentClass:componentClass
                                                              initialState:initialState];
          }
        }

        // Finalize the node/scope regsitration.
        if (scopeHandle) {
          [component acquireScopeHandle:scopeHandle];
          [scopeRoot registerComponent:component];
          [scopeHandle resolve];
        }

        return scopeHandle;
      }
    }
  }

  auto componentHasStateUpdate(__unsafe_unretained id<CKTreeNodeComponentProtocol> component,
                               __unsafe_unretained id<CKTreeNodeWithChildrenProtocol> previousParent,
                               const CKBuildComponentTreeParams &params) -> BOOL {
    if (previousParent && params.buildTrigger == CKBuildTrigger::StateUpdate) {
      auto const scopeHandle = component.scopeHandle;
      if (scopeHandle != nil) {
        auto const stateUpdateBlock = params.stateUpdates.find(scopeHandle);
        return stateUpdateBlock != params.stateUpdates.end();
      }
    }
    return NO;
  }

  auto nodeHasStateUpdate(__unsafe_unretained id<CKTreeNodeProtocol> node,
                          __unsafe_unretained id<CKTreeNodeWithChildrenProtocol> previousParent,
                          const CKBuildComponentTreeParams &params) -> BOOL {
    if (previousParent && params.buildTrigger == CKBuildTrigger::StateUpdate) {
      auto const scopeHandle = node.scopeHandle;
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
                           const CKBuildTrigger &buildTrigger) -> CKTreeNodeDirtyIds
  {
    CKTreeNodeDirtyIds treeNodesDirtyIds;
    // Compute the dirtyNodeIds in case of a state update only.
    if (buildTrigger == CKBuildTrigger::StateUpdate) {
      for (auto const & stateUpdate : stateUpdates) {
        CKRender::markTreeNodeDirtyIdsFromNodeUntilRoot(stateUpdate.first.treeNodeIdentifier, previousRoot.rootNode, treeNodesDirtyIds);
      }
    }
    return treeNodesDirtyIds;
  }
}
