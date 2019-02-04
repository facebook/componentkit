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

#import <algorithm>
#import <vector>

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
#import "CKDataSourceModificationHelper.h"
#import "CKGlobalConfig.h"

struct CKComponentHostingViewInputs {
  CKComponentScopeRoot *scopeRoot;
  id<NSObject> model;
  id<NSObject> context;
  CKComponentStateUpdateMap stateUpdates;

  bool operator==(const CKComponentHostingViewInputs &i) const {
    return scopeRoot == i.scopeRoot && model == i.model && context == i.context && stateUpdates == i.stateUpdates;
  };
};

struct CKComponentHostingViewSizeCache {
  CKComponentHostingViewSizeCache()
  : _constrainedSize({}), _computedSize({}), _empty(YES) {};

  CKComponentHostingViewSizeCache(const CKSizeRange constrainedSize,
                                  const CGSize computedSize)
  : _constrainedSize(constrainedSize), _computedSize(computedSize), _empty(NO) {};

  CGSize computedSize() {
    return _computedSize;
  }

  BOOL isValid(const CKSizeRange constrainedSize) {
    return _constrainedSize == constrainedSize;
  }

  operator bool() {
    return !_empty;
  }
private:
  CKSizeRange _constrainedSize;
  CGSize _computedSize;
  BOOL _empty;
};

@interface CKComponentHostingView () <CKComponentDebugReflowListener>
{
  CKComponentProviderBlock _componentProvider;
  id<CKComponentSizeRangeProviding> _sizeRangeProvider;

  CKComponentHostingViewInputs _pendingInputs;

  CKComponentBoundsAnimation _boundsAnimation;
  CKComponentAnimations _componentAnimations;
  std::unique_ptr<CK::AnimationApplicator<CK::ComponentAnimationsController>> _animationApplicator;
  std::unordered_set<CKComponentPredicate> _animationPredicates;

  CKComponent *_component;
  BOOL _componentNeedsUpdate;
  CKUpdateMode _requestedUpdateMode;

  CKComponentRootLayout _mountedRootLayout;
  NSSet *_mountedComponents;

