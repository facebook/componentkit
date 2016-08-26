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
#import "CKComponentLayout.h"
#import "CKComponentRootView.h"
#import "CKComponentScopeRoot.h"
#import "CKComponentSizeRangeProviding.h"
#import "CKComponentSubclass.h"

struct CKComponentHostingViewInputs {
  CKComponentScopeRoot *scopeRoot;
  id<NSObject> model;
  id<NSObject> context;
  CKComponentStateUpdateMap stateUpdates;

  bool operator==(const CKComponentHostingViewInputs &i) const {
    return scopeRoot == i.scopeRoot && model == i.model && context == i.context && stateUpdates == i.stateUpdates;
  };
};

@interface CKComponentHostingView () <CKComponentStateListener>
{
  Class<CKComponentProvider> _componentProvider;
  id<CKComponentSizeRangeProviding> _sizeRangeProvider;

  CKComponentHostingViewInputs _pendingInputs;

  CKComponent *_component;
  BOOL _componentNeedsUpdate;
  CKUpdateMode _requestedUpdateMode;

  CKComponentLayout _mountedLayout;
  NSSet *_mountedComponents;

  BOOL _scheduledAsynchronousComponentUpdate;
  BOOL _isSynchronouslyUpdatingComponent;
  BOOL _isMountingComponent;
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
    _pendingInputs = {.scopeRoot = [CKComponentScopeRoot rootWithListener:self]};

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

  // It is possible for a view change due to mounting to trigger a re-layout of the entire screen. This can
  // synchronously call layoutIfNeeded on this view, which could cause a re-entrant component mount, which we want
  // to avoid.
  if (!_isMountingComponent) {
    _isMountingComponent = YES;
    _containerView.frame = self.bounds;

    [self _synchronouslyUpdateComponentIfNeeded];
    const CGSize size = self.bounds.size;
    if (_mountedLayout.component != _component || !CGSizeEqualToSize(_mountedLayout.size, size)) {
      _mountedLayout = CKComputeRootComponentLayout(_component, {size, size});
    }
    _mountedComponents = [CKMountComponentLayout(_mountedLayout, _containerView, _mountedComponents, nil) copy];
    _isMountingComponent = NO;
  }
}

- (CGSize)sizeThatFits:(CGSize)size
{
  CKAssertMainThread();
  [self _synchronouslyUpdateComponentIfNeeded];
  const CKSizeRange constrainedSize = [_sizeRangeProvider sizeRangeForBoundingSize:size];
  return CKComputeRootComponentLayout(_component, constrainedSize).size;
}

#pragma mark - Accessors

- (void)updateModel:(id<NSObject>)model mode:(CKUpdateMode)mode
{
  CKAssertMainThread();
  _pendingInputs.model = model;
  [self _setNeedsUpdateWithMode:mode];
}

- (void)updateContext:(id<NSObject>)context mode:(CKUpdateMode)mode
{
  CKAssertMainThread();
  _pendingInputs.context = context;
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
  _pendingInputs.stateUpdates.insert({globalIdentifier, stateUpdate});
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

  const auto inputs = std::make_shared<const CKComponentHostingViewInputs>(_pendingInputs);
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    const auto result = std::make_shared<const CKBuildComponentResult>(CKBuildComponent(
      inputs->scopeRoot,
      inputs->stateUpdates,
      ^{ return [_componentProvider componentForModel:inputs->model context:inputs->context]; }
    ));
    dispatch_async(dispatch_get_main_queue(), ^{
      if (!_componentNeedsUpdate) {
        // A synchronous update snuck in and took care of it for us.
        _scheduledAsynchronousComponentUpdate = NO;
        return;
      }

      // If the inputs haven't changed, apply the result; otherwise, retry.
      if (_pendingInputs == *inputs) {
        _scheduledAsynchronousComponentUpdate = NO;
        [self _applyResult:*result];
        [self setNeedsLayout];
        [_delegate componentHostingViewDidInvalidateSize:self];
      } else {
        [self _scheduleAsynchronousUpdate];
      }
    });
  });
}

- (void)_applyResult:(const CKBuildComponentResult &)result
{
  _pendingInputs.scopeRoot = result.scopeRoot;
  _pendingInputs.stateUpdates = {};
  _component = result.component;
  _componentNeedsUpdate = NO;
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
  }

  _isSynchronouslyUpdatingComponent = YES;
  [self _applyResult:CKBuildComponent(_pendingInputs.scopeRoot, _pendingInputs.stateUpdates, ^CKComponent *{
    return [_componentProvider componentForModel:_pendingInputs.model context:_pendingInputs.context];
  })];
  _isSynchronouslyUpdatingComponent = NO;
}

@end
