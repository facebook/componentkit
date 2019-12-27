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
#import <ComponentKit/CKRootTreeNode.h>

@protocol CKRenderWithChildComponentProtocol;
@protocol CKRenderWithChildrenComponentProtocol;

@class CKRenderComponent;
@class CKTreeNodeWithChild;

using CKRenderDidReuseComponentBlock = void(^)(id<CKRenderComponentProtocol>);

namespace CKRender {
  namespace ComponentTree {

    namespace Iterable {
    /**
     Build component tree for a `CKTreeNodeComponentProtocol` component.
     This should be called when a component, on initialization, receives its child component from the outside and it's not meant to be converted to a render component.

     @param component The component at the head of the component tree.
     @param parent The current parent tree node of the component in input.
     @param previousParent The previous generation of the parent tree node of the component in input.
     @param params Collection of parameters to use to properly setup build component tree step.
     @param parentHasStateUpdate Flag used to run optimizations at component tree build time. `YES` if the input parent received a state update.
     */
      auto build(id<CKTreeNodeComponentProtocol> component,
                 id<CKTreeNodeWithChildrenProtocol> parent,
                 id<CKTreeNodeWithChildrenProtocol> previousParent,
                 const CKBuildComponentTreeParams &params,
                 BOOL parentHasStateUpdate) -> void;
  }

    namespace NonRender {
      /**
       Build component tree for a non-render component.
       This should be called when a component, on initialization, receives its child component from the outside and it's not meant to be converted to a render component.

       @param component The component at the head of the component tree.
       @param childComponent The pre-computed child component owned by the component in input.
       @param parent The current parent tree node of the component in input.
       @param previousParent The previous generation of the parent tree node of the component in input.
       @param params Collection of parameters to use to properly setup build component tree step.
       @param parentHasStateUpdate Flag used to run optimizations at component tree build time. `YES` if the input parent received a state update.
       */
      auto build(id<CKTreeNodeComponentProtocol> component,
                 id<CKTreeNodeComponentProtocol> childComponent,
                 id<CKTreeNodeWithChildrenProtocol> parent,
                 id<CKTreeNodeWithChildrenProtocol> previousParent,
                 const CKBuildComponentTreeParams &params,
                 BOOL parentHasStateUpdate) -> void;


      /**
       Build component tree for non-render components with children.
       This should be called when a component receives its children components as a prop and it's not meant to be converted to a render component.

       @param component The component at the head of the component tree.
       @param childrenComponent The pre-computed children components owned by the component in input.
       @param parent The current parent tree node of the component in input.
       @param previousParent The previous generation of the parent tree node of the component in input.
       @param params Collection of parameters to use to properly setup build component tree step.
       @param parentHasStateUpdate Flag used to run optimizations at component tree build time. `YES` if the input parent received a state update.
       */
      auto buildWithChildren(id<CKTreeNodeComponentProtocol> component,
                             std::vector<id<CKTreeNodeComponentProtocol>> childrenComponents,
                             id<CKTreeNodeWithChildrenProtocol> parent,
                             id<CKTreeNodeWithChildrenProtocol> previousParent,
                             const CKBuildComponentTreeParams &params,
                             BOOL parentHasStateUpdate) -> void;
    }

    namespace RenderLayout {
      /**
       Build component tree for render layout components (CKRenderLayoutComponent).

       @param component The component at the head of the component tree.
       @param childComponent The child component owned by the component in input.
       @param parent The current parent tree node of the component in input.
       @param previousParent The previous generation of the parent tree node of the component in input.
       @param params Collection of parameters to use to properly setup build component tree step.
       @param parentHasStateUpdate Flag used to run optimizations at component tree build time. `YES` if the input parent received a state update.
       */
      auto build(id<CKRenderWithChildComponentProtocol> component,
                 __strong id<CKTreeNodeComponentProtocol> *childComponent,
                 id<CKTreeNodeWithChildrenProtocol> parent,
                 id<CKTreeNodeWithChildrenProtocol> previousParent,
                 const CKBuildComponentTreeParams &params,
                 BOOL parentHasStateUpdate) -> void;

