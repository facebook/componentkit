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
#import <ComponentKit/CKComponentInternal.h>
#import <ComponentKit/CKComponentSubclass.h>
#import <ComponentKit/CKDetectDuplicateComponent.h>
#import <ComponentKit/ComponentLayoutContext.h>

CKMountLayoutResult CKMountComponentLayout(const CKComponentLayout &layout,
                                           UIView *view,
                                           NSSet *previouslyMountedComponents,
                                           id<CKMountable> supercomponent,
                                           id<CKAnalyticsListener> analyticsListener,
                                           BOOL isUpdate)
{
  ((CKComponent *)layout.component).rootComponentMountedView = view;
  [analyticsListener willMountComponentTreeWithRootComponent:layout.component];
  const auto result =
  CKMountLayout(layout,
                view,
                previouslyMountedComponents,
                supercomponent,
                isUpdate,
                [analyticsListener shouldCollectMountInformationForRootComponent:layout.component],
                analyticsListener.systraceListener);
  [analyticsListener didMountComponentTreeWithRootComponent:layout.component
                                      mountAnalyticsContext:result.mountAnalyticsContext];
  return result;
}

static auto buildComponentsByPredicateMap(const CKComponentLayout &layout,
                                          const std::unordered_set<CKMountablePredicate> &predicates)
{
  auto componentsByPredicate = CKComponentRootLayout::ComponentsByPredicateMap {};
  if (predicates.empty()) {
    return componentsByPredicate;
  }
  layout.enumerateLayouts([&](const auto &l){
    if (l.component == nil) { return; }
    for (const auto &p : predicates) {
      if (p(l.component)) {
        componentsByPredicate[p].push_back(l.component);
      }
    }
  });
  return componentsByPredicate;
}

CKComponentRootLayout CKComputeRootComponentLayout(id<CKMountable> rootComponent,
                                                   const CKSizeRange &sizeRange,
                                                   id<CKAnalyticsListener> analyticsListener,
                                                   CK::Optional<CKBuildTrigger> buildTrigger)
{
  [analyticsListener willLayoutComponentTreeWithRootComponent:rootComponent buildTrigger:buildTrigger];
  CK::Component::LayoutSystraceContext systraceContext([analyticsListener systraceListener]);

  CKComponentLayout layout = CKComputeComponentLayout(rootComponent, sizeRange, sizeRange.max);
  auto layoutCache = CKComponentRootLayout::ComponentLayoutCache {};
  layout.enumerateLayouts([&](const auto &l){
    if (l.component.controller) {
      layoutCache[l.component] = l;
    }
  });
  const auto componentsByPredicate = buildComponentsByPredicateMap(layout, CKComponentAnimationPredicates());
  const auto rootLayout = CKComponentRootLayout {
    layout,
    layoutCache,
    componentsByPredicate,
  };

  CKDetectDuplicateComponent(rootLayout.layout());
  [analyticsListener didLayoutComponentTreeWithRootComponent:rootComponent];
  return rootLayout;
}

CKComponentLayout CKComputeComponentLayout(id<CKMountable> component,
                                           const CKSizeRange &sizeRange,
                                           const CGSize parentSize)
{
  return component ? [component layoutThatFits:sizeRange parentSize:parentSize] : (CKComponentLayout){};
}

void CKComponentLayout::enumerateLayouts(const std::function<void(const CKComponentLayout &)> &f) const
{
  f(*this);

  if (children == nil) { return; }
  for (const auto &child : *children) {
    child.layout.enumerateLayouts(f);
  }
}

void CKComponentRootLayout::enumerateCachedLayout(void(^ _Nonnull block)(const CKComponentLayout &layout)) const
{
  for (const auto &it : _layoutCache) {
    block(it.second);
  }
}
