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

#import <ComponentKit/CKDataSourceItemInternal.h>

CKDataSourceItem *CKBuildDataSourceItem(CKComponentScopeRoot *previousRoot,
                                        const CKComponentStateUpdateMap &stateUpdates,
                                        const CKSizeRange &sizeRange,
                                        CKDataSourceConfiguration *configuration,
                                        id model,
                                        id context,
                                        BOOL ignoreComponentReuseOptimizations)
{
  auto const componentProvider = [configuration componentProvider];
  const auto componentFactory = ^{
    return componentProvider(model, context);
  };
  const CKBuildComponentResult result = CKBuildComponent(previousRoot,
                                                         stateUpdates,
                                                         componentFactory,
                                                         ignoreComponentReuseOptimizations);
  const auto rootLayout = CKComputeRootComponentLayout(result.component,
                                                       sizeRange,
                                                       result.scopeRoot.analyticsListener,
                                                       result.buildTrigger);
  return [[CKDataSourceItem alloc] initWithRootLayout:rootLayout
                                                model:model
                                            scopeRoot:result.scopeRoot
                                      boundsAnimation:result.boundsAnimation];
}
