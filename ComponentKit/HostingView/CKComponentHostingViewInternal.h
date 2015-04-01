/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant 
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKComponentHostingView.h>
#import <ComponentKit/CKDimension.h>

@class CKComponentLifecycleManager;

@interface CKComponentHostingView ()

@property (nonatomic, strong, readonly) UIView *containerView;
@property (nonatomic, readonly) CKSizeRange constrainedSize;
@property (nonatomic, readonly) CKComponentLifecycleManager *lifecycleManager;

- (instancetype)initWithLifecycleManager:(CKComponentLifecycleManager *)manager
                       sizeRangeProvider:(id<CKComponentSizeRangeProviding>)sizeRangeProvider
                                 context:(id<NSObject>)context;

@end
