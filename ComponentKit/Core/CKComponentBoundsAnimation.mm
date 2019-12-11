/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentBoundsAnimation.h"

void CKComponentBoundsAnimationApply(const CKComponentBoundsAnimation &animation,
                                     void (^animations)(void),
                                     void (^completion)(BOOL finished))
{
  // Avoid capturing the unmanaged reference to animation
  auto const ac = animation.completion;
  auto const _completion = ^(BOOL finished){
    if (auto c = ac) {
      c();
    }
    if (auto c = completion) {
      c(finished);
    }
  };

  if (animation.duration == 0) {
    [UIView performWithoutAnimation:animations];
    _completion(YES);
  } else {
    [CATransaction begin];
    [CATransaction setAnimationTimingFunction:animation.timingFunction];
    if (animation.mode == CKComponentBoundsAnimationModeSpring) {
      [UIView animateWithDuration:animation.duration
                            delay:animation.delay
           usingSpringWithDamping:animation.springDampingRatio
            initialSpringVelocity:animation.springInitialVelocity
                          options:animation.options
                       animations:animations
                       completion:_completion];
    } else {
      [UIView animateWithDuration:animation.duration
                            delay:animation.delay
                          options:animation.options
                       animations:animations
                       completion:_completion];
    }
    [CATransaction commit];
  }
}

static BOOL CAMediaTimingFunctionsAreEqual(CAMediaTimingFunction *t1, CAMediaTimingFunction *t2)
{
  if (t1 == t2) {
    return YES;
  }
  const auto pointsAreEqualAtIndex = [&](size_t index) {
    float point1[2], point2[2];
    [t1 getControlPointAtIndex:index values:point1];
    [t2 getControlPointAtIndex:index values:point2];
    return point1[0] == point2[0] && point1[1] == point2[1];
  };
  return pointsAreEqualAtIndex(0)
    && pointsAreEqualAtIndex(1)
    && pointsAreEqualAtIndex(2)
    && pointsAreEqualAtIndex(3);
}

auto operator ==(const CKComponentBoundsAnimation &lhs, const CKComponentBoundsAnimation &rhs) -> bool
{
  auto const commonPropsAreEqual =
      lhs.duration == rhs.duration && lhs.delay == rhs.delay && lhs.mode == rhs.mode && lhs.options == rhs.options && CAMediaTimingFunctionsAreEqual(lhs.timingFunction, rhs.timingFunction);

  if (lhs.mode == CKComponentBoundsAnimationModeDefault) {
    return commonPropsAreEqual;
  }

  return commonPropsAreEqual && lhs.springDampingRatio == rhs.springDampingRatio &&
         lhs.springInitialVelocity == rhs.springInitialVelocity;
}

auto operator !=(const CKComponentBoundsAnimation &lhs, const CKComponentBoundsAnimation &rhs) -> bool
{
  return !(lhs == rhs);
}
