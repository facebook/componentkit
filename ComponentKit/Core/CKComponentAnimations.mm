/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentAnimations.h"

#import <ComponentKit/CKCasting.h>
#import <ComponentKit/CKCollection.h>
#import <ComponentKit/CKInternalHelpers.h>

#import "CKComponentEvents.h"
#import "CKComponentScopeRoot.h"
#import "CKComponentInternal.h"
#import "CKComponentSubclass.h"

namespace CK {
  static auto getScopeHandle(id<CKMountable> const c) {
    const auto scopeHandle = objCForceCast<CKComponent>(c).scopeHandle;
    CKCAssertNotNil(scopeHandle, @"Scope must be provided for component animation");
    return scopeHandle;
  }
  static auto isSameHandle(CKComponentScopeHandle *const h1, CKComponentScopeHandle *const &h2) { return h1.globalIdentifier == h2.globalIdentifier; };
  static auto acquiredComponent(CKComponentScopeHandle *const h) { return objCForceCast<CKComponent>(h.acquiredComponent); };

  static auto animatedAppearedComponentsBetweenLayouts(const CKComponentRootLayout &newLayout,
                                                       const CKComponentRootLayout &previousLayout) -> std::vector<CKComponent *>
  {
    const auto newHandlesWithInitialAnimations = map(newLayout.componentsMatchingPredicate(CKComponentHasAnimationsOnInitialMountPredicate), getScopeHandle);
    const auto oldHandlesWithInitialAnimations = map(previousLayout.componentsMatchingPredicate(CKComponentHasAnimationsOnInitialMountPredicate), getScopeHandle);
    const auto handlesForAppearedComponentsWithInitialAnimations = Collection::difference(newHandlesWithInitialAnimations,
                                                                                          oldHandlesWithInitialAnimations,
                                                                                          isSameHandle);
    return map(handlesForAppearedComponentsWithInitialAnimations, acquiredComponent);
  }

  static auto animatedUpdatedComponentsBetweenLayouts(const CKComponentRootLayout &newLayout,
                                                      const CKComponentRootLayout &previousLayout)  -> std::vector<CK::ComponentTreeDiff::Pair>
  {
    const auto newHandlesWithAnimationsFromPreviousComponent = map(newLayout.componentsMatchingPredicate(CKComponentHasAnimationsFromPreviousComponentPredicate), getScopeHandle);
    const auto oldHandlesWithAnimationsFromPreviousComponent = map(previousLayout.componentsMatchingPredicate(CKComponentHasAnimationsFromPreviousComponentPredicate), getScopeHandle);
    const auto handlesForUpdatedComponents = Collection::intersection(newHandlesWithAnimationsFromPreviousComponent,
                                                                      oldHandlesWithAnimationsFromPreviousComponent,
                                                                      [](const auto &h1, const auto &h2){
                                                                        return isSameHandle(h1, h2) && h1.acquiredComponent != h2.acquiredComponent;
                                                                      });

    return map(handlesForUpdatedComponents, [&](const auto &h){
      const auto prevHandle =
      std::find_if(oldHandlesWithAnimationsFromPreviousComponent.begin(),
                   oldHandlesWithAnimationsFromPreviousComponent.end(),
                   [&](const auto &oldHandle) { return oldHandle.globalIdentifier == h.globalIdentifier; });
      return ComponentTreeDiff::Pair { acquiredComponent(*prevHandle), acquiredComponent(h) };
    });
  }

  static auto animatedDisappearedComponentsBetweenLayouts(const CKComponentRootLayout &newLayout,
                                                          const CKComponentRootLayout &previousLayout) -> std::vector<CKComponent *>
  {
    const auto newHandlesWithAnimationsOnDisappear = map(newLayout.componentsMatchingPredicate(CKComponentHasAnimationsOnFinalUnmountPredicate), getScopeHandle);
    const auto oldHandlesWithAnimationsOnDisappear = map(previousLayout.componentsMatchingPredicate(CKComponentHasAnimationsOnFinalUnmountPredicate), getScopeHandle);
    const auto handlesForDisappearedComponentsWithAnimationsOnDisappear = Collection::difference(oldHandlesWithAnimationsOnDisappear,
                                                                                                 newHandlesWithAnimationsOnDisappear,
                                                                                                 isSameHandle);
    return map(handlesForDisappearedComponentsWithAnimationsOnDisappear, acquiredComponent);
  }

