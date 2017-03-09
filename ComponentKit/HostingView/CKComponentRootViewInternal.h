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

#import <ComponentKit/CKComponentRootView.h>

/**
 @param rootView The CKComponentRootView instance being hit-tested.
 @param point The hit point in rootView's local coordinate system.
 @param event The event sent with the hit test.
 @param hitView The view that would be returned by the default hit-testing implementation.
 */
typedef UIView *(^CKComponentRootViewHitTestHook)(UIView *rootView, CGPoint point, UIEvent *event, UIView *hitView);

@interface CKComponentRootView ()

/**
 Exposes the ability to supplement the hitTest for the root view used in each CKComponentHostingView or
 UICollectionViewCell within a CKCollectionViewDataSource.

 Each hook will be called in the order they were registered. If any hook returns a view, that will override the return
 value of the view's -hitTest:withEvent:. If no hook returns a view, then the super implementation will be invoked.
 */
+ (void)addHitTestHook:(CKComponentRootViewHitTestHook)hook;

/** Returns an array of all registered hit test hooks. */
+ (NSArray *)hitTestHooks;

@end
