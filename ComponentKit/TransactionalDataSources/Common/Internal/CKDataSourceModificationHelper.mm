/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKDataSourceModificationHelper.h"

#import <ComponentKit/CKBuildComponent.h>
#import <ComponentKit/CKComponentContext.h>
#import <ComponentKit/CKComponentController.h>
#import <ComponentKit/CKComponentEvents.h>
#import <ComponentKit/CKComponentProvider.h>
#import <ComponentKit/CKDataSourceConfigurationInternal.h>
#import <ComponentKit/CKDataSourceItemInternal.h>

auto CKComponentAnimationPredicates(BOOL enableNewAnimationInfrastructure) -> std::unordered_set<CKComponentPredicate>
{
  return
  enableNewAnimationInfrastructure
  ? std::unordered_set<CKComponentPredicate> {
    CKComponentHasAnimationsOnInitialMountPredicate,
    CKComponentHasAnimationsFromPreviousComponentPredicate,
    CKComponentHasAnimationsOnFinalUnmountPredicate,
  }
  : std::unordered_set<CKComponentPredicate>();
}

CKDataSourceItem *CKBuildDataSourceItem(CKComponentScopeRoot *previousRoot,
                                        const CKComponentStateUpdateMap &stateUpdates,
                                        const CKSizeRange &sizeRange,
                                        CKDataSourceConfiguration *configuration,
                                        id model,
                                        id context,
                                        const std::unordered_set<CKComponentPredicate> &layoutPredicates)
{
  Class<CKComponentProvider> componentProvider = [configuration componentProvider];
  const auto componentFactory = ^{
    const auto controllerCtx = [CKComponentControllerContext newWithHandleAnimationsInController:!configuration.enableNewAnimationInfrastructure];
    const CKComponentContext<CKComponentControllerContext> ctx {controllerCtx};
    return [componentProvider componentForModel:model context:context];
  };
  if (!configuration.unifyBuildAndLayout) {
    const CKBuildComponentResult result = CKBuildComponent(previousRoot,
                                                           stateUpdates,
                                                           componentFactory,
                                                           configuration.buildComponentConfig);
    const auto layout = CKComputeRootComponentLayout(result.component,
                                                     sizeRange,
                                                     result.scopeRoot.analyticsListener,
                                                     layoutPredicates);
    return [[CKDataSourceItem alloc] initWithLayout:layout
                                              model:model
                                          scopeRoot:result.scopeRoot
                                    boundsAnimation:result.boundsAnimation];
  } else {
    CKBuildAndLayoutComponentResult result = CKBuildAndLayoutComponent(previousRoot,
                                                                       stateUpdates,
                                                                       sizeRange,
                                                                       componentFactory,
                                                                       layoutPredicates,
                                                                       configuration.buildComponentConfig);
    return [[CKDataSourceItem alloc] initWithLayout:result.computedLayout
                                              model:model
                                          scopeRoot:result.buildComponentResult.scopeRoot
                                    boundsAnimation:result.buildComponentResult.boundsAnimation];
  }

}
