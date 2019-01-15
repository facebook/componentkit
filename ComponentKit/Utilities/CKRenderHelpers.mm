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
#import <ComponentKit/CKThreadLocalComponentScope.h>
#import <ComponentKit/CKTreeNodeProtocol.h>
#import <ComponentKit/CKTreeNodeWithChild.h>
#import <ComponentKit/CKRenderTreeNodeWithChild.h>
#import <ComponentKit/CKRenderTreeNodeWithChildren.h>

namespace CKRenderInternal {
  // Reuse the previous component generation and its component tree and notify the previous component about it.
  static auto reusePreviousComponent(id<CKRenderComponentProtocol> component,
                                     __strong id<CKTreeNodeComponentProtocol> *childComponent,
                                     CKRenderTreeNodeWithChild *node,
                                     CKRenderTreeNodeWithChild *previousNode,
                                     const CKBuildComponentTreeParams &params) -> void {
    auto const reusedChild = previousNode.child;
    // Set the child from the previous tree node.
    node.child = reusedChild;
    // Save the reused node in the scope root for the next component creation.
    [reusedChild didReuseInScopeRoot:params.scopeRoot fromPreviousScopeRoot:params.previousScopeRoot];
    // Update the new parent in the new scope root
    [params.scopeRoot registerNode:reusedChild withParent:node];

    // Update the scope frame of the reuse of this component in order to transfer the render scope frame.
    [CKComponentScopeFrame didReuseRenderWithTreeNode:node];

    auto const prevChildComponent = [(CKRenderTreeNodeWithChild *)previousNode child].component;

    if (childComponent != nullptr) {
      // Link the previous child component to the the new component.
      *childComponent = prevChildComponent;
    }
    // Notify the new component about the reuse of the previous component.
    [component didReuseComponent:(id<CKRenderComponentProtocol>)previousNode.component];

    // Notify scope root listener
    if ([params.scopeRoot.analyticsListener respondsToSelector:@selector(didReuseNode:inScopeRoot:fromPreviousScopeRoot:)]) {
      [params.scopeRoot.analyticsListener didReuseNode:reusedChild inScopeRoot:params.scopeRoot fromPreviousScopeRoot:params.previousScopeRoot];
    }
  }

  // Reuse the previous component generation and its component tree and notify the previous component about it.
  static auto reusePreviousComponent(id<CKRenderComponentProtocol> component,
                                     __strong id<CKTreeNodeComponentProtocol> *childComponent,
                                     CKRenderTreeNodeWithChild *node,
                                     id<CKTreeNodeWithChildrenProtocol> parent,
                                     id<CKTreeNodeWithChildrenProtocol> previousParent,
                                     const CKBuildComponentTreeParams &params) -> BOOL {
    auto const previousNode = (CKRenderTreeNodeWithChild *)[previousParent childForComponentKey:node.componentKey];
    if (previousNode) {
      CKRenderInternal::reusePreviousComponent(component, childComponent, node, previousNode, params);
      return YES;
    }
    return NO;
  }

  // Check if shouldComponentUpdate returns `NO`; if it does, reuse the previous component generation and its component tree and notify the previous component about it.
  static auto reusePreviousComponentIfComponentsAreEqual(id<CKRenderComponentProtocol> component,
                                                         __strong id<CKTreeNodeComponentProtocol> *childComponent,
                                                         CKRenderTreeNodeWithChild *node,
                                                         id<CKTreeNodeWithChildrenProtocol> parent,
                                                         id<CKTreeNodeWithChildrenProtocol> previousParent,
                                                         const CKBuildComponentTreeParams &params) -> BOOL {
    auto const previousNode = (CKRenderTreeNodeWithChild *)[previousParent childForComponentKey:node.componentKey];
    auto const previousComponent = (id<CKRenderComponentProtocol>)previousNode.component;
    if (previousComponent && ![component shouldComponentUpdate:previousComponent]) {
      CKRenderInternal::reusePreviousComponent(component, childComponent, node, previousNode, params);
      return YES;
    }
    return NO;
  }

