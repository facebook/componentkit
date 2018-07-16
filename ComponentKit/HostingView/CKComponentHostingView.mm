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

#import "CKAnimationApplicator.h"
#import "CKBuildComponent.h"
#import "CKComponentAnimation.h"
#import "CKComponentController.h"
#import "CKComponentDebugController.h"
#import "CKComponentHostingViewDelegate.h"
#import "CKComponentLayout.h"
#import "CKComponentRootViewInternal.h"
#import "CKComponentScopeRoot.h"
#import "CKComponentScopeRootFactory.h"
#import "CKComponentSizeRangeProviding.h"
#import "CKComponentSubclass.h"
#import "CKComponentControllerEvents.h"
#import "CKComponentEvents.h"

struct CKComponentHostingViewInputs {
  CKComponentScopeRoot *scopeRoot;
  id<NSObject> model;
  id<NSObject> context;
  CKComponentStateUpdateMap stateUpdates;

  bool operator==(const CKComponentHostingViewInputs &i) const {
    return scopeRoot == i.scopeRoot && model == i.model && context == i.context && stateUpdates == i.stateUpdates;
  };
};

@interface CKComponentHostingView () <CKComponentStateListener, CKComponentDebugReflowListener>
{
  Class<CKComponentProvider> _componentProvider;
  id<CKComponentSizeRangeProviding> _sizeRangeProvider;

  CKComponentHostingViewInputs _pendingInputs;

  CKComponentBoundsAnimation _boundsAnimation;
  BOOL _enableComponentAnimations;
  CKComponentAnimations _componentAnimations;
  std::unique_ptr<CK::AnimationApplicator<CK::ComponentAnimationsController>> _animationApplicator;

  CKComponent *_component;
  BOOL _componentNeedsUpdate;
  CKUpdateMode _requestedUpdateMode;

  CKComponentRootLayout _mountedRootLayout;
  NSSet *_mountedComponents;

  BOOL _scheduledAsynchronousComponentUpdate;
  BOOL _scheduledAsynchronousBuildAndLayoutUpdate;
  BOOL _isSynchronouslyUpdatingComponent;
  BOOL _isMountingComponent;
  BOOL _unifyBuildAndLayout;
  BOOL _allowTapPassthrough;
}
@end

@implementation CKComponentHostingView

static id<CKAnalyticsListener> sDefaultAnalyticsListener;

// Default analytics listener is only set/read from main queue to avoid dealing with concurrency
// This should happen very rarely, ideally once per app run, so using main for that is ok
+ (void)setDefaultAnalyticsListener:(id<CKAnalyticsListener>) defaultListener
{
  CKAssertMainThread();
  CKAssertNil(sDefaultAnalyticsListener, @"Default analytics listener already exists - you shouldn't set it more then once!");
  sDefaultAnalyticsListener = defaultListener;
}

#pragma mark - Lifecycle

- (instancetype)initWithFrame:(CGRect)frame
{
  CK_NOT_DESIGNATED_INITIALIZER();
}

- (instancetype)initWithComponentProvider:(Class<CKComponentProvider>)componentProvider
                        sizeRangeProvider:(id<CKComponentSizeRangeProviding>)sizeRangeProvider
{
  return [self initWithComponentProvider:componentProvider
                       sizeRangeProvider:sizeRangeProvider
                       analyticsListener:nil];
}

- (instancetype)initWithComponentProvider:(Class<CKComponentProvider>)componentProvider
                        sizeRangeProvider:(id<CKComponentSizeRangeProviding>)sizeRangeProvider
                        analyticsListener:(id<CKAnalyticsListener>)analyticsListener
{
  return [self initWithComponentProvider:componentProvider
                       sizeRangeProvider:sizeRangeProvider
                     componentPredicates:{}
           componentControllerPredicates:{}
                       analyticsListener:analyticsListener
                                 options:{}];
}

