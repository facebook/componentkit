/*
 *  Copyright (c) 2015-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentFadeTransition.h"

CATransition* CKComponentGenerateTransition(const CKComponentFadeTransition &transition)
{
  CATransition *fadeTransition = [CATransition animation];
  fadeTransition.duration = transition.duration;
  fadeTransition.type = kCATransitionFade;
  fadeTransition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
  return fadeTransition;
}

void CKComponentFadeTransitionApply(const CKComponentFadeTransition &transition,
                                    UIView *view,
                                    void (^transitions)(void),
                                    void (^completion)(BOOL finished))
{
  if (transition.duration == 0) {
    [UIView performWithoutAnimation:transitions];
    if (completion) {
      completion(YES);
    }
  } else {
    [UIView transitionWithView:view
                      duration:transition.duration
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:transitions
                    completion:completion];
  }
}