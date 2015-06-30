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

typedef NS_ENUM(NSUInteger, CKComponentHostingViewUpdateType) {
  CKComponentHostingViewUpdateTypeNone = 0,
  CKComponentHostingViewUpdateTypeAsynchronous = 1,
  CKComponentHostingViewUpdateTypeSynchronous = 2,
};

@interface CKComponentHostingView () <CKComponentStateListener>
{
  Class<CKComponentProvider> _componentProvider;
  id<CKComponentSizeRangeProviding> _sizeRangeProvider;

  CKComponentScopeRoot *_scopeRoot;
  CKComponentStateUpdateMap _pendingStateUpdates;

  CKComponent *_component;
  CKComponentHostingViewUpdateType _componentNeedsUpdateType;
  CKComponentLayout _layout;

  NSSet *_mountedComponents;

  BOOL _scheduledAsynchronousComponentUpdate;
  BOOL _isSynchronouslyUpdatingComponent;
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
{
  if (self = [super initWithFrame:CGRectZero]) {
    _componentProvider = componentProvider;
    _sizeRangeProvider = sizeRangeProvider;
    _scopeRoot = [CKComponentScopeRoot rootWithListener:self];

    _containerView = [[CKComponentRootView alloc] initWithFrame:CGRectZero];
    [self addSubview:_containerView];

    _componentNeedsUpdateType = CKComponentHostingViewUpdateTypeSynchronous;
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
    [self _synchronouslyUpdateComponentIfNeeded];
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
  [self _synchronouslyUpdateComponentIfNeeded];
  const CKSizeRange constrainedSize = [_sizeRangeProvider sizeRangeForBoundingSize:size];
  return [_component layoutThatFits:constrainedSize parentSize:constrainedSize.max].size;
}

#pragma mark - Accessors

- (void)setModel:(id)model
{
  CKAssertMainThread();
  if (_model != model) {
    _model = model;
    [self _setNeedsUpdate:CKComponentHostingViewUpdateTypeSynchronous];
  }
}

- (void)setContext:(id<NSObject>)context
{
  CKAssertMainThread();
  if (_context != context) {
    _context = context;
    [self _setNeedsUpdate:CKComponentHostingViewUpdateTypeSynchronous];
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
  [self _setNeedsUpdate:tryAsynchronousUpdate ? CKComponentHostingViewUpdateTypeAsynchronous : CKComponentHostingViewUpdateTypeSynchronous];
}

#pragma mark - Private

- (void)_setNeedsUpdate:(CKComponentHostingViewUpdateType)updateType
{
  if (updateType <= _componentNeedsUpdateType) {
    return; // Never go backwards, e.g. from Sync to Async or Async to None.
  }

  _componentNeedsUpdateType = updateType;

  switch (updateType) {
    case CKComponentHostingViewUpdateTypeAsynchronous:
      [self _asynchronouslyUpdateComponentIfNeeded];
      break;
    case CKComponentHostingViewUpdateTypeSynchronous:
      [self setNeedsLayout];
      [_delegate componentHostingViewDidInvalidateSize:self];
      break;
    case CKComponentHostingViewUpdateTypeNone:
      break;
  }
}

- (void)_asynchronouslyUpdateComponentIfNeeded
{
  if (_scheduledAsynchronousComponentUpdate) {
    return;
  }
  _scheduledAsynchronousComponentUpdate = YES;

  // Wait until the end of the run loop so that if multiple async updates are triggered we don't thrash.
  dispatch_async(dispatch_get_main_queue(), ^{
    [self _scheduleAsynchronousUpdate];
  });
}

- (void)_scheduleAsynchronousUpdate
{
  if (_componentNeedsUpdateType != CKComponentHostingViewUpdateTypeAsynchronous) {
    // A synchronous update was either scheduled or completed, so we can skip the async update.
    _scheduledAsynchronousComponentUpdate = NO;
    return;
  }

  id<NSObject> modelCopy = _model;
  id<NSObject> contextCopy = _context;
  CKComponentScopeRoot *scopeRootCopy = _scopeRoot;
  auto stateUpdatesToApply = std::make_shared<const CKComponentStateUpdateMap>(_pendingStateUpdates);
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    const CKBuildComponentResult result = CKBuildComponent(scopeRootCopy, *stateUpdatesToApply, ^CKComponent *{
      return [_componentProvider componentForModel:modelCopy context:contextCopy];
    });
    dispatch_async(dispatch_get_main_queue(), ^{
      if (_componentNeedsUpdateType == CKComponentHostingViewUpdateTypeNone) {
        // A synchronous update snuck in and took care of it for us.
        return;
      }

      if (_model == modelCopy
          && _context == contextCopy
          && _scopeRoot == scopeRootCopy
          && _pendingStateUpdates.size() == stateUpdatesToApply->size()) {
        _pendingStateUpdates.clear();
        _component = result.component;
        _scopeRoot = result.scopeRoot;
        _componentNeedsUpdateType = CKComponentHostingViewUpdateTypeNone;
        _scheduledAsynchronousComponentUpdate = NO;
        [self setNeedsLayout];
        [_delegate componentHostingViewDidInvalidateSize:self];
      } else {
        [self _scheduleAsynchronousUpdate];
      }
    });
  });
}

- (void)_synchronouslyUpdateComponentIfNeeded
{
  if (_componentNeedsUpdateType != CKComponentHostingViewUpdateTypeSynchronous) {
    return;
  }

  if (_isSynchronouslyUpdatingComponent) {
    CKFailAssert(@"CKComponentHostingView is not re-entrant. This is called by -layoutSubviews, so ensure "
                 "that there is nothing that is triggering a nested call to -layoutSubviews.");
    return;
  } else {
    _isSynchronouslyUpdatingComponent = YES;
  }

  CKComponentStateUpdateMap stateUpdatesToApply = _pendingStateUpdates;
  _pendingStateUpdates.clear();
  const CKBuildComponentResult result = CKBuildComponent(_scopeRoot, stateUpdatesToApply, ^CKComponent *{
    return [_componentProvider componentForModel:_model context:_context];
  });
  _component = result.component;
  _scopeRoot = result.scopeRoot;
  _componentNeedsUpdateType = CKComponentHostingViewUpdateTypeNone;

  _isSynchronouslyUpdatingComponent = NO;
}

@end
