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

#import <ComponentKit/CKMacros.h>
#import <ComponentKit/CKComponentProvider.h>

@protocol CKComponentHostingViewDelegate;
@protocol CKComponentSizeRangeProviding;

/** A view that renders a single component. */
@interface CKComponentHostingView : UIView

/** Notified when the view's ideal size (measured by -sizeThatFits:) may have changed. */
@property (nonatomic, weak) id<CKComponentHostingViewDelegate> delegate;

/** Designated initializer. */
- (instancetype)initWithComponentProvider:(Class<CKComponentProvider>)componentProvider
                        sizeRangeProvider:(id<CKComponentSizeRangeProviding>)sizeRangeProvider;

/**
 The model object used to generate the view's component.

 Setting a new model will synchronously construct and mount a new component tree and the
 delegate will be notified if there is a change in size.
 */
@property (nonatomic, strong) id<NSObject> model;

/**
 Setting a new context will synchronously construct and mount a new component tree and the
 delegate will be notified if there is a change in size.
 */
@property (nonatomic, strong) id<NSObject> context;

- (instancetype)init CK_NOT_DESIGNATED_INITIALIZER_ATTRIBUTE;
- (instancetype)initWithFrame:(CGRect)frame CK_NOT_DESIGNATED_INITIALIZER_ATTRIBUTE;

@end
