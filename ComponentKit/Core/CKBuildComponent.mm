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

static BuildTrigger getBuildTrigger(CKComponentScopeRoot *scopeRoot, const CKComponentStateUpdateMap &stateUpdates) {
  if (scopeRoot.rootFrame.childrenSize > 0 || scopeRoot.rootNode.childrenSize > 0) {
    return (stateUpdates.size() > 0) ? BuildTrigger::StateUpdate : BuildTrigger::PropsUpdate;
  }
  return BuildTrigger::NewTree;
}

static CKBuildComponentResult _CKBuildComponent(const CKBuildComponentTreeParams &params,
                                                const CKBuildComponentConfig &config,
                                                CKThreadLocalComponentScope &threadScope,
                                                CKComponent *(^componentFactory)(void))
{
  CKCAssertNotNil(componentFactory, @"Must have component factory to build a component");
  auto const previousRoot = params.scopeRoot;
  auto const analyticsListener = [previousRoot analyticsListener];
  [analyticsListener willBuildComponentTreeWithScopeRoot:previousRoot buildTrigger:params.buildTrigger];

  CKComponent *const component = componentFactory();

  if (threadScope.newScopeRoot.hasRenderComponentInTree) {
    // Build the component tree from the render function.
    [component buildComponentTree:threadScope.newScopeRoot.rootNode
                   previousParent:previousRoot.rootNode
                           params:params
                           config:config];
  }

  CKComponentScopeRoot *newScopeRoot = threadScope.newScopeRoot;

  [analyticsListener didBuildComponentTreeWithScopeRoot:newScopeRoot component:component];
  return {
    .component = component,
    .scopeRoot = newScopeRoot,
    .boundsAnimation = CKComponentBoundsAnimationFromPreviousScopeRoot(newScopeRoot, previousRoot),
  };
}


CKBuildComponentResult CKBuildComponent(CKComponentScopeRoot *previousRoot,
                                        const CKComponentStateUpdateMap &stateUpdates,
                                        CKComponent *(^componentFactory)(void),
                                        CKBuildComponentConfig config)
{
  CKThreadLocalComponentScope threadScope(previousRoot, stateUpdates);
  const CKBuildComponentTreeParams params = {
    .scopeRoot = previousRoot,
    .stateUpdates = stateUpdates,
    .buildTrigger = getBuildTrigger(previousRoot, stateUpdates),
  };
  return _CKBuildComponent(params, config, threadScope, componentFactory);
}

CKBuildAndLayoutComponentResult CKBuildAndLayoutComponent(CKComponentScopeRoot *previousRoot,
                                                          const CKComponentStateUpdateMap &stateUpdates,
                                                          const CKSizeRange &sizeRange,
                                                          CKComponent *(^componentFactory)(void),
                                                          const std::unordered_set<CKComponentPredicate> &layoutPredicates,
                                                          CKBuildComponentConfig config) {
  CKThreadLocalComponentScope threadScope(previousRoot, stateUpdates);
  const CKBuildComponentTreeParams params = {
    .scopeRoot = previousRoot,
    .stateUpdates = stateUpdates,
    .buildTrigger = getBuildTrigger(previousRoot, stateUpdates),
  };
  const CKBuildComponentResult buildComponentResult = _CKBuildComponent(params, config, threadScope, componentFactory);
  const auto computedLayout = CKComputeRootComponentLayout(buildComponentResult.component, sizeRange, buildComponentResult.scopeRoot.analyticsListener, layoutPredicates);
  return {buildComponentResult, computedLayout};
}
