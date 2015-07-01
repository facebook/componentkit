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

  id<NSObject> _currentModel;
  id<NSObject> _currentContext;

  CKComponent *_component;
  BOOL _componentNeedsUpdate;
  CKUpdateMode _requestedUpdateMode;

  CKComponentLayout _mountedLayout;
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

    _componentNeedsUpdate = YES;
    _requestedUpdateMode = CKUpdateModeSynchronous;
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
    if (_mountedLayout.component != _component || !CGSizeEqualToSize(_mountedLayout.size, size)) {
      _mountedLayout = [_component layoutThatFits:{size, size} parentSize:size];
    }
    _mountedComponents = [CKMountComponentLayout(_mountedLayout, _containerView, _mountedComponents, nil) copy];
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

- (void)updateModel:(id<NSObject>)model mode:(CKUpdateMode)mode
{
  CKAssertMainThread();
  _currentModel = model;
  [self _setNeedsUpdateWithMode:mode];
}

- (void)updateContext:(id<NSObject>)context mode:(CKUpdateMode)mode
{
  CKAssertMainThread();
  _currentContext = context;
  [self _setNeedsUpdateWithMode:mode];
}

- (const CKComponentLayout &)mountedLayout
{
  return _mountedLayout;
}

#pragma mark - CKComponentStateListener

- (void)componentScopeHandleWithIdentifier:(CKComponentScopeHandleIdentifier)globalIdentifier
                            rootIdentifier:(CKComponentScopeRootIdentifier)rootIdentifier
                     didReceiveStateUpdate:(id (^)(id))stateUpdate
                                      mode:(CKUpdateMode)mode
{
  CKAssertMainThread();
  _pendingStateUpdates.insert({globalIdentifier, stateUpdate});
  [self _setNeedsUpdateWithMode:mode];
}

#pragma mark - Private

- (void)_setNeedsUpdateWithMode:(CKUpdateMode)mode
{
  if (_componentNeedsUpdate && _requestedUpdateMode == CKUpdateModeSynchronous) {
    return; // Already scheduled a synchronous update; nothing more to do.
  }

  _componentNeedsUpdate = YES;
  _requestedUpdateMode = mode;

  switch (mode) {
    case CKUpdateModeAsynchronous:
      [self _asynchronouslyUpdateComponentIfNeeded];
      break;
    case CKUpdateModeSynchronous:
      [self setNeedsLayout];
      [_delegate componentHostingViewDidInvalidateSize:self];
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
  if (_requestedUpdateMode != CKUpdateModeAsynchronous) {
    // A synchronous update was either scheduled or completed, so we can skip the async update.
    _scheduledAsynchronousComponentUpdate = NO;
    return;
  }

  id<NSObject> modelCopy = _currentModel;
  id<NSObject> contextCopy = _currentContext;
  CKComponentScopeRoot *scopeRootCopy = _scopeRoot;
  auto stateUpdatesToApply = std::make_shared<const CKComponentStateUpdateMap>(_pendingStateUpdates);
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    const CKBuildComponentResult result = CKBuildComponent(scopeRootCopy, *stateUpdatesToApply, ^CKComponent *{
      return [_componentProvider componentForModel:modelCopy context:contextCopy];
    });
    dispatch_async(dispatch_get_main_queue(), ^{
      if (!_componentNeedsUpdate) {
        // A synchronous update snuck in and took care of it for us.
        return;
      }

      if (_currentModel == modelCopy
          && _currentContext == contextCopy
          && _scopeRoot == scopeRootCopy
          && _pendingStateUpdates.size() == stateUpdatesToApply->size()) {
        _pendingStateUpdates.clear();
        _component = result.component;
        _scopeRoot = result.scopeRoot;
        _currentModel = modelCopy;
        _currentContext = contextCopy;
        _componentNeedsUpdate = NO;
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
  if (_componentNeedsUpdate == NO || _requestedUpdateMode == CKUpdateModeAsynchronous) {
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
    return [_componentProvider componentForModel:_currentModel context:_currentContext];
  });
  _component = result.component;
  _scopeRoot = result.scopeRoot;
  _componentNeedsUpdate = NO;

  _isSynchronouslyUpdatingComponent = NO;
}

@end
