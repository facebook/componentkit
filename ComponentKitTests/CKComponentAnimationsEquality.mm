/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentAnimationsEquality.h"

namespace CK {
  auto animationsAreEqual(const std::vector<CKComponentAnimation> &as1,
                          const std::vector<CKComponentAnimation> &as2) -> bool
  {
    if (as1.size() != as2.size()) {
      return false;
    }

    for (auto i = 0; i < as1.size(); i++) {
      if (!as1[i].isIdenticalTo(as2[i])) {
        return false;
      }
    }

    return true;
  }

  auto animationsAreEqual(const CKComponentAnimations::AnimationsByComponentMap &as1,
                          const CKComponentAnimations::AnimationsByComponentMap &as2) -> bool
  {
    if (as1.size() != as2.size()) {
      return false;
    }

    for (const auto &kv : as1) {
      const auto it = as2.find(kv.first);
      if (it == as2.end() || !animationsAreEqual(kv.second, it->second)) {
        return false;
      }
    }

    return true;
  }
}

auto operator==(const CKComponentAnimations &lhs, const CKComponentAnimations &rhs) -> bool
{
  return animationsAreEqual(lhs.animationsOnInitialMount(), rhs.animationsOnInitialMount()) &&
  animationsAreEqual(lhs.animationsFromPreviousComponent(), rhs.animationsFromPreviousComponent()) &&
  animationsAreEqual(lhs.animationsOnFinalUnmount(), rhs.animationsOnFinalUnmount());
}
