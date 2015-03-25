/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKTextComponentViewInternal.h"

/**
 A default control tracking implementation.
 */
@interface CKTextComponentViewControlTracker : NSObject

- (BOOL)beginTrackingForTextComponentView:(CKTextComponentView *)view
                                withTouch:(UITouch *)touch
                                withEvent:(UIEvent *)event;

- (BOOL)continueTrackingForTextComponentView:(CKTextComponentView *)view
                                   withTouch:(UITouch *)touch
                                   withEvent:(UIEvent *)event;

- (void)endTrackingForTextComponentView:(CKTextComponentView *)view
                              withTouch:(UITouch *)touch
                              withEvent:(UIEvent *)event;

- (void)cancelTrackingForTextComponentView:(CKTextComponentView *)view
                                 withEvent:(UIEvent *)event;

@end
