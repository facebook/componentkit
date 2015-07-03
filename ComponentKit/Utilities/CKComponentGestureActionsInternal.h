/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <Foundation/Foundation.h>

/** Exposed only for testing. Do not touch this directly. */
@interface CKComponentGestureActionForwarder : NSObject
+ (instancetype)sharedInstance;
- (void)handleGesture:(UIGestureRecognizer *)recognizer;
@end

/** Exposed only for testing. Do not touch this directly. */
@interface UIGestureRecognizer (CKComponent)
- (CKComponentAction)ck_componentAction;
- (void)ck_setComponentAction:(CKComponentAction)action;
@end