  static auto reusePreviousComponentForSingleChild(CKRenderTreeNodeWithChild *node,
                                                   id<CKRenderWithChildComponentProtocol> component,
                                                   __strong id<CKTreeNodeComponentProtocol> *childComponent,
                                                   id<CKTreeNodeWithChildrenProtocol> parent,
                                                   id<CKTreeNodeWithChildrenProtocol> previousParent,
                                                   const CKBuildComponentTreeParams &params,
                                                   BOOL parentHasStateUpdate) -> BOOL {

    // If there is no previous parent or no childComponent, we bail early.
    if (previousParent == nil || childComponent == nullptr) {
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
          return CKRenderInternal::reusePreviousComponent(component, childComponent, node, parent, previousParent, params);
        }
        // We fallback to the props update optimization in the follwing case:
        // - The component is not dirty, but the parent has a state update.
        return (params.enableFasterPropsUpdates && CKRenderInternal::reusePreviousComponentIfComponentsAreEqual(component, childComponent, node, parent, previousParent, params));
      }
    }
    // Props update branch:
    else if (params.buildTrigger == BuildTrigger::PropsUpdate && params.enableFasterPropsUpdates) {
      return CKRenderInternal::reusePreviousComponentIfComponentsAreEqual(component, childComponent, node, parent, previousParent, params);
    }

    return NO;
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

    auto const node = [[CKTreeNodeWithChild alloc]
                       initWithComponent:component
                       parent:parent
                       previousParent:previousParent
                       scopeRoot:params.scopeRoot
                       stateUpdates:params.stateUpdates];

    // Update the `parentHasStateUpdate` param for Faster state/props updates.
    if (!parentHasStateUpdate && CKRender::componentHasStateUpdate(node, previousParent, params)) {
      parentHasStateUpdate = YES;
    }

    if (childComponent) {
      [childComponent buildComponentTree:node
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

    auto const node = [[CKTreeNodeWithChildren alloc]
                       initWithComponent:component
                       parent:parent
                       previousParent:previousParent
                       scopeRoot:params.scopeRoot
                       stateUpdates:params.stateUpdates];

    // Update the `parentHasStateUpdate` param for Faster state/props updates.
    if (!parentHasStateUpdate && CKRender::componentHasStateUpdate(node, previousParent, params)) {
      parentHasStateUpdate = YES;
    }

    for (auto const childComponent : childrenComponents) {
      if (childComponent) {
        [childComponent buildComponentTree:node
                            previousParent:(id<CKTreeNodeWithChildrenProtocol>)[previousParent childForComponentKey:[node componentKey]]
                                    params:params
                      parentHasStateUpdate:parentHasStateUpdate];
      }
    }
  }

  auto buildComponentTreeWithSingleChild(id<CKRenderWithChildComponentProtocol> component,
                                         __strong id<CKTreeNodeComponentProtocol> *childComponent,
                                         id<CKTreeNodeWithChildrenProtocol> parent,
                                         id<CKTreeNodeWithChildrenProtocol> previousParent,
                                         const CKBuildComponentTreeParams &params,
                                         BOOL parentHasStateUpdate,
                                         BOOL isBridgeComponent,
                                         BOOL *didReuseComponent) -> void
  {
    CKCAssert(component, @"component cannot be nil");

    auto const node = [[CKRenderTreeNodeWithChild alloc]
                       initWithComponent:component
                       parent:parent
                       previousParent:previousParent
                       scopeRoot:params.scopeRoot
                       stateUpdates:params.stateUpdates];

    if (!isBridgeComponent) {
      CKComponentContextHelper::willBuildComponentTree(component);

      // Systrace logging
      if (params.isSystraceEnabled) {
        [params.scopeRoot.analyticsListener willBuildComponent:component.class];
      }
    }

    // Faster state/props optimizations require previous parent.
    if (!isBridgeComponent && CKRenderInternal::reusePreviousComponentForSingleChild(node, component, childComponent, parent, previousParent, params, parentHasStateUpdate)) {
      CKComponentContextHelper::didBuildComponentTree(component);

      if (didReuseComponent != nullptr) {
        *didReuseComponent = YES;
      }

      // Systrace logging
      if (params.isSystraceEnabled) {
        [params.scopeRoot.analyticsListener didBuildComponent:component.class];
      }
      return;
    }

    // Update the `parentHasStateUpdate` param for Faster state/props updates.
    if (!parentHasStateUpdate && CKRender::componentHasStateUpdate(node, previousParent, params)) {
      parentHasStateUpdate = YES;
    }

    if (!isBridgeComponent) {
      [CKComponentScopeFrame willBuildComponentTreeWithTreeNode:node];
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

    if (!isBridgeComponent) {
      [CKComponentScopeFrame didBuildComponentTreeWithNode:node];
      CKComponentContextHelper::didBuildComponentTree(component);

      // Systrace logging
      if (params.isSystraceEnabled) {
        [params.scopeRoot.analyticsListener didBuildComponent:component.class];
      }
    }
  }

  auto buildComponentTreeWithMultiChild(id<CKRenderWithChildrenComponentProtocol> component,
                                        id<CKTreeNodeWithChildrenProtocol> parent,
                                        id<CKTreeNodeWithChildrenProtocol> previousParent,
                                        const CKBuildComponentTreeParams &params,
                                        BOOL parentHasStateUpdate,
                                        BOOL isBridgeComponent) -> void
  {
    auto const node = [[CKRenderTreeNodeWithChildren alloc]
                       initWithComponent:component
                       parent:parent
                       previousParent:previousParent
                       scopeRoot:params.scopeRoot
                       stateUpdates:params.stateUpdates];

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
  }

  auto buildComponentTreeForLeafComponent(id<CKTreeNodeComponentProtocol> component,
                                          id<CKTreeNodeWithChildrenProtocol> parent,
                                          id<CKTreeNodeWithChildrenProtocol> previousParent,
                                          const CKBuildComponentTreeParams &params) -> void {
    __unused auto const node = [[CKTreeNode alloc]
                                initWithComponent:component
                                parent:parent
                                previousParent:previousParent
                                scopeRoot:params.scopeRoot
                                stateUpdates:params.stateUpdates];
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
                                             CKComponentScopeRoot *previousRoot,
                                             CKTreeNodeDirtyIds &treeNodesDirtyIds) -> void
  {
    CKTreeNodeIdentifier currentNodeIdentifier = nodeIdentifier;
    while (currentNodeIdentifier != 0) {
      auto const insertPair = treeNodesDirtyIds.insert(currentNodeIdentifier);
      // If we got to a node that is already in the set, we can stop as the path to the root is already dirty.
      if (insertPair.second == false) {
        break;
      }
      auto const parentNode = [previousRoot parentForNodeIdentifier:currentNodeIdentifier];
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
        CKRender::markTreeNodeDirtyIdsFromNodeUntilRoot(stateUpdate.first.treeNodeIdentifier, previousRoot, treeNodesDirtyIds);
      }
    }
    return treeNodesDirtyIds;
  }
}
