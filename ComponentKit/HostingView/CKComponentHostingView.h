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

#import <ComponentKit/CKDefines.h>
#import <ComponentKit/CKComponentHostingViewDelegate.h>
#import <ComponentKit/CKComponentProvider.h>
#import <ComponentKit/CKComponentSizeRangeProviding.h>
#import <ComponentKit/CKUpdateMode.h>

NS_ASSUME_NONNULL_BEGIN

/** A view that renders a single component. */
NS_SWIFT_NAME(ComponentHostingView)
@interface CKComponentHostingView<__covariant ModelType: id<NSObject>, __covariant ContextType: id<NSObject>> : UIView

/** Notified when the view's ideal size (measured by -sizeThatFits:) may have changed. */
@property (nonatomic, weak) id<CKComponentHostingViewDelegate> delegate;

#if CK_NOT_SWIFT

/**
 Convenience initializer that uses default analytics listener
 @param componentProvider provider conforming to CKComponentProvider protocol.
 @param sizeRangeProvider sizing range provider conforming to CKComponentSizeRangeProviding.
 @see CKComponentProvider
 @see CKComponentSizeRangeProviding
 */
- (instancetype)initWithComponentProviderFunc:(CKComponent * _Nullable(* _Nonnull)(ModelType model, ContextType context))componentProvider
                            sizeRangeProvider:(id<CKComponentSizeRangeProviding>)sizeRangeProvider;

#else

typedef CKComponent * _Nullable(*CKComponentProviderFn)(ModelType _Nullable, ContextType _Nullable);

- (instancetype)initWithComponentProvider:(CKComponentProviderFn)componentProvider
                   sizeRangeProviderBlock:(CKComponentSizeRangeProviderBlock)sizeRangeProvider;

#endif

/** Updates the model used to render the component. */
- (void)updateModel:(ModelType _Nullable)model mode:(CKUpdateMode)mode;

/** Updates the context used to render the component. */
- (void)updateContext:(ContextType _Nullable)context mode:(CKUpdateMode)mode;

/** Appearance events to be funneled to the component tree. */
- (void)hostingViewWillAppear;
- (void)hostingViewDidDisappear;

/** Updates the accessibility status. */
- (void)updateAccessibilityStatus:(BOOL)accessibilityStatus mode:(CKUpdateMode)mode;

CK_INIT_UNAVAILABLE;

- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
