/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#ifndef CKComponentAnimationsEquality_h
#define CKComponentAnimationsEquality_h

#import <ComponentKit/CKComponentAnimations.h>

namespace CK {
  auto animationsAreEqual(const std::vector<CKComponentAnimation> &as1,
                          const std::vector<CKComponentAnimation> &as2) -> bool;

  auto animationsAreEqual(const CKComponentAnimations::AnimationsByComponentMap &as1,
                          const CKComponentAnimations::AnimationsByComponentMap &as2) -> bool;
}

auto operator==(const CKComponentAnimations &lhs, const CKComponentAnimations &rhs) -> bool;

#endif /* CKComponentAnimationsEquality_h */
