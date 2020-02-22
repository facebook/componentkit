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
#import "CKThreadLocalComponentScope.h"
#import "CKTreeNodeProtocol.h"
#import "CKComponentCreationValidation.h"
#import "CKScopeTreeNodeProtocol.h"

namespace CKBuildComponentHelpers {
  auto getBuildTrigger(CKComponentScopeRoot *scopeRoot, const CKComponentStateUpdateMap &stateUpdates) -> CKBuildTrigger
  {
    if (!scopeRoot.rootNode.isEmpty()) {
      return (stateUpdates.size() > 0) ? CKBuildTrigger::StateUpdate : CKBuildTrigger::PropsUpdate;
    }
    return CKBuildTrigger::NewTree;
  }

  /**
   Computes and returns the bounds animations for the transition from a prior generation's scope root.
   */
  static auto boundsAnimationFromPreviousScopeRoot(CKComponentScopeRoot *newRoot,
                                                   CKComponentScopeRoot *previousRoot) -> CKComponentBoundsAnimation
  {
    NSMapTable *const uniqueIdentifierToOldComponent = [NSMapTable strongToStrongObjectsMapTable];
    [previousRoot
     enumerateComponentsMatchingPredicate:&CKComponentBoundsAnimationPredicate
     block:^(id<CKComponentProtocol> component) {
       CKComponent *oldComponent = (CKComponent *)component;
       id uniqueIdentifier = [oldComponent uniqueIdentifier];
       if (uniqueIdentifier) {
         [uniqueIdentifierToOldComponent setObject:oldComponent forKey:uniqueIdentifier];
       }
     }];

    __block CKComponentBoundsAnimation boundsAnimation {};
    [newRoot
     enumerateComponentsMatchingPredicate:&CKComponentBoundsAnimationPredicate
     block:^(id<CKComponentProtocol> component) {
       CKComponent *newComponent = (CKComponent *)component;
       id uniqueIdentifier = [newComponent uniqueIdentifier];
       if (uniqueIdentifier) {
         CKComponent *oldComponent = [uniqueIdentifierToOldComponent objectForKey:uniqueIdentifier];
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
                                        BOOL enableComponentReuseOptimizations,
                                        BOOL mergeTreeNodesLinks)
{
  CKCAssertNotNil(componentFactory, @"Must have component factory to build a component");
  auto const globalConfig = CKReadGlobalConfig();

  auto const buildTrigger = CKBuildComponentHelpers::getBuildTrigger(previousRoot, stateUpdates);
  CKThreadLocalComponentScope threadScope(previousRoot,
                                          stateUpdates,
                                          buildTrigger,
                                          mergeTreeNodesLinks);

  auto const analyticsListener = [previousRoot analyticsListener];
  [analyticsListener willBuildComponentTreeWithScopeRoot:previousRoot
                                            buildTrigger:buildTrigger
                                            stateUpdates:stateUpdates
                       enableComponentReuseOptimizations:enableComponentReuseOptimizations];
#if CK_ASSERTIONS_ENABLED
  const CKComponentContext<CKComponentCreationValidationContext> validationContext([[CKComponentCreationValidationContext alloc] initWithSource:CKComponentCreationValidationSourceBuild]);
#endif
  auto const component = componentFactory();

  // Build the component tree if we have a render component in the hierarchy.
  if (threadScope.newScopeRoot.hasRenderComponentInTree || globalConfig.alwaysBuildRenderTree) {
    CKBuildComponentTreeParams params = {
      .scopeRoot = threadScope.newScopeRoot,
      .previousScopeRoot = previousRoot,
      .stateUpdates = stateUpdates,
      .treeNodeDirtyIds = CKRender::treeNodeDirtyIdsFor(previousRoot, stateUpdates, buildTrigger),
      .buildTrigger = buildTrigger,
      .enableComponentReuseOptimizations = enableComponentReuseOptimizations,
      .systraceListener = threadScope.systraceListener,
      .shouldCollectTreeNodeCreationInformation = [analyticsListener shouldCollectTreeNodeCreationInformation:previousRoot],
      .mergeTreeNodesLinks = mergeTreeNodesLinks,
    };

    // Build the component tree from the render function.
    CKRender::ComponentTree::Root::build(component, params);
  }

  CKComponentScopeRoot *newScopeRoot = threadScope.newScopeRoot;

  [analyticsListener didBuildComponentTreeWithScopeRoot:newScopeRoot
                                           buildTrigger:buildTrigger
                                           stateUpdates:stateUpdates
                                              component:component
                      enableComponentReuseOptimizations:enableComponentReuseOptimizations];
  return {
    .component = component,
    .scopeRoot = newScopeRoot,
    .boundsAnimation = CKBuildComponentHelpers::boundsAnimationFromPreviousScopeRoot(newScopeRoot, previousRoot),
    .buildTrigger = buildTrigger,
  };
}
