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
#import <ComponentKit/ComponentUtilities.h>

namespace CK {
  static auto makePendingAnimation(const CKComponentAnimation &a)
  {
    return CKPendingComponentAnimation {a, a.willRemount()};
  }

  void ComponentAnimationsController::collectPendingAnimations()
  {
    CKCAssert(_appliedAnimationsOnInitialMount->empty(),
              @"Instances of CK::ComponentAnimationsController can't be reused.");

    std::transform(_animations.animationsOnInitialMount().begin(),
                   _animations.animationsOnInitialMount().end(),
                   std::inserter(_pendingAnimationsOnInitialMount, _pendingAnimationsOnInitialMount.begin()),
                   [](const auto &kv){ return std::make_pair(kv.first, map(kv.second, makePendingAnimation)); });

    std::transform(_animations.animationsFromPreviousComponent().begin(),
                   _animations.animationsFromPreviousComponent().end(),
                   std::inserter(_pendingAnimationsFromPreviousComponent, _pendingAnimationsFromPreviousComponent.begin()),
                   [](const auto &kv){ return std::make_pair(kv.first, map(kv.second, makePendingAnimation)); });

    std::transform(_animations.animationsOnFinalUnmount().begin(),
                   _animations.animationsOnFinalUnmount().end(),
                   std::inserter(_pendingAnimationsOnFinalUnmount, _pendingAnimationsOnFinalUnmount.begin()),
                   [](const auto &kv) { return std::make_pair(kv.first, map(kv.second, makePendingAnimation)); });
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
