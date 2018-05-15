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


static CKBuildComponentResult _CKBuildComponent(CKComponentScopeRoot *previousRoot,
                                                const CKComponentStateUpdateMap &stateUpdates,
                                                BOOL forceParent,
                                                CKThreadLocalComponentScope& threadScope,
                                                CKComponent *(^componentFactory)(void))
{
  CKCAssertNotNil(componentFactory, @"Must have component factory to build a component");
  const auto analyticsListener = [previousRoot analyticsListener];
  [analyticsListener willBuildComponentTreeWithScopeRoot:previousRoot];

  CKComponent *const component = componentFactory();

  if (threadScope.newScopeRoot.hasRenderComponentInTree) {
    // Build the component tree from the render function.
    [component buildComponentTree:threadScope.newScopeRoot.rootNode
                    previousOwner:previousRoot.rootNode
                        scopeRoot:threadScope.newScopeRoot
                     stateUpdates:stateUpdates
                      forceParent:forceParent];
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
                                        BOOL forceParent)
{
  CKThreadLocalComponentScope threadScope(previousRoot, stateUpdates);
  return _CKBuildComponent(previousRoot, stateUpdates, forceParent, threadScope, componentFactory);
}

CKBuildAndLayoutComponentResult CKBuildAndLayoutComponent(CKComponentScopeRoot *previousRoot,
                                                          const CKComponentStateUpdateMap &stateUpdates,
                                                          const CKSizeRange &sizeRange,
                                                          CKComponent *(^componentFactory)(void),
                                                          BOOL forceParent) {
  CKThreadLocalComponentScope threadScope(previousRoot, stateUpdates);
  const CKBuildComponentResult builcComponentResult = _CKBuildComponent(previousRoot, stateUpdates, forceParent, threadScope, componentFactory);
  const CKComponentLayout computedLayout = CKComputeRootComponentLayout(builcComponentResult.component, sizeRange, builcComponentResult.scopeRoot.analyticsListener);
  return {builcComponentResult, computedLayout};
}