      /**
       Build component tree for layout render component with children components (CKRenderLayoutWithChildrenComponent).

       @param component The *render* component at the head of the component tree.
       @param parent The current parent of the component in input.
       @param previousParent The previous generation of the parent tree node of the component in input.
       @param params Collection of parameters to use to properly setup build component tree step.
       @param parentHasStateUpdate Flag used to run optimizations at component tree build time. `YES` if the input parent received a state update.

       */
      auto buildWithChildren(id<CKRenderWithChildrenComponentProtocol> component,
                             std::vector<id<CKTreeNodeComponentProtocol>> *childrenComponents,
                             id<CKTreeNodeWithChildrenProtocol> parent,
                             id<CKTreeNodeWithChildrenProtocol> previousParent,
                             const CKBuildComponentTreeParams &params,
                             BOOL parentHasStateUpdate) -> void;
    }

    namespace Render {
      /**
       Build component tree for *render* component.

       @param component The *render* component at the head of the component tree.
       @param childComponent The child component owned by the component in input.
       @param parent The current parent tree node of the component in input.
       @param previousParent The previous generation of the parent tree node of the component in input.
       @param params Collection of parameters to use to properly setup build component tree step.
       @param parentHasStateUpdate Flag used to run optimizations at component tree build time. `YES` if the input parent received a state update.
       @param didReuseBlock Will be called in case that the component from the previous generation has been reused.
       */
      auto build(id<CKRenderWithChildComponentProtocol> component,
                 __strong id<CKTreeNodeComponentProtocol> *childComponent,
                 id<CKTreeNodeWithChildrenProtocol> parent,
                 id<CKTreeNodeWithChildrenProtocol> previousParent,
                 const CKBuildComponentTreeParams &params,
                 BOOL parentHasStateUpdate,
                 CKRenderDidReuseComponentBlock didReuseBlock = nil) -> id<CKTreeNodeProtocol>;
    }

    namespace Leaf {
      /**
       Builds a leaf node for a leaf component in the tree.
       This should be called when the component in input is a leaf component in the tree.

       @param component The leaf component at the end of the component tree.
       @param parent The current parent of the component in input.
       @param previousParent The previous generation of the parent tree node of the component in input.
       @param params Collection of parameters to use to properly setup build component tree step.
       */
      auto build(id<CKTreeNodeComponentProtocol> component,
                 id<CKTreeNodeWithChildrenProtocol> parent,
                 id<CKTreeNodeWithChildrenProtocol> previousParent,
                 const CKBuildComponentTreeParams &params) -> void;
    }

    /**
     Builds the component tree from a root component.

     @param component The root component of the tree.
     @param params Collection of parameters to use to properly setup build component tree step.
     */
    namespace Root {
      auto build(id<CKTreeNodeComponentProtocol> component, const CKBuildComponentTreeParams &params) -> void;
    }
  }

  namespace ScopeHandle {
    namespace Render {
      /**
       Create a scope handle for Render component (if needed).

       @param component Render component which the scope handle will be created for.
       @param componentClass The component class .
       @param previousNode The prevoious equivalent tree node.
       @param stateUpdates The state updates map of this component generation.
       */
      auto create(id<CKRenderComponentProtocol> component,
                  Class componentClass,
                  id<CKTreeNodeProtocol> previousNode,
                  CKComponentScopeRoot *scopeRoot,
                  const CKComponentStateUpdateMap &stateUpdates) -> CKComponentScopeHandle*;
    }
  }

  /**
   @return `YES` if the component of the node has a state update, `NO` otherwise.
   */
  auto componentHasStateUpdate(__unsafe_unretained id<CKTreeNodeComponentProtocol> component,
                               __unsafe_unretained id<CKTreeNodeWithChildrenProtocol> previousParent,
                               const CKBuildComponentTreeParams &params) -> BOOL;

  /**
   @return `YES` if the component of the node has a state update, `NO` otherwise.
   */
  auto nodeHasStateUpdate(__unsafe_unretained id<CKTreeNodeProtocol> node,
                          __unsafe_unretained id<CKTreeNodeWithChildrenProtocol> previousParent,
                          const CKBuildComponentTreeParams &params) -> BOOL;

  /**
   Mark all the dirty nodes, on a path from an existing node up to the root node in the passed CKTreeNodeDirtyIds set.
   */
  auto markTreeNodeDirtyIdsFromNodeUntilRoot(CKTreeNodeIdentifier nodeIdentifier,
                                             CKRootTreeNode &previousRootNode,
                                             CKTreeNodeDirtyIds &treeNodesDirtyIds) -> void;
  
  /**
   @return A collection of tree node marked as dirty if any. An empty collection otherwise.
   */
  auto treeNodeDirtyIdsFor(CKComponentScopeRoot *previousRoot,
                           const CKComponentStateUpdateMap &stateUpdates,
                           const CKBuildTrigger &buildTrigger) -> CKTreeNodeDirtyIds;
}
