/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentHostingContainerView.h"

#import "CKComponentAttachController.h"
#import "CKComponentLayout.h"
#import "CKComponentRootLayoutProvider.h"
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

@interface CKComponentHostingContainerView () <CKComponentRootLayoutProvider>

@end

@implementation CKComponentHostingContainerView
{
  id<CKAnalyticsListener> _analyticsListener;
  id<CKComponentSizeRangeProviding> _sizeRangeProvider;
  CKComponentScopeRootIdentifier _scopeIdentifier;

  CKComponentRootLayout _rootLayout;
  CKComponentBoundsAnimation _boundsAnimation;
  CKComponent *_component;

  CKComponentAttachController *_attachController;
  Optional<CKComponentHostingContainerViewSizeCache> _sizeCache;
}

- (instancetype)initWithFrame:(CGRect)frame
              scopeIdentifier:(CKComponentScopeRootIdentifier)scopeIdentifier
            analyticsListener:(id<CKAnalyticsListener>)analyticsListener
            sizeRangeProvider:(id<CKComponentSizeRangeProviding>)sizeRangeProvider
          allowTapPassthrough:(BOOL)allowTapPassthrough
{
  if (self = [super initWithFrame:frame allowTapPassthrough:allowTapPassthrough]) {
    _scopeIdentifier = scopeIdentifier;
    _analyticsListener = analyticsListener;
    _sizeRangeProvider = sizeRangeProvider;
    _attachController = [CKComponentAttachController new];
  }
  return self;
}

- (void)didMoveToSuperview
{
  [super didMoveToSuperview];
  if (!self.superview) {
    // Detaching component layout will remove the reference of `CKComponentHostingContainerView` from attach controller and avoid retain cycle.
    [_attachController detachComponentLayoutWithScopeIdentifier:_scopeIdentifier];
  }
}

- (CGSize)sizeThatFits:(CGSize)size
{
  CKAssertMainThread();
  CKAssertNotNil(_component, @"`component` should not be nil before calculating size");
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

- (void)setRootLayout:(const CKComponentRootLayout &)rootLayout
{
  CKAssertMainThread();
  _rootLayout = rootLayout;
}

- (void)setBoundsAnimation:(const CKComponentBoundsAnimation &)boundsAnimation
{
  CKAssertMainThread();
  _boundsAnimation = boundsAnimation;
}

- (void)setComponent:(CKComponent *)component
{
  CKAssertMainThread();
  _component = component;
  _sizeCache = none;
}

- (void)mount
{
  CKAssertMainThread();
  CKAssertNotNil(_rootLayout.component(), @"`rootLayout` should be set before calling `mount`");
  CKComponentAttachControllerAttachComponentRootLayout(_attachController,
  {
    .layoutProvider = self,
    .scopeIdentifier = _scopeIdentifier,
    .boundsAnimation = _boundsAnimation,
    .view = self,
    .analyticsListener = _analyticsListener,
  });
  _boundsAnimation = {};
}

#pragma mark - CKComponentRootLayoutProvider

- (const CKComponentRootLayout &)rootLayout
{
  return _rootLayout;
}

@end
