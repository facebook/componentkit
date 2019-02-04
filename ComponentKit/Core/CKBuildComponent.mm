/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKBuildComponent.h"

#import "CKAnalyticsListener.h"
#import "CKComponentBoundsAnimation.h"
#import "CKComponentContextHelper.h"
#import "CKComponentEvents.h"
#import "CKComponentInternal.h"
#import "CKComponentScopeRoot.h"
#import "CKComponentSubclass.h"
#import "CKRenderHelpers.h"
#import "CKRenderTreeNodeWithChildren.h"
#import "CKTreeNodeProtocol.h"
#import "CKThreadLocalComponentScope.h"

namespace CKBuildComponentHelpers {
  auto getBuildTrigger(CKComponentScopeRoot *scopeRoot, const CKComponentStateUpdateMap &stateUpdates) -> BuildTrigger
  {
    if (scopeRoot.rootFrame.childrenSize > 0 || !scopeRoot.rootNode.isEmpty()) {
      return (stateUpdates.size() > 0) ? BuildTrigger::StateUpdate : BuildTrigger::PropsUpdate;
    }
    return BuildTrigger::NewTree;
  }
}

CKBuildComponentResult CKBuildComponent(CKComponentScopeRoot *previousRoot,
                                        const CKComponentStateUpdateMap &stateUpdates,
                                        CKComponent *(^componentFactory)(void),
                                        CKBuildComponentConfig config)
{
  CKCAssertNotNil(componentFactory, @"Must have component factory to build a component");
  auto const buildTrigger = CKBuildComponentHelpers::getBuildTrigger(previousRoot, stateUpdates);
  CKThreadLocalComponentScope threadScope(previousRoot, stateUpdates, buildTrigger, config.enableFasterPropsUpdates);

  auto const analyticsListener = [previousRoot analyticsListener];
  [analyticsListener willBuildComponentTreeWithScopeRoot:previousRoot
                                            buildTrigger:buildTrigger
                                            stateUpdates:stateUpdates];
  auto const component = componentFactory();

  // Build the component tree if we have a render component in the hierarchy.
  if (threadScope.newScopeRoot.hasRenderComponentInTree) {
    CKTreeNodeDirtyIds treeNodeDirtyIds = CKRender::treeNodeDirtyIdsFor(previousRoot, stateUpdates, buildTrigger);

    // Build the component tree from the render function.
    [component buildComponentTree:threadScope.newScopeRoot.rootNode.node()
                   previousParent:previousRoot.rootNode.node()
                           params:{
                             .scopeRoot = threadScope.newScopeRoot,
                             .previousScopeRoot = previousRoot,
                             .stateUpdates = stateUpdates,
                             .treeNodeDirtyIds = treeNodeDirtyIds,
                             .buildTrigger = buildTrigger,
                             .enableFasterPropsUpdates = config.enableFasterPropsUpdates,
                             .isSystraceEnabled = threadScope.isSystraceEnabled,
                           }
             parentHasStateUpdate:NO];
  }

  CKComponentScopeRoot *newScopeRoot = threadScope.newScopeRoot;

  [analyticsListener didBuildComponentTreeWithScopeRoot:newScopeRoot component:component];
  return {
    .component = component,
    .scopeRoot = newScopeRoot,
    .boundsAnimation = CKComponentBoundsAnimationFromPreviousScopeRoot(newScopeRoot, previousRoot),
  };
}
