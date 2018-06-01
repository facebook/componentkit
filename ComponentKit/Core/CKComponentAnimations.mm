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

  static auto animatedAppearedComponentsBetweenScopeRoots(CKComponentScopeRoot *const newRoot,
                                                          CKComponentScopeRoot *const previousRoot)
  {
    const auto newHandlesWithInitialAnimations = map([newRoot componentsMatchingPredicate:&CKComponentHasAnimationsOnInitialMountPredicate], getScopeHandle);
    const auto oldHandlesWithInitialAnimations = map([previousRoot componentsMatchingPredicate:&CKComponentHasAnimationsOnInitialMountPredicate], getScopeHandle);

    const auto handlesForAppearedComponentsWithInitialAnimations = Collection::difference(newHandlesWithInitialAnimations,
                                                                                          oldHandlesWithInitialAnimations,
                                                                                          isSameHandle);
    return map(handlesForAppearedComponentsWithInitialAnimations, acquiredComponent);
  }

  static auto animatedUpdatedComponentsBetweenScopeRoots(CKComponentScopeRoot *const newRoot,
                                                         CKComponentScopeRoot *const previousRoot)
  {
    const auto newHandlesWithAnimationsFromPreviousComponent = map([newRoot componentsMatchingPredicate:&CKComponentHasAnimationsFromPreviousComponentPredicate], getScopeHandle);
    const auto oldHandlesWithAnimationsFromPreviousComponent = map([previousRoot componentsMatchingPredicate:&CKComponentHasAnimationsFromPreviousComponentPredicate], getScopeHandle);
    const auto handlesForUpdatedComponents = Collection::intersection(newHandlesWithAnimationsFromPreviousComponent,
                                                                      oldHandlesWithAnimationsFromPreviousComponent,
                                                                      isSameHandle);

    return map(handlesForUpdatedComponents, [&](const auto &h){
      const auto prevHandle =
      std::find_if(oldHandlesWithAnimationsFromPreviousComponent.begin(),
                   oldHandlesWithAnimationsFromPreviousComponent.end(),
                   [&](const auto &oldHandle) { return oldHandle.globalIdentifier == h.globalIdentifier; });
      return ComponentTreeDiff::Pair { acquiredComponent(*prevHandle), acquiredComponent(h) };
    });
  }

  auto animatedComponentsBetweenScopeRoots(CKComponentScopeRoot *const newRoot,
                                           CKComponentScopeRoot *const previousRoot) -> ComponentTreeDiff
  {
    return {
      .appearedComponents = animatedAppearedComponentsBetweenScopeRoots(newRoot, previousRoot),
      .updatedComponents = animatedUpdatedComponentsBetweenScopeRoots(newRoot, previousRoot),
    };
  }

  auto animationsForComponents(const ComponentTreeDiff& animatedComponents) -> CKComponentAnimations
  {
    if (animatedComponents.appearedComponents.empty() && animatedComponents.updatedComponents.empty()) {
      return {};
    }

    const auto initialAnimations = Collection::flatten(
      map(animatedComponents.appearedComponents, [](const auto &c) { return c.animationsOnInitialMount; })
    );

    const auto animationsFromPrevComponent = Collection::flatten(
      map(animatedComponents.updatedComponents, [](const auto &pair) {
        return [pair.current animationsFromPreviousComponent:pair.prev];
      })
    );

    return {initialAnimations, animationsFromPrevComponent};
  }
}
