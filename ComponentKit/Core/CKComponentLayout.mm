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
#import <ComponentKit/CKTreeVerificationHelpers.h>
#import <ComponentKit/ComponentLayoutContext.h>
#import <ComponentKit/CKComponentScopeRoot.h>

#import <pthread.h>

NSSet<id<CKMountable>> *CKMountComponentLayout(const CKLayout &layout,
                                               UIView *view,
                                               NSSet<id<CKMountable>> *previouslyMountedComponents,
                                               id<CKMountable> supercomponent,
                                               id<CKAnalyticsListener> analyticsListener)
{
  ((CKComponent *)layout.component).rootComponentMountedView = view;
  [analyticsListener willMountComponentTreeWithRootComponent:layout.component];

  CK::Component::MountAnalyticsContext mountAnalyticsContext;
  const BOOL collectMountAnalytics =
  [analyticsListener shouldCollectMountInformationForRootComponent:layout.component];

  NSSet<id<CKMountable>> *const mountedComponents =
  CKMountLayout(layout,
                view,
                previouslyMountedComponents,
                supercomponent,
                collectMountAnalytics ? &mountAnalyticsContext : nullptr,
                analyticsListener.systraceListener);
  [analyticsListener
   didMountComponentTreeWithRootComponent:layout.component
   mountAnalyticsContext:
   collectMountAnalytics
   ? CK::Optional<CK::Component::MountAnalyticsContext> {mountAnalyticsContext}
   : CK::none];
  return mountedComponents;
}

#if CK_ASSERTIONS_ENABLED

static pthread_key_t _threadStackRootKey() noexcept
{
  static pthread_key_t threadKey;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    (void)pthread_key_create(&threadKey, nullptr);
  });
  return threadKey;
}

size_t CKLayoutGetUsedStackSize() {
  const auto root = (char *)pthread_getspecific(_threadStackRootKey());
  if (root == nullptr) {
    return 0;
  } else {
    return root - (char *)&root;
  }
}

#endif

static auto buildComponentsByPredicateMap(const CKLayout &layout,
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
                                                   CK::Optional<CKBuildTrigger> buildTrigger,
                                                   CKComponentScopeRoot *scopeRoot)
{
  [analyticsListener willLayoutComponentTreeWithRootComponent:rootComponent buildTrigger:buildTrigger];
  CK::Component::LayoutSystraceContext systraceContext([analyticsListener systraceListener]);

#if CK_ASSERTIONS_ENABLED
  pthread_setspecific(_threadStackRootKey(), &systraceContext);
#endif

  CKLayout layout = CKComputeComponentLayout(rootComponent, sizeRange, sizeRange.max);
  auto layoutCache = CKComponentRootLayout::ComponentLayoutCache {};
  layout.enumerateLayouts([&](const auto &l){
    if ([l.component isKindOfClass:[CKComponent class]] && ((CKComponent *)l.component).controller) {
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
  CKVerifyTreeNodesToParentLinks(scopeRoot, rootLayout.layout());
  [analyticsListener didLayoutComponentTreeWithRootComponent:rootComponent];
  return rootLayout;
}

CKLayout CKComputeComponentLayout(id<CKMountable> component,
                                           const CKSizeRange &sizeRange,
                                           const CGSize parentSize)
{
  return component ? [component layoutThatFits:sizeRange parentSize:parentSize] : (CKLayout){};
}

void CKLayout::enumerateLayouts(const std::function<void(const CKLayout &)> &f) const
{
  f(*this);

  if (children == nil) { return; }
  for (const auto &child : *children) {
    child.layout.enumerateLayouts(f);
  }
}

void CKComponentRootLayout::enumerateCachedLayout(void(^ _Nonnull block)(const CKLayout &layout)) const
{
  for (const auto &it : _layoutCache) {
    block(it.second);
  }
}
