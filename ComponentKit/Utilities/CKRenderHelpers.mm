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
#import <ComponentKit/CKComponentScopeRoot.h>
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
                                     CKRenderTreeNodeWithChild *previousChild) -> void {
    // Set the child from the previous tree node.
    node.child = previousChild.child;
    if (childComponent != nullptr) {
      // Link the previous child component to the the new component.
      *childComponent = [(CKRenderTreeNodeWithChild *)previousChild child].component;
    }
    // Notify the new component about the reuse of the previous component.
    [component didReuseComponent:(id<CKRenderComponentProtocol>)previousChild.component];
  }

  // Reuse the previous component generation and its component tree and notify the previous component about it.
  static auto reusePreviousComponent(id<CKRenderComponentProtocol> component,
                                     __strong id<CKTreeNodeComponentProtocol> *childComponent,
                                     CKRenderTreeNodeWithChild *node,
                                     id<CKTreeNodeWithChildrenProtocol> parent,
                                     id<CKTreeNodeWithChildrenProtocol> previousParent) -> BOOL {
    auto const previousChild = (CKRenderTreeNodeWithChild *)[previousParent childForComponentKey:node.componentKey];
    if (previousChild) {
      CKRenderInternal::reusePreviousComponent(component, childComponent, node, previousChild);
      return YES;
    }
    return NO;
  }

  // Check if isEqualToComponent returns `YES`; if it does, reuse the previous component generation and its component tree and notify the previous component about it.
  static auto reusePreviousComponentIfComponentsAreEqual(id<CKRenderComponentProtocol> component,
                                                         __strong id<CKTreeNodeComponentProtocol> *childComponent,
                                                         CKRenderTreeNodeWithChild *node,
                                                         id<CKTreeNodeWithChildrenProtocol> parent,
                                                         id<CKTreeNodeWithChildrenProtocol> previousParent) -> BOOL {
    auto const previousChild = (CKRenderTreeNodeWithChild *)[previousParent childForComponentKey:node.componentKey];
    auto const previousComponent = (id<CKRenderComponentProtocol>)previousChild.component;
    if (previousComponent && ![component shouldComponentUpdate:previousComponent]) {
      CKRenderInternal::reusePreviousComponent(component, childComponent, node, previousChild);
      return YES;
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
                                         BOOL parentHasStateUpdate) -> void
  {
    CKCAssert(component, @"component cannot be nil");

    auto const node = [[CKRenderTreeNodeWithChild alloc]
                       initWithComponent:component
                       parent:parent
                       previousParent:previousParent
                       scopeRoot:params.scopeRoot
                       stateUpdates:params.stateUpdates];

    // Faster state/props optimizations require previous parent.
    if (previousParent && childComponent != nullptr) {
      if (params.buildTrigger == BuildTrigger::StateUpdate) {
        // During state update, we have two possible optimizations:
        // 1. Faster state update
        // 2. Faster props update (when the parent is dirty, we handle state update as props update).
        if (params.enableFasterStateUpdates || params.enableFasterPropsUpdates) {
          // Check if the tree node is not dirty (not in a branch of a state update).
          auto const dirtyNodeId = params.treeNodeDirtyIds.find(node.nodeIdentifier);
          if (dirtyNodeId == params.treeNodeDirtyIds.end()) {
            // If the component is not dirty and it doesn't have a parent with a state update - we can reuse it.
            if (!parentHasStateUpdate) {
              if (params.enableFasterStateUpdates) {
                // Faster state update optimizations.
                if (CKRenderInternal::reusePreviousComponent(component, childComponent, node, parent, previousParent)) {
                  return;
                }
              } // If `enableFasterStateUpdates` is disabled, we handle it as a props update as the component is not dirty.
              else if (params.enableFasterPropsUpdates &&
                       CKRenderInternal::reusePreviousComponentIfComponentsAreEqual(component, childComponent, node, parent, previousParent)) {
                return;
              }
            } // If the component is not dirty, but its parent is dirty - we handle it as props update.
            else if (params.enableFasterPropsUpdates &&
                     CKRenderInternal::reusePreviousComponentIfComponentsAreEqual(component, childComponent, node, parent, previousParent)) {
              return;
            }
          }
        }
      }
      else if (params.buildTrigger == BuildTrigger::PropsUpdate) {
        // Faster props update optimizations.
        if (params.enableFasterPropsUpdates &&
            CKRenderInternal::reusePreviousComponentIfComponentsAreEqual(component, childComponent, node, parent, previousParent)) {
          return;
        }
      }
    }

    // Update the `parentHasStateUpdate` param for Faster state/props updates.
    if (!parentHasStateUpdate && CKRender::componentHasStateUpdate(node, previousParent, params)) {
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
  }

  auto buildComponentTreeWithMultiChild(id<CKRenderWithChildrenComponentProtocol> component,
                                        id<CKTreeNodeWithChildrenProtocol> parent,
                                        id<CKTreeNodeWithChildrenProtocol> previousParent,
                                        const CKBuildComponentTreeParams &params,
                                        BOOL parentHasStateUpdate) -> void
  {
    auto const node = [[CKRenderTreeNodeWithChildren alloc]
                       initWithComponent:component
                       parent:parent
                       previousParent:previousParent
                       scopeRoot:params.scopeRoot
                       stateUpdates:params.stateUpdates];

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
    if (previousParent && params.buildTrigger == BuildTrigger::StateUpdate && (params.enableFasterStateUpdates || params.enableFasterPropsUpdates)) {
      auto const scopeHandle = node.handle;
      if (scopeHandle != nil) {
        auto const stateUpdateBlock = params.stateUpdates.find(scopeHandle);
        return stateUpdateBlock != params.stateUpdates.end();
      }
    }
    return NO;
  }

  static auto createTreeNodeDirtyIds(const CKComponentStateUpdateMap &stateUpdates) -> CKTreeNodeDirtyIds
  {
    CKTreeNodeDirtyIds treeNodesDirtyIds;
    for (auto const & stateUpdate : stateUpdates) {
      id<CKTreeNodeProtocol> treeNode = stateUpdate.first.treeNode;
      while (treeNode != nil) {
        treeNodesDirtyIds.insert(treeNode.nodeIdentifier);
        treeNode = treeNode.parent;
      }
    }
    return treeNodesDirtyIds;
  }

  auto treeNodeDirtyIdsFor(const CKComponentStateUpdateMap &stateUpdates, const BuildTrigger &buildTrigger, const CKBuildComponentConfig &config) -> CKTreeNodeDirtyIds
  {
    if (buildTrigger == BuildTrigger::StateUpdate &&
        (config.enableFasterStateUpdates || config.enableFasterPropsUpdates)) {
      return createTreeNodeDirtyIds(stateUpdates);
    }

    return CKTreeNodeDirtyIds();
  }
}
