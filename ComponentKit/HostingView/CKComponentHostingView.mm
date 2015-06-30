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
#import "CKComponentRootView.h"
#import "CKComponentScopeRoot.h"
#import "CKComponentSizeRangeProviding.h"
#import "CKComponentSubclass.h"

@interface CKComponentHostingView () <CKComponentStateListener>
{
  Class<CKComponentProvider> _componentProvider;
  id<CKComponentSizeRangeProviding> _sizeRangeProvider;

  CKComponentScopeRoot *_scopeRoot;
  CKComponentStateUpdateMap _pendingStateUpdates;

  CKComponent *_component;
  BOOL _componentNeedsUpdate;
  CKComponentLayout _layout;

  NSSet *_mountedComponents;

  BOOL _isUpdating;
}
@end

@implementation CKComponentHostingView

#pragma mark - Lifecycle

- (instancetype)initWithFrame:(CGRect)frame
{
  CK_NOT_DESIGNATED_INITIALIZER();
}

- (instancetype)initWithComponentProvider:(Class<CKComponentProvider>)componentProvider
                        sizeRangeProvider:(id<CKComponentSizeRangeProviding>)sizeRangeProvider
                                  context:(id<NSObject>)context
{
  if (self = [super initWithFrame:CGRectZero]) {
    _componentProvider = componentProvider;
    _sizeRangeProvider = sizeRangeProvider;
    _context = context;
    _scopeRoot = [CKComponentScopeRoot rootWithListener:self];

    _containerView = [[CKComponentRootView alloc] initWithFrame:CGRectZero];
    [self addSubview:_containerView];

    _componentNeedsUpdate = YES;
  }
  return self;
}

- (void)dealloc
{
  CKAssertMainThread(); // UIKit should guarantee this
  CKUnmountComponents(_mountedComponents);
}

#pragma mark - Layout

- (void)layoutSubviews
{
  CKAssertMainThread();
  [super layoutSubviews];
  _containerView.frame = self.bounds;

  if (!CGRectIsEmpty(self.bounds)) {
    [self _updateComponentIfNeeded];
    const CGSize size = self.bounds.size;
    if (_layout.component != _component || !CGSizeEqualToSize(_layout.size, size)) {
      _layout = [_component layoutThatFits:{size, size} parentSize:size];
    }
    _mountedComponents = [CKMountComponentLayout(_layout, _containerView, _mountedComponents, nil) copy];
  }
}

- (CGSize)sizeThatFits:(CGSize)size
{
  CKAssertMainThread();
  [self _updateComponentIfNeeded];
  const CKSizeRange constrainedSize = [_sizeRangeProvider sizeRangeForBoundingSize:size];
  return [_component layoutThatFits:constrainedSize parentSize:constrainedSize.max].size;
}

#pragma mark - Accessors

- (void)setModel:(id)model
{
  CKAssertMainThread();
  if (_model != model) {
    _model = model;
    [self _setComponentNeedsUpdate];
  }
}

- (void)setContext:(id<NSObject>)context
{
  CKAssertMainThread();
  if (_context != context) {
    _context = context;
    [self _setComponentNeedsUpdate];
  }
}

- (const CKComponentLayout &)mountedLayout
{
  return _layout;
}

#pragma mark - CKComponentStateListener

- (void)componentScopeHandleWithIdentifier:(CKComponentScopeHandleIdentifier)globalIdentifier
                            rootIdentifier:(CKComponentScopeRootIdentifier)rootIdentifier
                     didReceiveStateUpdate:(id (^)(id))stateUpdate
                     tryAsynchronousUpdate:(BOOL)tryAsynchronousUpdate
{
  CKAssertMainThread();
  _pendingStateUpdates.insert({globalIdentifier, stateUpdate});
  [self _setComponentNeedsUpdate];
}

#pragma mark - Private

- (void)_setComponentNeedsUpdate
{
  if (!_componentNeedsUpdate) { // Avoid thrashing delegate
    _componentNeedsUpdate = YES;
    [self setNeedsLayout];
    [_delegate componentHostingViewDidInvalidateSize:self];
  }
}

- (void)_updateComponentIfNeeded
{
  if (!_componentNeedsUpdate) {
    return;
  }

  if (_isUpdating) {
    CKFailAssert(@"CKComponentHostingView -_update is not re-entrant. This is called by -layoutSubviews, so ensure "
                 "that there is nothing that is triggering a nested call to -layoutSubviews. "
                 "This call will be a no-op in production.");
    return;
  } else {
    _isUpdating = YES;
  }

  CKComponentStateUpdateMap stateUpdatesToApply = _pendingStateUpdates;
  _pendingStateUpdates.clear();
  const CKBuildComponentResult result = CKBuildComponent(_scopeRoot, stateUpdatesToApply, ^CKComponent *{
    return [_componentProvider componentForModel:_model context:_context];
  });
  _component = result.component;
  _scopeRoot = result.scopeRoot;
  _componentNeedsUpdate = NO;

  _isUpdating = NO;
}

@end
