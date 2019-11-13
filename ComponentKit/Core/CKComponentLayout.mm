/*
*  Copyright (c) 2014-present, Facebook, Inc.
*  All rights reserved.
*
*  This source code is licensed under the BSD-style license found in the
*  LICENSE file in the root directory of this source tree. An additional grant
*  of patent rights can be found in the PATENTS file in the same directory.
*
*/

#import "CKComponentLayout.h"

#import <ComponentKit/CKAnalyticsListener.h>
#import <ComponentKit/CKComponentAnimationPredicates.h>
#import <ComponentKit/CKDetectDuplicateComponent.h>
#import <ComponentKit/ComponentLayoutContext.h>

CKMountLayoutResult CKMountComponentLayout(const CKComponentLayout &layout,
                                           UIView *view,
                                           NSSet *previouslyMountedComponents,
                                           id<CKMountable> supercomponent,
                                           id<CKAnalyticsListener> analyticsListener,
                                           BOOL isUpdate)
{
  [analyticsListener willMountComponentTreeWithRootComponent:layout.component];
  const auto result =
  CKMountLayout(layout,
                view,
                previouslyMountedComponents,
                supercomponent,
                isUpdate,
                [analyticsListener shouldCollectMountInformationForRootComponent:layout.component],
                [&](const auto component) {
                  [analyticsListener.systraceListener willMountComponent:component];
                },
                [&](const auto component) {
                  [analyticsListener.systraceListener didMountComponent:component];
                });
  [analyticsListener didMountComponentTreeWithRootComponent:layout.component
                                      mountAnalyticsContext:result.mountAnalyticsContext];
  return result;
}

CKComponentRootLayout CKComputeRootComponentLayout(id<CKMountable> rootComponent,
                                                   const CKSizeRange &sizeRange,
                                                   id<CKAnalyticsListener> analyticsListener,
                                                   CK::Optional<CKBuildTrigger> buildTrigger)
{
  [analyticsListener willLayoutComponentTreeWithRootComponent:rootComponent buildTrigger:buildTrigger];
  CK::Component::LayoutSystraceContext systraceContext([analyticsListener systraceListener]);
  const auto rootLayout = CKComputeRootLayout(rootComponent, sizeRange, CKComponentAnimationPredicates());
  CKDetectDuplicateComponent(rootLayout.layout());
  [analyticsListener didLayoutComponentTreeWithRootComponent:rootComponent];
  return rootLayout;
}
