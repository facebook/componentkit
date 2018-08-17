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
#import "CKComponentEvents.h"
#import "CKComponentInternal.h"
#import "CKComponentScopeRoot.h"
#import "CKComponentSubclass.h"
#import "CKRenderTreeNodeWithChildren.h"
#import "CKThreadLocalComponentScope.h"

static CKTreeNodeDirtyIds createTreeNodeDirtyIds(const CKComponentStateUpdateMap &stateUpdates)
{
  CKTreeNodeDirtyIds treeNodesDirtyIds;
  for (auto const & stateUpdate : stateUpdates) {
    CKTreeNode *treeNode = stateUpdate.first.treeNode;
    while (treeNode != nil) {
      treeNodesDirtyIds.insert(treeNode.nodeIdentifier);
      treeNode = treeNode.parent;
    }
  }
  return treeNodesDirtyIds;
}

static BuildTrigger getBuildTrigger(CKComponentScopeRoot *scopeRoot, const CKComponentStateUpdateMap &stateUpdates) {
  if (scopeRoot.rootFrame.childrenSize > 0 || scopeRoot.rootNode.childrenSize > 0) {
    return (stateUpdates.size() > 0) ? BuildTrigger::StateUpdate : BuildTrigger::PropsUpdate;
  }
  return BuildTrigger::NewTree;
}

CKBuildComponentResult CKBuildComponent(CKComponentScopeRoot *previousRoot,
                                        const CKComponentStateUpdateMap &stateUpdates,
                                        CKComponent *(^componentFactory)(void),
                                        CKBuildComponentConfig config)
{
  CKCAssertNotNil(componentFactory, @"Must have component factory to build a component");

  CKThreadLocalComponentScope threadScope(previousRoot, stateUpdates);
  auto const analyticsListener = [previousRoot analyticsListener];
  auto const buildTrigger = getBuildTrigger(previousRoot, stateUpdates);
  [analyticsListener willBuildComponentTreeWithScopeRoot:previousRoot buildTrigger:buildTrigger];

  auto const component = componentFactory();

  // Build the component tree if we have a render component in the hierarchy.
  if (threadScope.newScopeRoot.hasRenderComponentInTree) {

    CKTreeNodeDirtyIds treeNodeDirtyIds;
    if (config.enableFasterStateUpdates && buildTrigger == BuildTrigger::StateUpdate) {
      treeNodeDirtyIds = createTreeNodeDirtyIds(stateUpdates);
    }

    // Build the component tree from the render function.
    [component buildComponentTree:threadScope.newScopeRoot.rootNode
                   previousParent:previousRoot.rootNode
                           params:{
                             .scopeRoot = threadScope.newScopeRoot,
                             .stateUpdates = stateUpdates,
                             .treeNodeDirtyIds = treeNodeDirtyIds,
                             .buildTrigger = buildTrigger,
                           }
                           config:config
                   hasDirtyParent:NO];
  }

  CKComponentScopeRoot *newScopeRoot = threadScope.newScopeRoot;

  [analyticsListener didBuildComponentTreeWithScopeRoot:newScopeRoot component:component];
  return {
    .component = component,
    .scopeRoot = newScopeRoot,
    .boundsAnimation = CKComponentBoundsAnimationFromPreviousScopeRoot(newScopeRoot, previousRoot),
  };
}

CKBuildAndLayoutComponentResult CKBuildAndLayoutComponent(CKComponentScopeRoot *previousRoot,
                                                          const CKComponentStateUpdateMap &stateUpdates,
                                                          const CKSizeRange &sizeRange,
                                                          CKComponent *(^componentFactory)(void),
                                                          const std::unordered_set<CKComponentPredicate> &layoutPredicates,
                                                          CKBuildComponentConfig config) {
  CKCAssertNotNil(componentFactory, @"Must have component factory to build a component");
  CKThreadLocalComponentScope threadScope(previousRoot, stateUpdates);
  auto const analyticsListener = [previousRoot analyticsListener];
  auto const buildTrigger = getBuildTrigger(previousRoot, stateUpdates);

  auto const component = componentFactory();

  CKTreeNodeDirtyIds treeNodeDirtyIds;
  const CKBuildComponentTreeParams params = {
    .scopeRoot = threadScope.newScopeRoot,
    .stateUpdates = stateUpdates,
    .treeNodeDirtyIds = treeNodeDirtyIds,
    .buildTrigger = buildTrigger,
  };

  // Build the component tree if we have a render component in the hierarchy.
  if (threadScope.newScopeRoot.hasRenderComponentInTree) {

    if (buildTrigger == BuildTrigger::StateUpdate &&
        (config.enableFasterStateUpdates || config.enableFasterPropsUpdates)) {
      treeNodeDirtyIds = createTreeNodeDirtyIds(stateUpdates);
    }

    // Build the component tree from the render function.
    [component buildComponentTree:threadScope.newScopeRoot.rootNode
                   previousParent:previousRoot.rootNode
                           params:params
                           config:config
                   hasDirtyParent:NO];
  }

  CKComponentScopeRoot *newScopeRoot = threadScope.newScopeRoot;

  [analyticsListener didBuildComponentTreeWithScopeRoot:newScopeRoot component:component];

  const CKBuildComponentResult buildComponentResult = {
    .component = component,
    .scopeRoot = newScopeRoot,
    .boundsAnimation = CKComponentBoundsAnimationFromPreviousScopeRoot(newScopeRoot, previousRoot),
  };
  const auto computedLayout = CKComputeRootComponentLayout(buildComponentResult.component, sizeRange, buildComponentResult.scopeRoot.analyticsListener, layoutPredicates);
  return {buildComponentResult, computedLayout};
}
