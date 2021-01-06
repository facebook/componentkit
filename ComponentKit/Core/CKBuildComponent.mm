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

namespace CKBuildComponentHelpers {
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

auto CKBuildComponentTrigger(CK::NonNull<CKComponentScopeRoot *> scopeRoot,
                             const CKComponentStateUpdateMap &stateUpdates,
                             BOOL treeEnvironmentChanged,
                             BOOL treeHasPropsUpdate) -> CKBuildTrigger
{
  CKBuildTrigger trigger = CKBuildTriggerNone;

  if ([scopeRoot isEmpty] == NO) {
    if (stateUpdates.empty() == false) {
      trigger |= CKBuildTriggerStateUpdate;
    }

    if (treeHasPropsUpdate) {
      trigger |= CKBuildTriggerPropsUpdate;
    }

    if (treeEnvironmentChanged) {
      trigger |= CKBuildTriggerEnvironmentUpdate;
    } else if (stateUpdates.empty()) {
      trigger |= CKBuildTriggerPropsUpdate;
    }
  } else {
    CKCAssert(stateUpdates.empty(), @"No previous scope root but state updates");
  }

  return trigger;
}

CKBuildComponentResult CKBuildComponent(CK::NonNull<CKComponentScopeRoot *> previousRoot,
                                        const CKComponentStateUpdateMap &stateUpdates,
                                        NS_NOESCAPE CKComponent *(^componentFactory)(void))
{
  auto const buildTrigger = CKBuildComponentTrigger(previousRoot, stateUpdates, NO, NO);
  return CKBuildComponent(previousRoot, stateUpdates, componentFactory, buildTrigger, CKReadGlobalConfig().coalescingMode);
}

CKBuildComponentResult CKBuildComponent(CK::NonNull<CKComponentScopeRoot *> previousRoot,
                                        const CKComponentStateUpdateMap &stateUpdates,
                                        NS_NOESCAPE CKComponent *(^componentFactory)(void),
                                        CKBuildTrigger buildTrigger,
                                        CKReflowTrigger reflowTrigger,
                                        RCComponentCoalescingMode coalescingMode)
{
  CKCAssertNotNil(componentFactory, @"Must have component factory to build a component");
  auto const globalConfig = CKReadGlobalConfig();

  auto const analyticsListener = [previousRoot analyticsListener];
  auto const shouldCollectTreeNodeCreationInformation = [analyticsListener shouldCollectTreeNodeCreationInformation:previousRoot];

  CKThreadLocalComponentScope threadScope(previousRoot,
                                          stateUpdates,
                                          buildTrigger,
                                          shouldCollectTreeNodeCreationInformation,
                                          globalConfig.alwaysBuildRenderTree,
                                          coalescingMode,
                                          /* enforce CKComponent */ YES,
                                          globalConfig.disableRenderToNilInCoalescedCompositeComponents);

  [analyticsListener willBuildComponentTreeWithScopeRoot:previousRoot
                                            buildTrigger:buildTrigger
                                            stateUpdates:stateUpdates];
#if CK_ASSERTIONS_ENABLED
  const CKComponentContext<CKComponentCreationValidationContext> validationContext([[CKComponentCreationValidationContext alloc] initWithSource:CKComponentCreationValidationSourceBuild]);
#endif
  auto const component = componentFactory();

  // Build the component tree if we have a render component in the hierarchy.
  if ([threadScope.newScopeRoot hasRenderComponentInTree] || globalConfig.alwaysBuildRenderTree) {
    CKBuildComponentTreeParams params = {
      .scopeRoot = threadScope.newScopeRoot,
      .previousScopeRoot = previousRoot,
      .stateUpdates = stateUpdates,
      .treeNodeDirtyIds = threadScope.treeNodeDirtyIds,
      .buildTrigger = buildTrigger,
      .systraceListener = threadScope.systraceListener,
      .shouldCollectTreeNodeCreationInformation = shouldCollectTreeNodeCreationInformation,
      .coalescingMode = coalescingMode,
    };

    // Build the component tree from the render function.
    CKRender::ComponentTree::Root::build(component, params);
  }

  auto newScopeRoot = threadScope.newScopeRoot;
  auto const boundsAnimation = CKBuildComponentHelpers::boundsAnimationFromPreviousScopeRoot(newScopeRoot, previousRoot);

  [analyticsListener didBuildComponentTreeWithScopeRoot:newScopeRoot
                                           buildTrigger:buildTrigger
                                           stateUpdates:stateUpdates
                                              component:component
                                        boundsAnimation:boundsAnimation];
  [newScopeRoot setRootComponent:component];
  return {
    .component = component,
    .scopeRoot = newScopeRoot,
    .boundsAnimation = boundsAnimation,
    .buildTrigger = buildTrigger,
  };
}
