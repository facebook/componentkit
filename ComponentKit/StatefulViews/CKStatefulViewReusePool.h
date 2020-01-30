/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKDefines.h>

#if CK_NOT_SWIFT

#import <UIKit/UIKit.h>

/**
 Should return YES if the stateful view can be reused, or NO to block reuse of the stateful view.
 */
typedef BOOL (^CKStatefulViewReusePoolPendingMayRelinquishBlock)(void);

@interface CKStatefulViewReusePool : NSObject

+ (instancetype)sharedPool;

- (UIView *)dequeueStatefulViewForControllerClass:(Class)controllerClass
                               preferredSuperview:(UIView *)preferredSuperview
                                          context:(id)context;

- (void)enqueueStatefulView:(UIView *)view
         forControllerClass:(Class)controllerClass
                    context:(id)context
         mayRelinquishBlock:(CKStatefulViewReusePoolPendingMayRelinquishBlock)mayRelinquishBlock;

@end

#endif
