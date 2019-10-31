/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentAnimationsController.h"

#import <ComponentKit/CKAssert.h>
#import <ComponentKit/CKFunctionalHelpers.h>

namespace CK {
  static auto makePendingAnimation(const CKComponentAnimation &a)
  {
    return CKPendingComponentAnimation {a, a.willRemount()};
  }

  auto collectPendingAnimations(const CKComponentAnimations &animations) -> PendingAnimations
  {
    auto pendingAnimationsOnInitialMount = PendingAnimationsByComponentMap {};
    std::transform(animations.animationsOnInitialMount().begin(),
                   animations.animationsOnInitialMount().end(),
                   std::inserter(pendingAnimationsOnInitialMount, pendingAnimationsOnInitialMount.begin()),
                   [](const auto &kv){ return std::make_pair(kv.first, map(kv.second, makePendingAnimation)); });

    auto pendingAnimationsFromPreviousComponent = PendingAnimationsByComponentMap {};
    std::transform(animations.animationsFromPreviousComponent().begin(),
                   animations.animationsFromPreviousComponent().end(),
                   std::inserter(pendingAnimationsFromPreviousComponent, pendingAnimationsFromPreviousComponent.begin()),
                   [](const auto &kv){ return std::make_pair(kv.first, map(kv.second, makePendingAnimation)); });

    auto pendingAnimationsOnFinalUnmount = PendingAnimationsByComponentMap {};
    std::transform(animations.animationsOnFinalUnmount().begin(),
                   animations.animationsOnFinalUnmount().end(),
                   std::inserter(pendingAnimationsOnFinalUnmount, pendingAnimationsOnFinalUnmount.begin()),
                   [](const auto &kv) { return std::make_pair(kv.first, map(kv.second, makePendingAnimation)); });

    return {
      pendingAnimationsOnInitialMount,
      pendingAnimationsFromPreviousComponent,
      pendingAnimationsOnFinalUnmount
    };
  }

  auto ComponentAnimationsController::cleanupAppliedAnimationsForComponent(AppliedAnimationsByComponentMap &aas, CKComponent *const c)
  {
    for (const auto &kv : aas[c]) {
      const auto a = kv.second;
      a.animation.cleanup(a.context);
    }
    aas.erase(c);
  }

  void ComponentAnimationsController::cleanupAppliedAnimationsForComponent(CKComponent *const c)
  {
    cleanupAppliedAnimationsForComponent(*_appliedAnimationsOnInitialMount, c);
    cleanupAppliedAnimationsForComponent(*_appliedAnimationsFromPreviousComponent, c);
    cleanupAppliedAnimationsForComponent(*_appliedAnimationsOnFinalUnmount, c);
  }
}
