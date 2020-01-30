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

#import <ComponentKit/CKMacros.h>
#import <ComponentKit/CKComponentProvider.h>
#import <ComponentKit/CKUpdateMode.h>

@protocol CKComponentHostingViewDelegate;
@protocol CKComponentSizeRangeProviding;

/** A view that renders a single component. */
@interface CKComponentHostingView<__covariant ModelType: id<NSObject>, __covariant ContextType: id<NSObject>> : UIView

/** Notified when the view's ideal size (measured by -sizeThatFits:) may have changed. */
@property (nonatomic, weak) id<CKComponentHostingViewDelegate> delegate;

/**
 Convenience initializer that uses default analytics listener
 @param componentProvider provider conforming to CKComponentProvider protocol.
 @param sizeRangeProvider sizing range provider conforming to CKComponentSizeRangeProviding.
 @see CKComponentProvider
 @see CKComponentSizeRangeProviding
 */
- (instancetype)initWithComponentProviderFunc:(CKComponent *(*)(ModelType model, ContextType context))componentProvider
                            sizeRangeProvider:(id<CKComponentSizeRangeProviding>)sizeRangeProvider;

/**
 This method is deprecated. Please use initWithComponentProviderFunc:sizeRangeProvider:
 */
- (instancetype)initWithComponentProvider:(Class<CKComponentProvider>)componentProvider
                        sizeRangeProvider:(id<CKComponentSizeRangeProviding>)sizeRangeProvider;

/** Updates the model used to render the component. */
- (void)updateModel:(ModelType)model mode:(CKUpdateMode)mode;

/** Updates the context used to render the component. */
- (void)updateContext:(ContextType)context mode:(CKUpdateMode)mode;

/** Appearance events to be funneled to the component tree. */
- (void)hostingViewWillAppear;
- (void)hostingViewDidDisappear;

- (instancetype)init CK_NOT_DESIGNATED_INITIALIZER_ATTRIBUTE;
- (instancetype)initWithFrame:(CGRect)frame CK_NOT_DESIGNATED_INITIALIZER_ATTRIBUTE;

@end

#endif
