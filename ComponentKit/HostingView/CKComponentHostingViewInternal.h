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

#import <ComponentKit/CKBuildComponent.h>
#import <ComponentKit/CKComponentHostingView.h>
#import <ComponentKit/CKComponentHostingViewProtocol.h>
#import <ComponentKit/CKDimension.h>
#import <ComponentKit/CKComponentLayout.h>
#import <ComponentKit/CKComponentScopeRoot.h>
#import <ComponentKit/CKComponentScopeTypes.h>
#import <ComponentKit/CKGlobalConfig.h>
#import <ComponentKit/CKInspectableView.h>
#import <ComponentKit/CKOptional.h>

#import <unordered_set>

@protocol CKAnalyticsListener;

struct CKComponentHostingViewOptions {
  /// If set to YES, allows taps to pass though this hosting view to views behind it. Default NO.
  BOOL allowTapPassthrough;
  /// A initial size that will be used for hosting view before first generation of component is created.
  /// Specifying a initial size enables the ability to handle the first model/context update asynchronously.
  CK::Optional<CGSize> initialSize;
};

@interface CKComponentHostingView<__covariant ModelType: id<NSObject>, __covariant ContextType: id<NSObject>> () <CKComponentHostingViewProtocol>

- (instancetype)initWithComponentProviderFunc:(CKComponent *(*)(ModelType model, ContextType context))componentProvider
                            sizeRangeProvider:(id<CKComponentSizeRangeProviding>)sizeRangeProvider
                          componentPredicates:(const std::unordered_set<CKComponentPredicate> &)componentPredicates
                componentControllerPredicates:(const std::unordered_set<CKComponentControllerPredicate> &)componentControllerPredicates
                            analyticsListener:(id<CKAnalyticsListener>)analyticsListener
                                      options:(const CKComponentHostingViewOptions &)options NS_DESIGNATED_INITIALIZER;

@property (nonatomic, strong, readonly) UIView *containerView;

/** Applies a result from a component built outside the hosting view. Main thread only. */
- (void)applyResult:(const CKBuildComponentResult &)result;

/**
 Calling this method will re-generate the underlying component hierarchy without component reuse.
 Use case could be reloading a hosting view when `CKComponentContext` should be updated.
 */
- (void)reloadWithMode:(CKUpdateMode)mode;

@end

#endif
