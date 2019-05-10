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
#import <ComponentKit/CKUpdateMode.h>

@protocol CKComponentHostingViewDelegate;
@protocol CKComponentSizeRangeProviding;
@protocol CKAnalyticsListener;

/** A view that renders a single component. */
@interface CKComponentHostingView : UIView

/** Notified when the view's ideal size (measured by -sizeThatFits:) may have changed. */
@property (nonatomic, weak) id<CKComponentHostingViewDelegate> delegate;

/**
 Convenience initializer that uses default analytics listener
 @param componentProvider provider conforming to CKComponentProvider protocol.
 @param sizeRangeProvider sizing range provider conforming to CKComponentSizeRangeProviding.
 @see CKComponentProvider
 @see CKComponentSizeRangeProviding
 */
- (instancetype)initWithComponentProviderFunc:(CKComponentProviderFunc)componentProvider
                            sizeRangeProvider:(id<CKComponentSizeRangeProviding>)sizeRangeProvider;

/**
 @param componentProvider provider conforming to CKComponentProvider protocol.
 @param sizeRangeProvider sizing range provider conforming to CKComponentSizeRangeProviding.
 @param analyticsListener listener conforming to AnalyticsListener will be used to get component lifecycle callbacks for logging
 @see CKComponentProvider
 @see CKComponentSizeRangeProviding
*/
- (instancetype)initWithComponentProviderFunc:(CKComponentProviderFunc)componentProvider
                            sizeRangeProvider:(id<CKComponentSizeRangeProviding>)sizeRangeProvider
                            analyticsListener:(id<CKAnalyticsListener>)analyticsListener;

/**
 Create a fixed size hosting view. A fixed size hosting view could have better performance because it doesn't need to
 calculate the size of hosting view based on its component. Component layout could also be done on the background thread
 when there is a fixed size.
 @param componentProvider provider function. @see CKComponentProviderFunc
 @param size a fixed size that will be used for hosting view.
 */
- (instancetype)initWithComponentProviderFunc:(CKComponentProviderFunc)componentProvider
                                         size:(CGSize)size;

/**
 Create a fixed size hosting view. A fixed size hosting view could have better performance because it doesn't need to
 calculate the size of hosting view based on its component. Component layout could also be done on the background thread
 when there is a fixed size.
 @param componentProvider provider function. @see CKComponentProviderFunc
 @param size a fixed size that will be used for hosting view.
 @param analyticsListener listener conforming to AnalyticsListener will be used to get component lifecycle callbacks for logging
 */
- (instancetype)initWithComponentProviderFunc:(CKComponentProviderFunc)componentProvider
                                         size:(CGSize)size
                            analyticsListener:(id<CKAnalyticsListener>)analyticsListener;

/**
 This method is deprecated. Please use initWithComponentProviderFunc:sizeRangeProvider:
 */
- (instancetype)initWithComponentProvider:(Class<CKComponentProvider>)componentProvider
                        sizeRangeProvider:(id<CKComponentSizeRangeProviding>)sizeRangeProvider;

/**
 This method is deprecated. Please use initWithComponentProviderFunc:sizeRangeProvider:analyticsListener:
 */
- (instancetype)initWithComponentProvider:(Class<CKComponentProvider>)componentProvider
                        sizeRangeProvider:(id<CKComponentSizeRangeProviding>)sizeRangeProvider
                        analyticsListener:(id<CKAnalyticsListener>)analyticsListener;


/** Updates the model used to render the component. */
- (void)updateModel:(id<NSObject>)model mode:(CKUpdateMode)mode;

/** Updates the context used to render the component. */
- (void)updateContext:(id<NSObject>)context mode:(CKUpdateMode)mode;

/** Appearance events to be funneled to the component tree. */
- (void)hostingViewWillAppear;
- (void)hostingViewDidDisappear;

- (instancetype)init CK_NOT_DESIGNATED_INITIALIZER_ATTRIBUTE;
- (instancetype)initWithFrame:(CGRect)frame CK_NOT_DESIGNATED_INITIALIZER_ATTRIBUTE;

@end
