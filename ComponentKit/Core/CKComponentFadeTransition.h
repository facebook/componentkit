/*
 *  Copyright (c) 2015-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <UIKit/UIKit.h>

/**
 Specifies how to animate a fade transition to the component tree.
 */
struct CKComponentFadeTransition {
  NSTimeInterval duration;
};

/**
 Creates a CATransition object from a CKComponentFadeTransition.
 It will use kCAMediaTimingFunctionEaseInEaseOut as timing function.
 */
CATransition* CKComponentGenerateTransition(const CKComponentFadeTransition &transition);

/**
 Wraps the given block in the correct UIView transition block for a given bounds animation.
 If duration is zero, wraps [UIView +performWithoutAnimation:].
 */
void CKComponentFadeTransitionApply(const CKComponentFadeTransition &transition,
                                    UIView *view,
                                    void (^transitions)(void),
                                    void (^completion)(BOOL finished));