  auto animatedComponentsBetweenLayouts(const CKComponentRootLayout &newLayout,
                                        const CKComponentRootLayout &previousLayout) -> ComponentTreeDiff
  {
    return {
      .appearedComponents = animatedAppearedComponentsBetweenLayouts(newLayout, previousLayout),
      .updatedComponents = animatedUpdatedComponentsBetweenLayouts(newLayout, previousLayout),
      .disappearedComponents = animatedDisappearedComponentsBetweenLayouts(newLayout, previousLayout),
    };
  }

  auto animationsForComponents(const ComponentTreeDiff& animatedComponents, UIView *const hostView) -> CKComponentAnimations
  {
    if (animatedComponents.appearedComponents.empty() &&
        animatedComponents.updatedComponents.empty() &&
        animatedComponents.disappearedComponents.empty()) {
      return {};
    }

    const auto animationsOnInitialMountPairs = filter(map(animatedComponents.appearedComponents, [](const auto &c) {
      return std::make_pair(c, c.animationsOnInitialMount);
    }), [](const auto &pair) {
      return !pair.second.empty();
    });

    const auto animationsOnInitialMount =
    CKComponentAnimations::AnimationsByComponentMap(animationsOnInitialMountPairs.begin(),
                                                    animationsOnInitialMountPairs.end());

    const auto animationsFromPreviousComponentPairs = filter(map(animatedComponents.updatedComponents, [](const auto &pair) {
      return std::make_pair(pair.current, [pair.current animationsFromPreviousComponent:pair.prev]);
    }), [](const auto &pair) {
      return !pair.second.empty();
    });

    const auto animationsFromPrevComponent =
    CKComponentAnimations::AnimationsByComponentMap(animationsFromPreviousComponentPairs.begin(),
                                                    animationsFromPreviousComponentPairs.end());

    const auto animationsOnFinalUnmountPairs = filter(map(animatedComponents.disappearedComponents, [hostView](const auto &c) {
      return std::make_pair(c, map(c.animationsOnFinalUnmount, [hostView](const auto &a) {
        return CKComponentAnimation {a, hostView};
      }));
    }), [](const auto &pair) {
      return !pair.second.empty();
    });

    const auto animationsOnFinalUnmount =
    CKComponentAnimations::AnimationsByComponentMap(animationsOnFinalUnmountPairs.begin(),
                                                    animationsOnFinalUnmountPairs.end());

    return {animationsOnInitialMount, animationsFromPrevComponent, animationsOnFinalUnmount};
  }
}

static auto descriptionForAnimationsByComponentMap(const CKComponentAnimations::AnimationsByComponentMap &map)
{
  auto pairStrs = static_cast<NSMutableArray<NSString *> *>([NSMutableArray array]);
  for (const auto &p : map) {
    for (const auto &a : p.second) {
      [pairStrs addObject:[NSString stringWithFormat:@"\t%@: %p", p.first, &a]];
    }
  }
  return [pairStrs componentsJoinedByString:@",\n"];
}

auto CKComponentAnimations::description() const -> NSString *
{
  auto description = [NSMutableString new];
  if (!_animationsOnInitialMount.empty()) {
    [description appendString:@"Animations on initial mount: {\n"];
    [description appendString:descriptionForAnimationsByComponentMap(_animationsOnInitialMount)];
    [description appendString:@"\n}\n"];
  }
  if (!_animationsFromPreviousComponent.empty()) {
    [description appendString:@"Animations from previous component: {\n"];
    [description appendString:descriptionForAnimationsByComponentMap(_animationsFromPreviousComponent)];
    [description appendString:@"\n}\n"];
  }
  if (!_animationsOnFinalUnmount.empty()) {
    [description appendString:@"Final unmount animations from component: {\n"];
    [description appendString:descriptionForAnimationsByComponentMap(_animationsOnFinalUnmount)];
    [description appendString:@"\n}\n"];
  }
  return description;
}
