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
  auto buildComponentTreeWithPrecomputedChild(id<CKTreeNodeComponentProtocol> component,
                                              id<CKTreeNodeComponentProtocol> childComponent,
                                              id<CKTreeNodeWithChildrenProtocol> parent,
                                              id<CKTreeNodeWithChildrenProtocol> previousParent,
                                              const CKBuildComponentTreeParams &params,
                                              BOOL hasDirtyParent) -> void;

  auto buildComponentTreeWithSingleChild(id<CKRenderWithChildComponentProtocol> component,
                                         __strong id<CKTreeNodeComponentProtocol> *childComponent,
                                         id<CKTreeNodeWithChildrenProtocol> parent,
                                         id<CKTreeNodeWithChildrenProtocol> previousParent,
                                         const CKBuildComponentTreeParams &params,
                                         BOOL hasDirtyParent) -> void;

  auto buildComponentTreeWithMultiChild(id<CKRenderWithChildrenComponentProtocol> component,
                                        id<CKTreeNodeWithChildrenProtocol> parent,
                                        id<CKTreeNodeWithChildrenProtocol> previousParent,
                                        const CKBuildComponentTreeParams &params,
                                        BOOL hasDirtyParent) -> void;

  auto buildComponentTreeForLeafComponent(id<CKTreeNodeComponentProtocol> component,
                                          id<CKTreeNodeWithChildrenProtocol> parent,
                                          id<CKTreeNodeWithChildrenProtocol> previousParent,
                                          const CKBuildComponentTreeParams &params) -> void;

  auto hasDirtyParent(id<CKTreeNodeProtocol> node,
                      id<CKTreeNodeWithChildrenProtocol> previousParent,
                      const CKBuildComponentTreeParams &params) -> BOOL;

  /**
   @return A collection of tree node marked as dirty if any. An empty collection otherwise.
   */
  auto treeNodeDirtyIdsFor(const CKComponentStateUpdateMap &stateUpdates, const BuildTrigger &buildTrigger, const CKBuildComponentConfig &config) -> CKTreeNodeDirtyIds;

  /**
   @return `YES` if the in input scope requires to build a component tree. `NO` otherwise.
   */
  auto shouldBuildComponentTreeFrom(CKThreadLocalComponentScope threadScope) -> BOOL;
}
