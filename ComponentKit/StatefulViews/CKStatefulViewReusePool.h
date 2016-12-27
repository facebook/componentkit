/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <UIKit/UIKit.h>

@interface CKStatefulViewReusePool : NSObject

+ (instancetype)sharedPool;

- (UIView *)dequeueStatefulViewForControllerClass:(Class)controllerClass
                               preferredSuperview:(UIView *)preferredSuperview
                                          context:(id)context;

- (void)enqueueStatefulView:(UIView *)view
         forControllerClass:(Class)controllerClass
                    context:(id)context;

@end
