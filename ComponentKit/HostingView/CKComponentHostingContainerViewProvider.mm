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

#import "CKComponentAttachController.h"
#import "CKComponentLayout.h"
#import "CKComponentRootLayoutProvider.h"
#import "CKComponentRootView.h"
#import "CKComponentRootViewInternal.h"
#import "CKComponentSizeRangeProviding.h"
#import "CKOptional.h"

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

- (instancetype)initWithFrame:(CGRect)frame
            analyticsListener:(id<CKAnalyticsListener>)analyticsListener
            sizeRangeProvider:(id<CKComponentSizeRangeProviding>)sizeRangeProvider
          allowTapPassthrough:(BOOL)allowTapPassthrough;

- (void)setComponent:(CKComponent *)component;

@end

@implementation CKComponentHostingContainerViewProvider
{
  id<CKAnalyticsListener> _analyticsListener;
  CKComponentScopeRootIdentifier _scopeIdentifier;

  CKComponentHostingContainerLayoutProvider *_previousLayoutProvider;
  CKComponentHostingContainerLayoutProvider *_layoutProvider;
  CKComponentBoundsAnimation _boundsAnimation;

  CKComponentHostingContainerView *_containerView;
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
    _containerView = [[CKComponentHostingContainerView alloc]
                      initWithFrame:frame
                      analyticsListener:analyticsListener
                      sizeRangeProvider:sizeRangeProvider
                      allowTapPassthrough:allowTapPassthrough];
    _attachController = [CKComponentAttachController new];
  }
  return self;
}

- (void)setRootLayout:(const CKComponentRootLayout &)rootLayout
{
  CKAssertMainThread();
  _previousLayoutProvider = _layoutProvider;
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

- (instancetype)initWithFrame:(CGRect)frame
            analyticsListener:(id<CKAnalyticsListener>)analyticsListener
            sizeRangeProvider:(id<CKComponentSizeRangeProviding>)sizeRangeProvider
          allowTapPassthrough:(BOOL)allowTapPassthrough
{
  if (self = [super initWithFrame:frame]) {
    _analyticsListener = analyticsListener;
    _sizeRangeProvider = sizeRangeProvider;
    [self setAllowTapPassthrough:allowTapPassthrough];
  }
  return self;
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
