/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <Foundation/Foundation.h>

#import <ComponentKit/CKBuildComponent.h>
#import <ComponentKit/CKComponentInternal.h>

@protocol CKRenderWithChildComponentProtocol;
@protocol CKRenderWithChildrenComponentProtocol;

@class CKRenderComponent;
@class CKRenderTreeNodeWithChild;

namespace CKRender {
  /**
   Builds a component tree for a component having a child component that has been already initialized.
   This should be called when a component, on initialization, receives its child component from the outside and it's not meant to be converted to a render component.

   @param component The component at the head of the component tree.
   @param childComponent The pre-computed child component owned by the component in input.
   @param parent The current parent tree node of the component in input.
   @param previousParent The previous generation of the parent tree node of the component in input.
   @param params Collection of parameters to use to properly setup build component tree step.
   @param parentHasStateUpdate Flag used to run optimizations at component tree build time. `YES` if the input parent received a state update.
   */
  auto buildComponentTreeWithPrecomputedChild(id<CKTreeNodeComponentProtocol> component,
                                              id<CKTreeNodeComponentProtocol> childComponent,
                                              id<CKTreeNodeWithChildrenProtocol> parent,
                                              id<CKTreeNodeWithChildrenProtocol> previousParent,
                                              const CKBuildComponentTreeParams &params,
                                              BOOL parentHasStateUpdate) -> void;


  /**
   Builds a component tree for a component having children components that have been already initialized.
   This should be called when a component receives its children components as a prop and it's not meant to be converted to a render component.

   @param component The component at the head of the component tree.
   @param childrenComponent The pre-computed children components owned by the component in input.
   @param parent The current parent tree node of the component in input.
   @param previousParent The previous generation of the parent tree node of the component in input.
   @param params Collection of parameters to use to properly setup build component tree step.
   @param parentHasStateUpdate Flag used to run optimizations at component tree build time. `YES` if the input parent received a state update.
   */
  auto buildComponentTreeWithPrecomputedChildren(id<CKTreeNodeComponentProtocol> component,
                                                 std::vector<id<CKTreeNodeComponentProtocol>> childrenComponents,
                                                 id<CKTreeNodeWithChildrenProtocol> parent,
                                                 id<CKTreeNodeWithChildrenProtocol> previousParent,
                                                 const CKBuildComponentTreeParams &params,
                                                 BOOL parentHasStateUpdate) -> void;
  /**
   Builds a component tree for the input *render* component having a child component.

   @param component The *render* component at the head of the component tree.
   @param childComponent The child component owned by the component in input.
   @param parent The current parent tree node of the component in input.
   @param previousParent The previous generation of the parent tree node of the component in input.
   @param params Collection of parameters to use to properly setup build component tree step.
   @param parentHasStateUpdate Flag used to run optimizations at component tree build time. `YES` if the input parent received a state update.
   @param isBridgeComponent Flag used to mark components that are not "real" render components;
          when they are being created they don't mark the `hasRenderComponentInTree` flag in the thread local store as well.
          Default value is `NO`.
   @param didReuseComponent Out parameter used if the component got reused as optimization outcome when building the component tree.
   */
  auto buildComponentTreeWithSingleChild(id<CKRenderWithChildComponentProtocol> component,
                                         __strong id<CKTreeNodeComponentProtocol> *childComponent,
                                         id<CKTreeNodeWithChildrenProtocol> parent,
                                         id<CKTreeNodeWithChildrenProtocol> previousParent,
                                         const CKBuildComponentTreeParams &params,
                                         BOOL parentHasStateUpdate,
                                         BOOL isBridgeComponent = NO,
                                         BOOL *didReuseComponent = nullptr) -> void;

  /**
   Builds a component tree for the input *render* component having children components.

   @param component The *render* component at the head of the component tree.
   @param parent The current parent of the component in input.
   @param previousParent The previous generation of the parent tree node of the component in input.
   @param params Collection of parameters to use to properly setup build component tree step.
   @param parentHasStateUpdate Flag used to run optimizations at component tree build time. `YES` if the input parent received a state update.
   @param isBridgeComponent Flag used to mark components that are not "real" render components;
          when they are being created they don't mark the `hasRenderComponentInTree` flag in the thread local store as well.
          Default value is `NO`.
   */
  auto buildComponentTreeWithMultiChild(id<CKRenderWithChildrenComponentProtocol> component,
                                        id<CKTreeNodeWithChildrenProtocol> parent,
                                        id<CKTreeNodeWithChildrenProtocol> previousParent,
                                        const CKBuildComponentTreeParams &params,
                                        BOOL parentHasStateUpdate,
                                        BOOL isBridgeComponent = NO) -> void;

  /**
   Builds a leaf node for a leaf component in the tree.
   This should be called when the component in input is a leaf component in the tree.

   @param component The leaf component at the end of the component tree.
   @param parent The current parent of the component in input.
   @param previousParent The previous generation of the parent tree node of the component in input.
   @param params Collection of parameters to use to properly setup build component tree step.
   */
  auto buildComponentTreeForLeafComponent(id<CKTreeNodeComponentProtocol> component,
                                          id<CKTreeNodeWithChildrenProtocol> parent,
                                          id<CKTreeNodeWithChildrenProtocol> previousParent,
                                          const CKBuildComponentTreeParams &params) -> void;


  /**
   @return `YES` if the input node is part of a state update path. `NO` otherwise.
   */
  auto componentHasStateUpdate(id<CKTreeNodeProtocol> node,
                               id<CKTreeNodeWithChildrenProtocol> previousParent,
                               const CKBuildComponentTreeParams &params) -> BOOL;

  /**
   @return A collection of tree node marked as dirty if any. An empty collection otherwise.
   */
  auto treeNodeDirtyIdsFor(CKComponentScopeRoot *previousRoot, const CKComponentStateUpdateMap &stateUpdates, const BuildTrigger &buildTrigger, const CKBuildComponentConfig &config) -> CKTreeNodeDirtyIds;
}
