/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKComponentRootView.h>

#import <ComponentKit/CKComponentScopeTypes.h>
#import <ComponentKit/CKComponentBoundsAnimation.h>
#import <ComponentKit/CKComponentLayout.h>

@protocol CKAnalyticsListener;
@protocol CKComponentSizeRangeProviding;

/**
 * A container view which is used in a component hosting view that provides component mount
 * in additional to functionalities of a `CKComponentRootView`.
 */
@interface CKComponentHostingContainerView : CKComponentRootView

- (instancetype)initWithFrame:(CGRect)frame
              scopeIdentifier:(CKComponentScopeRootIdentifier)scopeIdentifier
            analyticsListener:(id<CKAnalyticsListener>)analyticsListener
            sizeRangeProvider:(id<CKComponentSizeRangeProviding>)sizeRangeProvider
          allowTapPassthrough:(BOOL)allowTapPassthrough NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame
          allowTapPassthrough:(BOOL)allowTapPassthrough NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (void)setRootLayout:(const CKComponentRootLayout &)rootLayout;
- (void)setBoundsAnimation:(const CKComponentBoundsAnimation &)boundsAnimation;
- (void)setComponent:(CKComponent *)component;

- (void)mount;

@end
