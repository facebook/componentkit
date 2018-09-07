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

#import <ComponentKit/CKComponentInternal.h>

@protocol CKRenderWithChildComponentProtocol;
@protocol CKRenderWithChildrenComponentProtocol;
@protocol CKTreeNodeProtocol;
@protocol CKTreeNodeWithChildrenProtocol;

@class CKRenderComponent;
@class CKRenderTreeNodeWithChild;

namespace CKRender {
  auto buildComponentTreeWithPrecomputedChild(CKComponent *component,
                                              CKComponent *childComponent,
                                              id<CKTreeNodeWithChildrenProtocol> parent,
                                              id<CKTreeNodeWithChildrenProtocol> previousParent,
                                              const CKBuildComponentTreeParams &params,
                                              const CKBuildComponentConfig &config,
                                              BOOL hasDirtyParent) -> void;

  auto buildComponentTreeWithSingleChild(id<CKRenderWithChildComponentProtocol> component,
                                         __strong CKComponent **childComponent,
                                         id<CKTreeNodeWithChildrenProtocol> parent,
                                         id<CKTreeNodeWithChildrenProtocol> previousParent,
                                         const CKBuildComponentTreeParams &params,
                                         const CKBuildComponentConfig &config,
                                         BOOL hasDirtyParent) -> void;

  auto buildComponentTreeWithMultiChild(id<CKRenderWithChildrenComponentProtocol> component,
                                        id<CKTreeNodeWithChildrenProtocol> parent,
                                        id<CKTreeNodeWithChildrenProtocol> previousParent,
                                        const CKBuildComponentTreeParams &params,
                                        const CKBuildComponentConfig &config,
                                        BOOL hasDirtyParent) -> void;
  
  auto hasDirtyParent(id<CKTreeNodeProtocol> node,
                      id<CKTreeNodeWithChildrenProtocol> previousParent,
                      const CKBuildComponentTreeParams &params,
                      const CKBuildComponentConfig &config) -> BOOL;
}
