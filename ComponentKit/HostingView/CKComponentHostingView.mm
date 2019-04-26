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
#import "CKComponentControllerHelper.h"
#import "CKComponentEvents.h"
#import "CKGlobalConfig.h"
#import "CKComponentHostingContainerViewProvider.h"

struct CKComponentHostingViewInputs {
  CKComponentScopeRoot *scopeRoot;
  id<NSObject> model;
  id<NSObject> context;
  CKComponentStateUpdateMap stateUpdates;

  bool operator==(const CKComponentHostingViewInputs &i) const {
    return scopeRoot == i.scopeRoot && model == i.model && context == i.context && stateUpdates == i.stateUpdates;
  };
};

static auto nilProvider(id<NSObject>, id<NSObject>) -> CKComponent * { return nil; }

@interface CKComponentHostingView () <CKComponentDebugReflowListener>
{
  CKComponentProviderBlock _componentProvider;
  id<CKComponentSizeRangeProviding> _sizeRangeProvider;

  CKComponentHostingViewInputs _pendingInputs;

  CKComponentHostingContainerViewProvider *_containerViewProvider;

  CKComponent *_component;
  BOOL _componentNeedsUpdate;
  CKUpdateMode _requestedUpdateMode;

  CKComponentRootLayout _mountedRootLayout;

  BOOL _scheduledAsynchronousComponentUpdate;
  BOOL _isSynchronouslyUpdatingComponent;
  BOOL _isMountingComponent;
  BOOL _allowTapPassthrough;
  BOOL _shouldInvalidateControllerBetweenComponentGenerations;
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
  componentProvider = componentProvider ?: nilProvider;
  
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
      .scopeRoot = CKComponentScopeRootWithPredicates(self, (analyticsListener ?: CKReadGlobalConfig().defaultAnalyticsListener), componentPredicates, componentControllerPredicates)
    };

    _allowTapPassthrough = options.allowTapPassthrough;
    _containerViewProvider =
    [[CKComponentHostingContainerViewProvider alloc]
     initWithFrame:CGRectZero
     scopeIdentifier:_pendingInputs.scopeRoot.globalIdentifier
     analyticsListener:_pendingInputs.scopeRoot.analyticsListener
     sizeRangeProvider:sizeRangeProvider
     allowTapPassthrough:_allowTapPassthrough];
    [self addSubview:self.containerView];

    _componentNeedsUpdate = YES;
    _requestedUpdateMode = CKUpdateModeSynchronous;

    _shouldInvalidateControllerBetweenComponentGenerations = options.shouldInvalidateControllerBetweenComponentGenerations;

    [CKComponentDebugController registerReflowListener:self];
  }
  return self;
}

- (void)dealloc
{
  CKAssertMainThread(); // UIKit should guarantee this
  CKComponentScopeRootAnnounceControllerInvalidation(_pendingInputs.scopeRoot);
}

- (UIView *)containerView
{
  return _containerViewProvider.containerView;
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
    self.containerView.frame = self.bounds;
    const CGSize size = self.bounds.size;

    [self _synchronouslyUpdateComponentIfNeeded];
    if (_mountedRootLayout.component() != _component || !CGSizeEqualToSize(_mountedRootLayout.size(), size)) {
      auto const rootLayout = CKComputeRootComponentLayout(_component, {size, size}, _pendingInputs.scopeRoot.analyticsListener);
      _mountedRootLayout = rootLayout;
      [self _sendDidPrepareLayoutIfNeeded];
      [_containerViewProvider setRootLayout:rootLayout];
    }
    [_containerViewProvider mount];
    _isMountingComponent = NO;
  }
}

- (CGSize)sizeThatFits:(CGSize)size
{
  CKAssertMainThread();
  [self _synchronouslyUpdateComponentIfNeeded];
  return [self.containerView sizeThatFits:size];
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

- (void)applyResult:(const CKBuildComponentResult &)result
{
  CKAssertMainThread();
  [self _applyResult:result invalidComponentControllers:[self _invalidComponentControllersWithNewScopeRoot:result.scopeRoot
                                                                                     fromPreviousScopeRoot:_pendingInputs.scopeRoot]];
  [self setNeedsLayout];
  [_delegate componentHostingViewDidInvalidateSize:self];
}

- (CKComponentLayout)mountedLayout
{
  return _mountedRootLayout.layout();
}

- (id<CKComponentScopeEnumeratorProvider>)scopeEnumeratorProvider
{
  return _pendingInputs.scopeRoot;
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
    const auto invalidComponentControllers = _shouldInvalidateControllerBetweenComponentGenerations
    ? std::make_shared<const std::vector<CKComponentController *>>([self _invalidComponentControllersWithNewScopeRoot:result->scopeRoot
                                                                                                fromPreviousScopeRoot:inputs->scopeRoot])
    : nullptr;
    dispatch_async(dispatch_get_main_queue(), ^{
      if (!_componentNeedsUpdate) {
        // A synchronous update snuck in and took care of it for us.
        _scheduledAsynchronousComponentUpdate = NO;
        return;
      }

      // If the inputs haven't changed, apply the result; otherwise, retry.
      if (_pendingInputs == *inputs) {
        _scheduledAsynchronousComponentUpdate = NO;
        const auto componentControllers = invalidComponentControllers != nullptr ? *invalidComponentControllers : std::vector<CKComponentController *> {};
        [self _applyResult:*result invalidComponentControllers:componentControllers];
        [self setNeedsLayout];
        [_delegate componentHostingViewDidInvalidateSize:self];
      } else {
        [self _scheduleAsynchronousUpdate];
      }
    });
  });
}

- (void)_applyResult:(const CKBuildComponentResult &)result invalidComponentControllers:(const std::vector<CKComponentController *> &)invalidComponentControllers
{
  for (const auto componentController : invalidComponentControllers) {
    [componentController invalidateController];
  }
  _pendingInputs.scopeRoot = result.scopeRoot;
  _pendingInputs.stateUpdates = {};
  _component = result.component;
  [_containerViewProvider setBoundsAnimation:result.boundsAnimation];
  [_containerViewProvider setComponent:result.component];
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
  const auto result = CKBuildComponent(_pendingInputs.scopeRoot, _pendingInputs.stateUpdates, ^{
    return _componentProvider(_pendingInputs.model, _pendingInputs.context);
  });
  [self _applyResult:result invalidComponentControllers:[self _invalidComponentControllersWithNewScopeRoot:result.scopeRoot
                                                                                     fromPreviousScopeRoot:_pendingInputs.scopeRoot]];
  _isSynchronouslyUpdatingComponent = NO;
}


- (void)_sendDidPrepareLayoutIfNeeded
{
  CKComponentSendDidPrepareLayoutForComponent(_pendingInputs.scopeRoot, _mountedRootLayout);
}

- (std::vector<CKComponentController *>)_invalidComponentControllersWithNewScopeRoot:(CKComponentScopeRoot *)newRoot
                                                               fromPreviousScopeRoot:(CKComponentScopeRoot *)previousRoot
{
  if (!previousRoot || !_shouldInvalidateControllerBetweenComponentGenerations) {
    return {};
  }
  return
  CKComponentControllerHelper::removedControllersFromPreviousScopeRootMatchingPredicate(newRoot,
                                                                                        previousRoot,
                                                                                        &CKComponentControllerInvalidateEventPredicate);
}

@end