- (instancetype)initWithComponentProvider:(Class<CKComponentProvider>)componentProvider
                        sizeRangeProvider:(id<CKComponentSizeRangeProviding>)sizeRangeProvider
                      componentPredicates:(const std::unordered_set<CKComponentPredicate> &)componentPredicates
            componentControllerPredicates:(const std::unordered_set<CKComponentControllerPredicate> &)componentControllerPredicates
                        analyticsListener:(id<CKAnalyticsListener>)analyticsListener
                                  options:(const CKComponentHostingViewOptions &)options
{
  if (self = [super initWithFrame:CGRectZero]) {
    _componentProvider = componentProvider;
    _sizeRangeProvider = sizeRangeProvider;

    _pendingInputs = {.scopeRoot =
      CKComponentScopeRootWithPredicates(self, analyticsListener ?: sDefaultAnalyticsListener, componentPredicates, componentControllerPredicates)};

    _allowTapPassthrough = options.allowTapPassthrough;
    _containerView = [[CKComponentRootView alloc] initWithFrame:CGRectZero allowTapPassthrough:_allowTapPassthrough];
    [self addSubview:_containerView];

    _componentNeedsUpdate = YES;
    _requestedUpdateMode = CKUpdateModeSynchronous;
    _unifyBuildAndLayout = options.unifyBuildAndLayout;
    _enableComponentAnimations = options.enableComponentAnimations;
    if (_enableComponentAnimations) {
      _animationApplicator = CK::AnimationApplicatorFactory::make();
    }

    [CKComponentDebugController registerReflowListener:self];
  }
  return self;
}

- (void)dealloc
{
  CKAssertMainThread(); // UIKit should guarantee this
  CKUnmountComponents(_mountedComponents);
  CKComponentScopeRootAnnounceControllerInvalidation(_pendingInputs.scopeRoot);
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
    const CGSize size = self.bounds.size;

    if (!_unifyBuildAndLayout) {
      [self _synchronouslyUpdateComponentIfNeeded];
      if (_mountedRootLayout.component() != _component || !CGSizeEqualToSize(_mountedRootLayout.size(), size)) {
        [self setMountedRootLayout:CKComputeRootComponentLayout(_component, {size, size}, _pendingInputs.scopeRoot.analyticsListener, self.layoutPredicates)];
      }
    } else {
      [self _synchronouslyBuildAndLayoutComponentIfNeeded:{size,size} forceUpdate:(_mountedRootLayout.component() != _component || !CGSizeEqualToSize(_mountedRootLayout.size(), size))];
    }

    const auto mountPerformer = ^{
      __block NSSet<CKComponent *> *unmountedComponents;
      CKComponentBoundsAnimationApply(_boundsAnimation, ^{
        const auto result = CKMountComponentLayout(_mountedRootLayout.layout(), _containerView, _mountedComponents, nil, _pendingInputs.scopeRoot.analyticsListener);
        _mountedComponents = result.mountedComponents;
        unmountedComponents = result.unmountedComponents;
      }, nil);
      return unmountedComponents;
    };
    _animationApplicator->runAnimationsWhenMounting(_componentAnimations, mountPerformer);

    _componentAnimations = {};
    _boundsAnimation = {};
    _isMountingComponent = NO;
  }
}

- (CGSize)sizeThatFits:(CGSize)size
{
  CKAssertMainThread();
  if (!_unifyBuildAndLayout) {
    [self _synchronouslyUpdateComponentIfNeeded];
    const CKSizeRange constrainedSize = [_sizeRangeProvider sizeRangeForBoundingSize:size];
    return CKComputeRootComponentLayout(_component, constrainedSize, _pendingInputs.scopeRoot.analyticsListener).size();
  } else {
    const CKSizeRange constrainedSize = [_sizeRangeProvider sizeRangeForBoundingSize:size];
    return [self _synchronouslyCalculateLayoutSize:constrainedSize];
  }
}

#pragma mark - Hit Testing

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
  UIView *const hitView = [super hitTest:point withEvent:event];

  if (_allowTapPassthrough && hitView == self) {
    return nil;
  } else {
    return hitView;
  }
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

- (CKComponentLayout)mountedLayout
{
  return _mountedRootLayout.layout();
}

- (void)setMountedRootLayout:(const CKComponentRootLayout &)rootLayout
{
  _componentAnimations = [self animationsForNewLayout:rootLayout];
  _mountedRootLayout = rootLayout;
  [self _sendDidPrepareLayoutIfNeeded];
}

