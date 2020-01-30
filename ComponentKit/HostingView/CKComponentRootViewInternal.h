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

#import <ComponentKit/CKComponentRootView.h>
#import <ComponentKit/CKInspectableView.h>
#import <ComponentKit/CKNonNull.h>

/**
 @param rootView The CKComponentRootView instance being hit-tested.
 @param point The hit point in rootView's local coordinate system.
 @param event The event sent with the hit test.
 @param hitView The view that would be returned by the default hit-testing implementation.
 */
typedef UIView *(^CKComponentRootViewHitTestHook)(UIView *rootView, CGPoint point, UIEvent *event, UIView *hitView);

@interface CKComponentRootView () <CKInspectableView>

/**
 Allow tap passthrough the root view.
 */
- (void)setAllowTapPassthrough:(BOOL)allowTapPassthrough;

/**
 Called before root view is pushed into `CK::Component::RootViewPool`.
 */
- (void)willEnterViewPool NS_REQUIRES_SUPER;

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

/**
 This should be implemented for object that hosts a `CKComponentRootView`.
 A `CKComponentRootViewHost` provides categorization and read/write access of root view.
 */
@protocol CKComponentRootViewHost <NSObject>

/**
 Category of root view. This can be used as category for `CK::Component::RootViewPool`.
 */
@property (nonatomic, copy) NSString *rootViewCategory;

/**
 The underlying `CKComponentRootView`.
 */
@property (nonatomic, strong) CKComponentRootView *rootView;

/**
 Create a new root view which will be attached to this `CKComponentRootViewHost`.
 */
- (CK::NonNull<CKComponentRootView *>)createRootView;

/**
 Called before root view enters view pool.
 */
- (void)rootViewWillEnterViewPool;

@end

#endif