  BOOL _scheduledAsynchronousComponentUpdate;
  BOOL _isSynchronouslyUpdatingComponent;
  BOOL _isMountingComponent;
  BOOL _allowTapPassthrough;
  BOOL _invalidateRemovedControllers;
  CKComponentHostingViewSizeCache _sizeCache;
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

- (instancetype)initWithComponentProviderFunc:(CKComponentProviderFunc)componentProvider
                            sizeRangeProvider:(id<CKComponentSizeRangeProviding>)sizeRangeProvider
{
  return [self initWithComponentProviderFunc:componentProvider
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

- (instancetype)initWithComponentProviderFunc:(CKComponentProviderFunc)componentProvider
                            sizeRangeProvider:(id<CKComponentSizeRangeProviding>)sizeRangeProvider
                            analyticsListener:(id<CKAnalyticsListener>)analyticsListener
{
  return [self initWithComponentProviderFunc:componentProvider
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
  auto const p = ^(id<NSObject> m, id<NSObject> c) {
    return [componentProvider componentForModel:m context:c];
  };
  return [self initWithComponentProviderBlock:p
                            sizeRangeProvider:sizeRangeProvider
                          componentPredicates:componentPredicates
                componentControllerPredicates:componentControllerPredicates
                            analyticsListener:analyticsListener
                                      options:options];
}

- (instancetype)initWithComponentProviderFunc:(CKComponentProviderFunc)componentProvider
                            sizeRangeProvider:(id<CKComponentSizeRangeProviding>)sizeRangeProvider
                          componentPredicates:(const std::unordered_set<CKComponentPredicate> &)componentPredicates
                componentControllerPredicates:(const std::unordered_set<CKComponentControllerPredicate> &)componentControllerPredicates
                            analyticsListener:(id<CKAnalyticsListener>)analyticsListener
                                      options:(const CKComponentHostingViewOptions &)options
{
  auto const p = ^(id<NSObject> m, id<NSObject> c) { return componentProvider(m, c); };
  return [self initWithComponentProviderBlock:p
                            sizeRangeProvider:sizeRangeProvider
                          componentPredicates:componentPredicates
                componentControllerPredicates:componentControllerPredicates
                            analyticsListener:analyticsListener
                                      options:options];
}

- (instancetype)initWithComponentProviderBlock:(CKComponentProviderBlock)componentProvider
                             sizeRangeProvider:(id<CKComponentSizeRangeProviding>)sizeRangeProvider
                           componentPredicates:(const std::unordered_set<CKComponentPredicate> &)componentPredicates
                 componentControllerPredicates:(const std::unordered_set<CKComponentControllerPredicate> &)componentControllerPredicates
                             analyticsListener:(id<CKAnalyticsListener>)analyticsListener
                                       options:(const CKComponentHostingViewOptions &)options
{
  if (self = [super initWithFrame:CGRectZero]) {
    _componentProvider = componentProvider;
    _sizeRangeProvider = sizeRangeProvider;

    _pendingInputs = {
      .scopeRoot = CKComponentScopeRootWithPredicates(self, analyticsListener ?: sDefaultAnalyticsListener, componentPredicates, componentControllerPredicates)
    };

    _allowTapPassthrough = options.allowTapPassthrough;
    _containerView = [[CKComponentRootView alloc] initWithFrame:CGRectZero allowTapPassthrough:_allowTapPassthrough];
    [self addSubview:_containerView];

    if (_component == nil || !_pendingInputs.stateUpdates.empty()) {
      _componentNeedsUpdate = YES;
      _requestedUpdateMode = CKUpdateModeSynchronous;
    }

    _animationApplicator = CK::AnimationApplicatorFactory::make();
    _animationPredicates = CKComponentAnimationPredicates();
    _invalidateRemovedControllers = options.invalidateRemovedControllers;

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

    [self _synchronouslyUpdateComponentIfNeeded];
    if (_mountedRootLayout.component() != _component || !CGSizeEqualToSize(_mountedRootLayout.size(), size)) {
      setMountedRootLayout(self, CKComputeRootComponentLayout(_component, {size, size}, _pendingInputs.scopeRoot.analyticsListener, _animationPredicates));
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
  [self _synchronouslyUpdateComponentIfNeeded];
  const CKSizeRange constrainedSize = [_sizeRangeProvider sizeRangeForBoundingSize:size];
  if (_sizeCache && _sizeCache.isValid(constrainedSize)) {
    return _sizeCache.computedSize();
  }
  const auto computedSize = CKComputeRootComponentLayout(_component,
                                                         constrainedSize,
                                                         _pendingInputs.scopeRoot.analyticsListener).size();
  _sizeCache = {constrainedSize, computedSize};
  return computedSize;
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

- (void)updateStateUpdates:(const CKComponentStateUpdateMap &)stateUpdates mode:(CKUpdateMode)mode
{
  CKAssertMainThread();
  _pendingInputs.stateUpdates = stateUpdates;
  [self _setNeedsUpdateWithMode:mode];
}

- (void)applyResult:(const CKBuildComponentResult &)result
{
  CKAssertMainThread();
  [self _applyResult:result];
  [self setNeedsLayout];
  [_delegate componentHostingViewDidInvalidateSize:self];
}

- (CKComponentLayout)mountedLayout
{
  return _mountedRootLayout.layout();
}

static void setMountedRootLayout(CKComponentHostingView *const self, const CKComponentRootLayout &rootLayout)
{
  self->_componentAnimations = animationsForNewLayout(self, rootLayout);
  self->_mountedRootLayout = rootLayout;
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

static CKComponentAnimations animationsForNewLayout(const CKComponentHostingView *const self, const CKComponentRootLayout &newLayout)
{
  return CK::animationsForComponents(CK::animatedComponentsBetweenLayouts(newLayout, self->_mountedRootLayout), self->_containerView);
}

#pragma mark - Appearance

- (void)hostingViewWillAppear
{
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
    const auto result =
    std::make_shared<const CKBuildComponentResult>(CKBuildComponent(
                                                                    inputs->scopeRoot,
                                                                    inputs->stateUpdates,
                                                                    ^{
                                                                      return _componentProvider(inputs->model, inputs->context);
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
  if (_invalidateRemovedControllers) {
    [self _invalidateControllersIfNeeded:result];
  }

  _pendingInputs.scopeRoot = result.scopeRoot;
  _pendingInputs.stateUpdates = {};
  _sizeCache = {};
  _component = result.component;
  _boundsAnimation = result.boundsAnimation;
  _componentNeedsUpdate = NO;
}

- (void)_invalidateControllersIfNeeded:(const CKBuildComponentResult &)result
{
  if (_pendingInputs.scopeRoot == nil) {
    return;
  }

  const auto oldControllers = [_pendingInputs.scopeRoot componentControllersMatchingPredicate:&CKComponentControllerInvalidateEventPredicate];
  const auto newControllers = [result.scopeRoot componentControllersMatchingPredicate:&CKComponentControllerInvalidateEventPredicate];
  const auto removedControllers = CK::Collection::difference(oldControllers,
                                                             newControllers,
                                                             [](const auto &lhs, const auto &rhs){
                                                               return lhs == rhs;
                                                             });

  for (auto it = removedControllers.begin(); it != removedControllers.end(); it++) {
    const auto controller = (CKComponentController *)*it;
    [controller invalidateController];
  }
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
    return _componentProvider(_pendingInputs.model, _pendingInputs.context);
  })];
  _isSynchronouslyUpdatingComponent = NO;
}


- (void)_sendDidPrepareLayoutIfNeeded
{
  CKComponentSendDidPrepareLayoutForComponent(_pendingInputs.scopeRoot, _mountedRootLayout);
}

@end