- (id<CKComponentScopeEnumeratorProvider>)scopeEnumeratorProvider
{
  return _pendingInputs.scopeRoot;
}

/**
 @return A build component result from current component settings.
 */
- (CKBuildComponentResult)currentBuildComponentResult {
  return {
    .component = _component,
    .scopeRoot = _pendingInputs.scopeRoot,
    .boundsAnimation = _boundsAnimation,
  };
}

- (std::vector<CKComponentPredicate>)layoutPredicates
{
  static const auto animationPredicates = std::vector<CKComponentPredicate> {
    CKComponentHasAnimationsOnInitialMountPredicate,
    CKComponentHasAnimationsFromPreviousComponentPredicate,
  };
  return _enableComponentAnimations ? animationPredicates : std::vector<CKComponentPredicate> {};
}

- (CKComponentAnimations)animationsForNewLayout:(const CKComponentRootLayout &)newLayout
{
  return _enableComponentAnimations ?
  CK::animationsForComponents(CK::animatedComponentsBetweenLayouts(newLayout, _mountedRootLayout)) :
  CKComponentAnimations {};
}

#pragma mark - Appearance

- (void)hostingViewWillAppear
{
  // We often run into this situation where `hostingViewWillAppear` is called
  // before the component tree is generated and mounted, resulting in no-op.
  // This is because component tree is generated in `layoutSubviews` happening at the end of the runloop.
  // This force the layout immediately to ensure that
  // component tree is created in order to have the appearance callback received.
  [self layoutIfNeeded];
  CKComponentScopeRootAnnounceControllerAppearance(_pendingInputs.scopeRoot);
}

- (void)hostingViewDidDisappear
{
  CKComponentScopeRootAnnounceControllerDisappearance(_pendingInputs.scopeRoot);
}

#pragma mark - CKComponentStateListener

- (void)componentScopeHandle:(CKComponentScopeHandle *)handle
              rootIdentifier:(CKComponentScopeRootIdentifier)rootIdentifier
       didReceiveStateUpdate:(id (^)(id))stateUpdate
                    metadata:(const CKStateUpdateMetadata)metadata
                        mode:(CKUpdateMode)mode
{
  CKAssertMainThread();

  _pendingInputs.stateUpdates[handle].push_back(stateUpdate);
  [self _setNeedsUpdateWithMode:mode];
}

#pragma mark - CKComponentDebugController

