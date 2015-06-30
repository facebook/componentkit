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
#import <ComponentKit/CKComponentLayout.h>

@class CKComponentLifecycleManager;

@interface CKComponentHostingView ()

@property (nonatomic, strong, readonly) UIView *containerView;

/** Returns the layout that's currently mounted. Main thread only. */
- (const CKComponentLayout &)mountedLayout;

@end
