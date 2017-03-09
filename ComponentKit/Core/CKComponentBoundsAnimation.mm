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
  if (animation.duration == 0) {
    [UIView performWithoutAnimation:animations];
    if (completion) {
      completion(YES);
    }
  } else if (animation.mode == CKComponentBoundsAnimationModeSpring) {
    [UIView animateWithDuration:animation.duration
                          delay:animation.delay
         usingSpringWithDamping:animation.springDampingRatio
          initialSpringVelocity:animation.springInitialVelocity
                        options:animation.options
                     animations:animations
                     completion:completion];
  } else {
    [UIView animateWithDuration:animation.duration
                          delay:animation.delay
                        options:animation.options
                     animations:animations
                     completion:completion];
  }
}
