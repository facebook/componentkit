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

  /**
   Computes and returns the bounds animations for the transition from a prior generation's scope root.
   */
  static auto boundsAnimationFromPreviousScopeRoot(CKComponentScopeRoot *newRoot,
                                                   CKComponentScopeRoot *previousRoot) -> CKComponentBoundsAnimation
  {
    NSMapTable *const scopeFrameTokenToOldComponent = [NSMapTable strongToStrongObjectsMapTable];
    [previousRoot
     enumerateComponentsMatchingPredicate:&CKComponentBoundsAnimationPredicate
     block:^(id<CKComponentProtocol> component) {
       CKComponent *oldComponent = (CKComponent *)component;
       id scopeFrameToken = [oldComponent scopeFrameToken];
       if (scopeFrameToken) {
         [scopeFrameTokenToOldComponent setObject:oldComponent forKey:scopeFrameToken];
       }
     }];

    __block CKComponentBoundsAnimation boundsAnimation {};
    [newRoot
     enumerateComponentsMatchingPredicate:&CKComponentBoundsAnimationPredicate
     block:^(id<CKComponentProtocol> component) {
       CKComponent *newComponent = (CKComponent *)component;
       id scopeFrameToken = [newComponent scopeFrameToken];
       if (scopeFrameToken) {
         CKComponent *oldComponent = [scopeFrameTokenToOldComponent objectForKey:scopeFrameToken];
         if (oldComponent) {
           auto const ba = [newComponent boundsAnimationFromPreviousComponent:oldComponent];
           if (ba.duration != 0) {
             boundsAnimation = ba;
#if CK_ASSERTIONS_ENABLED
             boundsAnimation.component = newComponent;
#endif
           }
         }
       }
     }];
    return boundsAnimation;
  }
}

CKBuildComponentResult CKBuildComponent(CKComponentScopeRoot *previousRoot,
                                        const CKComponentStateUpdateMap &stateUpdates,
                                        CKComponent *(^componentFactory)(void),
                                        CKBuildComponentConfig config,
                                        BOOL ignoreComponentReuseOptimizations)
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
    CKBuildComponentTreeParams params = {
      .scopeRoot = threadScope.newScopeRoot,
      .previousScopeRoot = previousRoot,
      .stateUpdates = stateUpdates,
      .treeNodeDirtyIds = CKRender::treeNodeDirtyIdsFor(previousRoot, stateUpdates, buildTrigger),
      .buildTrigger = buildTrigger,
      .enableFasterPropsUpdates = config.enableFasterPropsUpdates,
      .ignoreComponentReuseOptimizations = ignoreComponentReuseOptimizations,
      .systraceListener = threadScope.systraceListener,
    };

    // Build the component tree from the render function.
    [component buildComponentTree:threadScope.newScopeRoot.rootNode.node()
                   previousParent:previousRoot.rootNode.node()
                           params:params
             parentHasStateUpdate:NO];

#if DEBUG
    auto debugAnalyticsListener = [previousRoot.analyticsListener debugAnalyticsListener];
    [debugAnalyticsListener canReuseNodes:params.canBeReusedNodes
                        previousScopeRoot:previousRoot
                             newScopeRoot:threadScope.newScopeRoot
                                component:component];
#endif
  }

  CKComponentScopeRoot *newScopeRoot = threadScope.newScopeRoot;

  [analyticsListener didBuildComponentTreeWithScopeRoot:newScopeRoot component:component];
  return {
    .component = component,
    .scopeRoot = newScopeRoot,
    .boundsAnimation = CKBuildComponentHelpers::boundsAnimationFromPreviousScopeRoot(newScopeRoot, previousRoot),
  };
}
