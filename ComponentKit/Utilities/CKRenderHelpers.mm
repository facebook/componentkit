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

#import <ComponentKit/CKBuildComponent.h>
#import <ComponentKit/CKRenderComponent.h>
#import <ComponentKit/CKTreeNodeProtocol.h>
#import <ComponentKit/CKTreeNodeWithChild.h>
#import <ComponentKit/CKRenderTreeNodeWithChild.h>
#import <ComponentKit/CKRenderTreeNodeWithChildren.h>

namespace CKRenderInternal {
  // Reuse the previous component generation and its component tree and notify the previous component about it.
  static auto reusePreviousComponent(id<CKRenderComponentProtocol> component,
                                     __strong CKComponent **childComponent,
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
                                     __strong CKComponent **childComponent,
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
                                                         __strong CKComponent **childComponent,
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
  auto buildComponentTreeWithPrecomputedChild(CKComponent *component,
                                              CKComponent *childComponent,
                                              id<CKTreeNodeWithChildrenProtocol> parent,
                                              id<CKTreeNodeWithChildrenProtocol> previousParent,
                                              const CKBuildComponentTreeParams &params,
                                              const CKBuildComponentConfig &config,
                                              BOOL hasDirtyParent) -> void
  {
    CKCAssert(component, @"component cannot be nil");

    auto const node = [[CKTreeNodeWithChild alloc]
                       initWithComponent:component
                       parent:parent
                       previousParent:previousParent
                       scopeRoot:params.scopeRoot
                       stateUpdates:params.stateUpdates];

    // Update the `hasDirtyParent` param for Faster state/props updates.
    if (!hasDirtyParent && CKRender::hasDirtyParent(node, previousParent, params, config)) {
      hasDirtyParent = YES;
    }

    if (childComponent) {
      [childComponent buildComponentTree:node
                          previousParent:(id<CKTreeNodeWithChildrenProtocol>)[previousParent childForComponentKey:[node componentKey]]
                                  params:params
                                  config:config
                          hasDirtyParent:hasDirtyParent];
    }
  }

  auto buildComponentTreeWithSingleChild(id<CKRenderWithChildComponentProtocol> component,
                                         __strong CKComponent **childComponent,
                                         id<CKTreeNodeWithChildrenProtocol> parent,
                                         id<CKTreeNodeWithChildrenProtocol> previousParent,
                                         const CKBuildComponentTreeParams &params,
                                         const CKBuildComponentConfig &config,
                                         BOOL hasDirtyParent) -> void
  {
    CKCAssert(component, @"component cannot be nil");

    auto const node = [[CKRenderTreeNodeWithChild alloc]
                       initWithComponent:component
                       parent:parent
                       previousParent:previousParent
                       scopeRoot:params.scopeRoot
                       stateUpdates:params.stateUpdates];

    // Faster state/props optimizations require previous parent.
    if (previousParent) {
      if (params.buildTrigger == BuildTrigger::StateUpdate) {
        // During state update, we have two possible optimizations:
        // 1. Faster state update
        // 2. Faster props update (when the parent is dirty, we handle state update as props update).
        if (config.enableFasterStateUpdates || config.enableFasterPropsUpdates) {
          // Check if the tree node is not dirty (not in a branch of a state update).
          auto const dirtyNodeId = params.treeNodeDirtyIds.find(node.nodeIdentifier);
          if (dirtyNodeId == params.treeNodeDirtyIds.end()) {
            // If the component is not dirty and it doesn't have a dirty parent - we can reuse it.
            if (!hasDirtyParent) {
              if (config.enableFasterStateUpdates) {
                // Faster state update optimizations.
                if (CKRenderInternal::reusePreviousComponent(component, childComponent, node, parent, previousParent)) {
                  return;
                }
              } // If `enableFasterStateUpdates` is disabled, we handle it as a props update as the component is not dirty.
              else if (config.enableFasterPropsUpdates &&
                       CKRenderInternal::reusePreviousComponentIfComponentsAreEqual(component, childComponent, node, parent, previousParent)) {
                return;
              }
            } // If the component is not dirty, but its parent is dirty - we handle it as props update.
            else if (config.enableFasterPropsUpdates &&
                     CKRenderInternal::reusePreviousComponentIfComponentsAreEqual(component, childComponent, node, parent, previousParent)) {
              return;
            }
          }
          else { // If the component is dirty, we mark it with `hasDirtyParent` param for its children.
            hasDirtyParent = YES;
          }
        }
      }
      else if (params.buildTrigger == BuildTrigger::PropsUpdate) {
        // Faster props update optimizations.
        if (config.enableFasterPropsUpdates &&
            CKRenderInternal::reusePreviousComponentIfComponentsAreEqual(component, childComponent, node, parent, previousParent)) {
          return;
        }
      }
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
                         config:config
                 hasDirtyParent:hasDirtyParent];
    }
  }

  auto buildComponentTreeWithMultiChild(id<CKRenderWithChildrenComponentProtocol> component,
                                        id<CKTreeNodeWithChildrenProtocol> parent,
                                        id<CKTreeNodeWithChildrenProtocol> previousParent,
                                        const CKBuildComponentTreeParams &params,
                                        const CKBuildComponentConfig &config,
                                        BOOL hasDirtyParent) -> void
  {
    auto const node = [[CKRenderTreeNodeWithChildren alloc]
                       initWithComponent:component
                       parent:parent
                       previousParent:previousParent
                       scopeRoot:params.scopeRoot
                       stateUpdates:params.stateUpdates];

    // Update the `hasDirtyParent` param for Faster state/props updates.
    if (!hasDirtyParent && CKRender::hasDirtyParent(node, previousParent, params, config)) {
      hasDirtyParent = YES;
    }

    auto const children = [component renderChildren:node.state];
    auto const previousParentForChild = (id<CKTreeNodeWithChildrenProtocol>)[previousParent childForComponentKey:[node componentKey]];
    for (auto const child : children) {
      if (child) {
        [child buildComponentTree:node
                   previousParent:previousParentForChild
                           params:params
                           config:config
                   hasDirtyParent:hasDirtyParent];
      }
    }
  }

  auto hasDirtyParent(id<CKTreeNodeProtocol> node,
                      id<CKTreeNodeWithChildrenProtocol> previousParent,
                      const CKBuildComponentTreeParams &params,
                      const CKBuildComponentConfig &config) -> BOOL {
    if (previousParent && params.buildTrigger == BuildTrigger::StateUpdate && (config.enableFasterStateUpdates || config.enableFasterPropsUpdates)) {
      auto const dirtyNodeId = params.treeNodeDirtyIds.find(node.nodeIdentifier);
      return dirtyNodeId != params.treeNodeDirtyIds.end();
    }
    return NO;
  }
}
