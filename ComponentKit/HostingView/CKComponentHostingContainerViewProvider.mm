/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentHostingContainerViewProvider.h"

#import <ComponentKit/CKAnalyticsListener.h>
#import <ComponentKit/CKCasting.h>
#import <ComponentKit/CKDelayedNonNull.h>
#import <ComponentKit/CKOptional.h>

#import <ComponentKit/CKComponentAttachControllerInternal.h>
#import <ComponentKit/CKComponentLayout.h>
#import <ComponentKit/CKComponentRootLayoutProvider.h>
#import <ComponentKit/CKComponentRootView.h>
#import <ComponentKit/CKComponentRootViewInternal.h>
#import <ComponentKit/CKComponentSizeRangeProviding.h>

using namespace CK;

struct CKComponentHostingContainerViewSizeCache {
  CKComponentHostingContainerViewSizeCache(const CKSizeRange constrainedSize,
                                           const CGSize computedSize)
  : _constrainedSize(constrainedSize), _computedSize(computedSize) {};

  Optional<CGSize> sizeForConstrainedSize(const CKSizeRange constrainedSize) const {
    return _constrainedSize == constrainedSize ? Optional<CGSize> {_computedSize} : none;
  }
private:
  CKSizeRange _constrainedSize;
  CGSize _computedSize;
};

@interface CKComponentHostingContainerLayoutProvider : NSObject <CKComponentRootLayoutProvider>

- (instancetype)initWithRootLayout:(const CKComponentRootLayout &)rootLayout;

@end

@interface CKComponentHostingContainerView : CKComponentRootView

- (void)setAnalyticsListener:(id<CKAnalyticsListener>)analyticsListener;
- (void)setSizeRangeProvider:(id<CKComponentSizeRangeProviding>)sizeRangeProvider;
- (void)setComponent:(CKComponent *)component;

@end


@implementation CKComponentHostingContainerViewProvider
{
  id<CKAnalyticsListener> _analyticsListener;
  CKComponentScopeRootIdentifier _scopeIdentifier;

  CKComponentHostingContainerLayoutProvider *_previousLayoutProvider;
  CKComponentHostingContainerLayoutProvider *_layoutProvider;
  CKComponentBoundsAnimation _boundsAnimation;

  CK::DelayedNonNull<CKComponentHostingContainerView *> _containerView;
  CKComponentAttachController *_attachController;
  BOOL _needsMount;
}

- (instancetype)initWithFrame:(CGRect)frame
              scopeIdentifier:(CKComponentScopeRootIdentifier)scopeIdentifier
            analyticsListener:(id<CKAnalyticsListener>)analyticsListener
            sizeRangeProvider:(id<CKComponentSizeRangeProviding>)sizeRangeProvider
          allowTapPassthrough:(BOOL)allowTapPassthrough
{
  if (self = [super init]) {
    _scopeIdentifier = scopeIdentifier;
    _analyticsListener = analyticsListener;

    _attachController = [CKComponentAttachController new];

    _containerView = CK::makeNonNull([CKComponentHostingContainerView new]);
    [_containerView setFrame:frame];
    [_containerView setAnalyticsListener:analyticsListener];
    [_containerView setSizeRangeProvider:sizeRangeProvider];
    [_containerView setAllowTapPassthrough:allowTapPassthrough];
  }
  return self;
}

- (UIView *)containerView
{
  return _containerView;
}

- (void)setRootLayout:(const CKComponentRootLayout &)rootLayout
{
  CKAssertMainThread();
  // In the case when layout has no chance to be mounted, we need to make sure the correct previous layout is still retained.
  _previousLayoutProvider = _previousLayoutProvider ?: _layoutProvider;
  _layoutProvider = [[CKComponentHostingContainerLayoutProvider alloc] initWithRootLayout:rootLayout];
  _needsMount = YES;
}

- (void)setBoundsAnimation:(const CKComponentBoundsAnimation &)boundsAnimation
{
  CKAssertMainThread();
  _boundsAnimation = boundsAnimation;
}

- (void)setComponent:(CKComponent *)component
{
  CKAssertMainThread();
  [_containerView setComponent:component];
}

- (void)mount
{
  CKAssertMainThread();
  if (!_needsMount) {
    return;
  }
  _needsMount = NO;
  if (!_layoutProvider) {
    [_attachController detachComponentLayoutWithScopeIdentifier:_scopeIdentifier];
    return;
  }
  CKComponentAttachControllerAttachComponentRootLayout(_attachController,
  {
    .layoutProvider = _layoutProvider,
    .scopeIdentifier = _scopeIdentifier,
    .boundsAnimation = _boundsAnimation,
    .view = _containerView,
    .analyticsListener = _analyticsListener,
  });
  _previousLayoutProvider = nil;
  _boundsAnimation = {};
}

- (void)unmount
{
  CKAssertMainThread();
  [_attachController detachComponentLayoutWithScopeIdentifier:_scopeIdentifier];
}

@end

@implementation CKComponentHostingContainerLayoutProvider
{
  CKComponentRootLayout _rootLayout;
}

- (instancetype)initWithRootLayout:(const CKComponentRootLayout &)rootLayout
{
  if (self = [super init]) {
    _rootLayout = rootLayout;
  }
  return self;
}

- (const CKComponentRootLayout &)rootLayout
{
  return _rootLayout;
}

@end

@implementation CKComponentHostingContainerView
{
  id<CKAnalyticsListener> _analyticsListener;
  id<CKComponentSizeRangeProviding> _sizeRangeProvider;
  CKComponent *_component;
  Optional<CKComponentHostingContainerViewSizeCache> _sizeCache;
}

- (void)setAnalyticsListener:(id<CKAnalyticsListener>)analyticsListener
{
  _analyticsListener = analyticsListener;
}

- (void)setSizeRangeProvider:(id<CKComponentSizeRangeProviding>)sizeRangeProvider
{
  _sizeRangeProvider = sizeRangeProvider;
}

- (void)setComponent:(CKComponent *)component
{
  CKAssertMainThread();
  _component = component;
  _sizeCache = none;
}

- (CGSize)sizeThatFits:(CGSize)size
{
  CKAssertMainThread();
  if (!_component) {
    return CGSizeZero;
  }
  const CKSizeRange constrainedSize = [_sizeRangeProvider sizeRangeForBoundingSize:size];
  const auto computeSize = [&]() {
    return CKComputeRootComponentLayout(_component,
                                        constrainedSize,
                                        _analyticsListener).size();
  };
  const auto computedSize = _sizeCache.flatMap([&](const auto &sizeCache) {
    return sizeCache.sizeForConstrainedSize(constrainedSize);
  }).valueOr(computeSize);
  _sizeCache = CKComponentHostingContainerViewSizeCache {constrainedSize, computedSize};
  return computedSize;
}

@end