- (void)didReceiveReflowComponentsRequest
{
  [self _setNeedsUpdateWithMode:CKUpdateModeAsynchronous];
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
      if (_unifyBuildAndLayout) {
        [self _asynchronouslyBuildAndLayoutComponentIfNeeded];
      } else {
        [self _asynchronouslyUpdateComponentIfNeeded];
      }
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
    const auto result =
    std::make_shared<const CKBuildComponentResult>(CKBuildComponent(
                                                                    inputs->scopeRoot,
                                                                    inputs->stateUpdates,
                                                                    ^{
                                                                      const auto controllerCtx = [CKComponentControllerContext newWithHandleAnimationsInController:!_enableComponentAnimations];
                                                                      const CKComponentContext<CKComponentControllerContext> ctx {controllerCtx};
                                                                      return [_componentProvider componentForModel:inputs->model context:inputs->context];
                                                                    }
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
  _boundsAnimation = result.boundsAnimation;
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
  [self _applyResult:CKBuildComponent(_pendingInputs.scopeRoot, _pendingInputs.stateUpdates, ^{
    const auto controllerCtx = [CKComponentControllerContext newWithHandleAnimationsInController:!_enableComponentAnimations];
    const CKComponentContext<CKComponentControllerContext> ctx {controllerCtx};
    return [_componentProvider componentForModel:_pendingInputs.model context:_pendingInputs.context];
  })];
  _isSynchronouslyUpdatingComponent = NO;
}


- (void)_sendDidPrepareLayoutIfNeeded
{
  CKComponentSendDidPrepareLayoutForComponent(_pendingInputs.scopeRoot, _mountedRootLayout);
}

#pragma mark - Unified Build And Layout methods

- (CKBuildAndLayoutComponentResult)_buildAndLayoutComponentIfNeeded:(const CKSizeRange &)sizeRange pendingInputs:(const CKComponentHostingViewInputs &)pendingInputs{
  id<NSObject> model = pendingInputs.model;
  id<NSObject> context = pendingInputs.context;
  CKBuildAndLayoutComponentResult results = CKBuildAndLayoutComponent(pendingInputs.scopeRoot,
                                                                      pendingInputs.stateUpdates,
                                                                      sizeRange,
                                                                      ^{
                                                                        const auto controllerCtx = [CKComponentControllerContext newWithHandleAnimationsInController:!_enableComponentAnimations];
                                                                        const CKComponentContext<CKComponentControllerContext> ctx {controllerCtx};
                                                                        return [_componentProvider componentForModel:model context:context];
                                                                      });

  return results;
}

- (CGSize)_synchronouslyCalculateLayoutSize:(const CKSizeRange &)sizeRange {
  CKBuildAndLayoutComponentResult results = [self _buildAndLayoutComponentIfNeeded:sizeRange pendingInputs:_pendingInputs];
  return results.computedLayout.size();
}

- (void)_asynchronouslyBuildAndLayoutComponentIfNeeded
{
  if (_scheduledAsynchronousBuildAndLayoutUpdate) {
    return;
  }
  _scheduledAsynchronousBuildAndLayoutUpdate = YES;

  // Wait until the end of the run loop so that if multiple async updates are triggered we don't thrash.
  dispatch_async(dispatch_get_main_queue(), ^{
    [self _scheduleAsynchronousBuildAndLayout];
  });
}

- (void)_scheduleAsynchronousBuildAndLayout
{
  if (_requestedUpdateMode != CKUpdateModeAsynchronous) {
    // A synchronous build and layout was either scheduled or completed, so we can skip the async update.
    _scheduledAsynchronousBuildAndLayoutUpdate = NO;
    return;
  }
  const auto inputs = std::make_shared<const CKComponentHostingViewInputs>(_pendingInputs);
  const CKSizeRange constrainedSize = {self.bounds.size,self.bounds.size};
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    CKBuildAndLayoutComponentResult results = [self _buildAndLayoutComponentIfNeeded:constrainedSize pendingInputs:*inputs];
    dispatch_async(dispatch_get_main_queue(), ^{
      // If the inputs haven't changed, apply the result; otherwise, retry.
      if (_pendingInputs == *inputs) {
        [self _applyResult:results.buildComponentResult];
        [self setMountedRootLayout:results.computedLayout];
        _scheduledAsynchronousBuildAndLayoutUpdate = NO;
        [self setNeedsLayout];
        [_delegate componentHostingViewDidInvalidateSize:self];
      } else {
        [self _scheduleAsynchronousUpdate];
      }
    });
  });
}

- (void)_synchronouslyBuildAndLayoutComponentIfNeeded:(const CKSizeRange &)sizeRange forceUpdate:(BOOL)forceUpdate
{
  if (!forceUpdate && (_componentNeedsUpdate == NO || _requestedUpdateMode == CKUpdateModeAsynchronous)) {
    return;
  }

  if (_isSynchronouslyUpdatingComponent) {
    CKFailAssert(@"CKComponentHostingView is not re-entrant. This is called by -layoutSubviews, so ensure "
                 "that there is nothing that is triggering a nested call to -layoutSubviews.");
    return;
  }

  _isSynchronouslyUpdatingComponent = YES;
  CKBuildAndLayoutComponentResult results = [self _buildAndLayoutComponentIfNeeded:sizeRange pendingInputs:_pendingInputs];
  [self _updateMountedLayoutWithLayout:results.computedLayout buildComponentResult:results.buildComponentResult];
  _isSynchronouslyUpdatingComponent = NO;
}

/**
 Updates the mount layout with a new layout and build component result passed in input.

 @param computedLayout The computed layout to assign to the mounted layout.
 @param buildComponentResult The build component result to apply after the mounted layout has been updated
 */
- (void)_updateMountedLayoutWithLayout:(const CKComponentRootLayout &)computedLayout buildComponentResult:(const CKBuildComponentResult &)buildComponentResult {
  [self _applyResult:buildComponentResult];
  [self setMountedRootLayout:computedLayout];
}

@end
