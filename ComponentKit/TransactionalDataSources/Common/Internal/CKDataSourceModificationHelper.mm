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
#import <ComponentKit/CKComponentProvider.h>
#import <ComponentKit/CKDataSourceConfigurationInternal.h>
#import <ComponentKit/CKDataSourceItemInternal.h>

CKDataSourceItem *CKBuildDataSourceItem(CKComponentScopeRoot *previousRoot,
                                        const CKComponentStateUpdateMap &stateUpdates,
                                        const CKSizeRange &sizeRange,
                                        CKDataSourceConfiguration *configuration,
                                        id model,
                                        id context)
{
  Class<CKComponentProvider> componentProvider = [configuration componentProvider];
  if (!configuration.unifyBuildAndLayout) {
    const CKBuildComponentResult result = CKBuildComponent(previousRoot,
                                                           stateUpdates,
                                                           ^CKComponent *{
                                                             return [componentProvider componentForModel:model context:context];
                                                           },
                                                           configuration.buildComponentTree,
                                                           configuration.alwaysBuildComponentTree,
                                                           configuration.forceParent);
    const CKComponentLayout layout = CKComputeRootComponentLayout(result.component,
                                                                  sizeRange,
                                                                  result.scopeRoot.analyticsListener);
    return [[CKDataSourceItem alloc] initWithLayout:layout
                                              model:model
                                          scopeRoot:result.scopeRoot
                                    boundsAnimation:result.boundsAnimation];
  } else {
    CKBuildAndLayoutComponentResult result = CKBuildAndLayoutComponent(previousRoot,
                                                                       stateUpdates,
                                                                       sizeRange,
                                                                       ^CKComponent *{
                                                                         return [componentProvider componentForModel:model context:context];
                                                                       });
    return [[CKDataSourceItem alloc] initWithLayout:result.computedLayout
                                              model:model
                                          scopeRoot:result.buildComponentResult.scopeRoot
                                    boundsAnimation:result.buildComponentResult.boundsAnimation];
  }

}
