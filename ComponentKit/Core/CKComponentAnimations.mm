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

#import "CKCasting.h"
#import "CKCollection.h"
#import "CKComponentEvents.h"
#import "CKComponentScopeRoot.h"
#import "CKComponentInternal.h"
#import "CKComponentSubclass.h"
#import "CKInternalHelpers.h"

namespace CK {
  static auto getScopeHandle(id<CKComponentProtocol> const c) { return objCForceCast<CKComponent>(c).scopeHandle; }
  static auto isSameHandle(CKComponentScopeHandle *const h1, CKComponentScopeHandle *const &h2) { return h1.globalIdentifier == h2.globalIdentifier; };
  static auto acquiredComponent(CKComponentScopeHandle *const h) { return objCForceCast<CKComponent>(h.acquiredComponent); };

  static auto animatedAppearedComponentsBetweenLayouts(const CKComponentRootLayout &newLayout,
                                                       const CKComponentRootLayout &previousLayout)
  {
    const auto newHandlesWithInitialAnimations = map(newLayout.componentsMatchingPredicate(CKComponentHasAnimationsOnInitialMountPredicate), getScopeHandle);
    const auto oldHandlesWithInitialAnimations = map(previousLayout.componentsMatchingPredicate(CKComponentHasAnimationsOnInitialMountPredicate), getScopeHandle);
    const auto handlesForAppearedComponentsWithInitialAnimations = Collection::difference(newHandlesWithInitialAnimations,
                                                                                          oldHandlesWithInitialAnimations,
                                                                                          isSameHandle);
    return map(handlesForAppearedComponentsWithInitialAnimations, acquiredComponent);
  }

  static auto animatedUpdatedComponentsBetweenLayouts(const CKComponentRootLayout &newLayout,
                                                      const CKComponentRootLayout &previousLayout)
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

  auto animatedComponentsBetweenLayouts(const CKComponentRootLayout &newLayout,
                                        const CKComponentRootLayout &previousLayout) -> ComponentTreeDiff
  {
    return {
      .appearedComponents = animatedAppearedComponentsBetweenLayouts(newLayout, previousLayout),
      .updatedComponents = animatedUpdatedComponentsBetweenLayouts(newLayout, previousLayout),
    };
  }

  auto animationsForComponents(const ComponentTreeDiff& animatedComponents) -> CKComponentAnimations
  {
    if (animatedComponents.appearedComponents.empty() && animatedComponents.updatedComponents.empty()) {
      return {};
    }

    const auto animationsOnInitialMountPairs = filter(map(animatedComponents.appearedComponents, [](const auto &c) {
      return std::make_pair(c, c.animationsOnInitialMount);
    }), [](const auto &pair) {
      return !pair.second.empty();
    });

    const auto initialAnimations =
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

    return {initialAnimations, animationsFromPrevComponent};
  }
}
