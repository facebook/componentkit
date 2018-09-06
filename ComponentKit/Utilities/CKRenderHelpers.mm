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
#import <ComponentKit/CKTreeNodeProtocol.h>
#import <ComponentKit/CKTreeNodeWithChild.h>

namespace CKRender {
  auto buildComponentTreeWithPrecomputedChild(CKComponent *component,
                                              CKComponent *childComponent,
                                              id<CKTreeNodeWithChildrenProtocol> parent,
                                              id<CKTreeNodeWithChildrenProtocol> previousParent,
                                              const CKBuildComponentTreeParams &params,
                                              const CKBuildComponentConfig &config,
                                              BOOL hasDirtyParent) -> void {

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
