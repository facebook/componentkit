/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant 
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentHostingView.h"
#import "CKComponentHostingViewInternal.h"

#import <ComponentKit/CKAssert.h>
#import <ComponentKit/CKMacros.h>

#import "CKComponentAnimation.h"
#import "CKComponentHostingViewDelegate.h"
#import "CKComponentLifecycleManager.h"
#import "CKComponentLifecycleManager_Private.h"
#import "CKComponentRootView.h"
#import "CKComponentSizeRangeProviding.h"

@interface CKComponentHostingView () <CKComponentLifecycleManagerDelegate>
{
  CKComponentLifecycleManager *_lifecycleManager;
  id<CKComponentSizeRangeProviding> _sizeRangeProvider;
  CKComponentRootView *_containerView;
  BOOL _isUpdating;
  id<NSObject> _context;
}
@end

@implementation CKComponentHostingView

#pragma mark - Lifecycle

- (instancetype)initWithFrame:(CGRect)frame
{
  CK_NOT_DESIGNATED_INITIALIZER();
}

- (instancetype)initWithLifecycleManager:(CKComponentLifecycleManager *)manager
                       sizeRangeProvider:(id<CKComponentSizeRangeProviding>)sizeRangeProvider
                                 context:(id<NSObject>)context
{
  if (self = [super initWithFrame:CGRectZero]) {
    // Injected dependencies
    _sizeRangeProvider = sizeRangeProvider;
    _context = context;
    
    // Internal dependencies
    _lifecycleManager = manager;
    _lifecycleManager.delegate = self;
    
    _containerView = [[CKComponentRootView alloc] initWithFrame:CGRectZero];
    [self addSubview:_containerView];
  }
  return self;
}

- (instancetype)initWithComponentProvider:(Class<CKComponentProvider>)componentProvider
                        sizeRangeProvider:(id<CKComponentSizeRangeProviding>)sizeRangeProvider
                                  context:(id<NSObject>)context
{
  CKComponentLifecycleManager *manager = [[CKComponentLifecycleManager alloc] initWithComponentProvider:componentProvider sizeRangeProvider:sizeRangeProvider];
  return [self initWithLifecycleManager:manager sizeRangeProvider:sizeRangeProvider context:context];
}

- (void)dealloc
{
  [_lifecycleManager detachFromView];
}

#pragma mark - Layout

- (void)layoutSubviews
{
  [super layoutSubviews];
  _containerView.frame = self.bounds;

  if (_model && !CGRectIsEmpty(self.bounds)) {
    [self _update];

    if (![_lifecycleManager isAttachedToView]) {
      [_lifecycleManager attachToView:_containerView];
    }
  }
}

- (CGSize)sizeThatFits:(CGSize)size
{
  CKSizeRange constrainedSize = [_sizeRangeProvider sizeRangeForBoundingSize:size];
  CKComponentLayout layout = [_lifecycleManager layoutForModel:_model constrainedSize:constrainedSize context:_context];
  return layout.size;
}

#pragma mark - Accessors

- (void)setModel:(id)model
{
  if (_model != model) {
    _model = model;
    CKAssertNotNil(_model, @"Model can not be nil.");

    [self setNeedsLayout];
  }
}

- (void)setContext:(id<NSObject>)context
{
  if (_context != context) {
    _context = context;
    [self setNeedsLayout];
  }
}

- (UIView *)containerView
{
  return _containerView;
}

#pragma mark - CKComponentLifecycleManagerDelegate

- (void)componentLifecycleManager:(CKComponentLifecycleManager *)manager
       sizeDidChangeWithAnimation:(const CKComponentBoundsAnimation &)animation
{
  [_delegate componentHostingViewDidInvalidateSize:self];
}

#pragma mark - Private

- (void)_update
{
  if (_isUpdating) {
    CKFailAssert(@"CKComponentHostingView -_update is not re-entrant. This is called by -layoutSubviews, so ensure that there is nothing that is triggering a nested call to -layoutSubviews. This call will be a no-op in production.");
    return;
  } else {
    _isUpdating = YES;
  }

  const CGRect bounds = self.bounds;
  CKComponentLifecycleManagerState state = [_lifecycleManager prepareForUpdateWithModel:_model constrainedSize:CKSizeRange(bounds.size, bounds.size) context:_context];
  [_lifecycleManager updateWithState:state];

  _isUpdating = NO;
}

@end
