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
#import <ComponentKit/CKGlobalConfig.h>
#import <ComponentKit/CKMacros.h>
#import <ComponentKit/CKOptional.h>
#import <ComponentKit/CKRootTreeNode.h>

#import <algorithm>
#import <vector>

#import "CKAnimationApplicator.h"
#import "CKBuildComponent.h"
#import "CKComponentAnimation.h"
#import "CKComponentController.h"
#import "CKComponentDebugController.h"
#import "CKComponentGenerator.h"
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
#import "CKComponentHostingContainerViewProvider.h"

static auto nilProvider(id<NSObject>, id<NSObject>) -> CKComponent * { return nil; }

@interface CKComponentHostingView () <CKComponentDebugReflowListener, CKComponentGeneratorDelegate>
{
  CKComponentGenerator *_componentGenerator;
  CKComponentHostingContainerViewProvider *_containerViewProvider;

  CKComponent *_component;
  BOOL _componentNeedsUpdate;

  CK::Optional<CKComponentRootLayout> _mountedRootLayout;

  BOOL _scheduledAsynchronousComponentUpdate;
  BOOL _isSynchronouslyUpdatingComponent;
  BOOL _isMountingComponent;
  BOOL _allowTapPassthrough;

  CK::Optional<CGSize> _initialSize;
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
                     componentPredicates:{}
           componentControllerPredicates:{}
                       analyticsListener:nil
                                 options:{}];
}

- (instancetype)initWithComponentProviderFunc:(CKComponentProviderFunc)componentProvider
                            sizeRangeProvider:(id<CKComponentSizeRangeProviding>)sizeRangeProvider
{
  return [self initWithComponentProviderFunc:componentProvider
                           sizeRangeProvider:sizeRangeProvider
                         componentPredicates:{}
               componentControllerPredicates:{}
                           analyticsListener:nil
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
                  componentProviderIdentifier:[NSString stringWithFormat:@"%p", componentProvider]
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
                  componentProviderIdentifier:[NSString stringWithFormat:@"%p", componentProvider]
                            sizeRangeProvider:sizeRangeProvider
                          componentPredicates:componentPredicates
                componentControllerPredicates:componentControllerPredicates
                            analyticsListener:analyticsListener
                                      options:options];
}

- (instancetype)initWithComponentProviderBlock:(CKComponentProviderBlock)componentProvider
                   componentProviderIdentifier:(NSString *)componentProviderIdentifier
                             sizeRangeProvider:(id<CKComponentSizeRangeProviding>)sizeRangeProvider
                           componentPredicates:(const std::unordered_set<CKComponentPredicate> &)componentPredicates
                 componentControllerPredicates:(const std::unordered_set<CKComponentControllerPredicate> &)componentControllerPredicates
                             analyticsListener:(id<CKAnalyticsListener>)analyticsListener
                                       options:(const CKComponentHostingViewOptions &)options
{
  if (self = [super initWithFrame:CGRectZero]) {
    _componentGenerator =
    [[CKComponentGenerator alloc]
     initWithOptions:{
       .delegate = CK::makeNonNull(self),
       .componentProvider = CK::makeNonNull(componentProvider),
       .componentPredicates = componentPredicates,
       .componentControllerPredicates = componentControllerPredicates,
       .analyticsListener = analyticsListener,
     }];

    _allowTapPassthrough = options.allowTapPassthrough;
    _containerViewProvider =
    [[CKComponentHostingContainerViewProvider alloc]
     initWithFrame:CGRectZero
     scopeIdentifier:_componentGenerator.scopeRoot.globalIdentifier
     analyticsListener:_componentGenerator.scopeRoot.analyticsListener
     sizeRangeProvider:sizeRangeProvider
     allowTapPassthrough:_allowTapPassthrough
     rootViewPoolOptions:options.rootViewPool.map([&](const auto rootViewPool) {
      return CKComponentHostingViewRootViewPoolOptions {
        .rootViewCategory = CK::makeNonNull([NSString stringWithFormat:@"%@-%@", NSStringFromClass(self.class), componentProviderIdentifier]),
        .rootViewPool = rootViewPool,
      };
     })];
    [self addSubview:self.containerView];

    _initialSize = options.initialSize;
    _initialSize.apply([&](const auto initialSize) {
      self.frame = {CGPointZero, initialSize};
    });
    _componentNeedsUpdate = !_initialSize.hasValue();

    [CKComponentDebugController registerReflowListener:self];
  }
  return self;
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

    auto const buildTrigger = [self _synchronouslyUpdateComponentIfNeeded];
    const auto mountedComponent = _mountedRootLayout.mapToPtr([](const auto &rootLayout){
      return rootLayout.component();
    });
    // We shouldn't layout component if there is no `_mountedRootLayout` even though sizes are different.
    const auto shouldLayoutComponent = _mountedRootLayout.map([&](const auto &rootLayout) {
      return !CGSizeEqualToSize(rootLayout.size(), size);
    }).valueOr(NO);
    if (mountedComponent != _component || shouldLayoutComponent) {
      auto const rootLayout = CKComputeRootComponentLayout(_component, {size, size}, _componentGenerator.scopeRoot.analyticsListener, buildTrigger);
      [self _applyRootLayout:rootLayout];
    }
    [_containerViewProvider mount];
    _isMountingComponent = NO;
  }
}

- (CGSize)sizeThatFits:(CGSize)size
{
  CKAssertMainThread();
  [self _synchronouslyUpdateComponentIfNeeded];
  if (!_component) {
    // This could only happen when `initialSize` is specified.
    return _initialSize.valueOr(CGSizeZero);
  }
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
  [_componentGenerator updateModel:model];
  [self _setNeedsUpdateWithMode:mode];
}

- (void)updateContext:(id<NSObject>)context mode:(CKUpdateMode)mode
{
  CKAssertMainThread();
  [_componentGenerator updateContext:context];
  [self _setNeedsUpdateWithMode:mode];
}

- (void)applyResult:(const CKBuildComponentResult &)result
{
  CKAssertMainThread();
  _componentGenerator.scopeRoot = result.scopeRoot;
  [self _applyResult:result];
  [self setNeedsLayout];
  [_delegate componentHostingViewDidInvalidateSize:self];
}

- (void)reloadWithMode:(CKUpdateMode)mode
{
  CKAssertMainThread();
  [_componentGenerator ignoreComponentReuseInNextGeneration];
  [self _setNeedsUpdateWithMode:mode];
}

- (CKComponentLayout)mountedLayout
{
  return _mountedRootLayout.map([](const auto &rootLayout) {
    return rootLayout.layout();
  }).valueOr({});
}

- (id<NSObject>)uniqueIdentifier
{
  auto const scopeRootIdentifier = _componentGenerator.scopeRoot.globalIdentifier;
  return scopeRootIdentifier > 0 ? @(scopeRootIdentifier) : nil;
}

- (id<CKComponentScopeEnumeratorProvider>)scopeEnumeratorProvider
{
  return _componentGenerator.scopeRoot;
}

#pragma mark - Appearance

- (void)hostingViewWillAppear
{
  CKComponentScopeRootAnnounceControllerAppearance(_componentGenerator.scopeRoot);
}

- (void)hostingViewDidDisappear
{
  CKComponentScopeRootAnnounceControllerDisappearance(_componentGenerator.scopeRoot);
}

#pragma mark - CKComponentDebugController

- (void)didReceiveReflowComponentsRequest
{
  [self _setNeedsUpdateWithMode:CKUpdateModeAsynchronous];
}

- (void)didReceiveReflowComponentsRequestWithTreeNodeIdentifier:(CKTreeNodeIdentifier)treeNodeIdentifier
{
  if (_componentGenerator.scopeRoot.rootNode.parentForNodeIdentifier(treeNodeIdentifier) != nil) {
    [self _setNeedsUpdateWithMode:CKUpdateModeSynchronous];
  }
}

#pragma mark - Private

- (BOOL)_hasScheduledSyncUpdate
{
  return _componentNeedsUpdate && !_scheduledAsynchronousComponentUpdate;
}

- (void)_setNeedsUpdateWithMode:(CKUpdateMode)mode
{
  if ([self _hasScheduledSyncUpdate]) {
    return; // Already scheduled a synchronous update; nothing more to do.
  }

  _componentNeedsUpdate = YES;

  switch (mode) {
    case CKUpdateModeAsynchronous:
      [self _asynchronouslyUpdateComponentIfNeeded];
      break;
    case CKUpdateModeSynchronous:
      _scheduledAsynchronousComponentUpdate = NO;
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
    if (!_scheduledAsynchronousComponentUpdate) {
      // A synchronous update was either scheduled or completed, so we can skip the async update.
      return;
    }
    [_componentGenerator generateComponentAsynchronously];
  });
}

- (void)_applyResult:(const CKBuildComponentResult &)result
{
  _component = result.component;
  [_containerViewProvider setBoundsAnimation:result.boundsAnimation];
  [_containerViewProvider setComponent:result.component];
  _componentNeedsUpdate = NO;
}

- (void)_applyRootLayout:(const CKComponentRootLayout &)rootLayout
{
  _mountedRootLayout = rootLayout;
  [self _sendDidPrepareLayoutIfNeeded];
  [_containerViewProvider setRootLayout:rootLayout];
}

- (CK::Optional<CKBuildTrigger>)_synchronouslyUpdateComponentIfNeeded
{
  if (!_componentNeedsUpdate || _scheduledAsynchronousComponentUpdate) {
    return CK::none;
  }

  if (_isSynchronouslyUpdatingComponent) {
    CKFailAssert(@"CKComponentHostingView is not re-entrant. This is called by -layoutSubviews, so ensure "
                 "that there is nothing that is triggering a nested call to -layoutSubviews.");
    return CK::none;
  }

  _isSynchronouslyUpdatingComponent = YES;
  const auto result = [_componentGenerator generateComponentSynchronously];
  [self _applyResult:result];
  _isSynchronouslyUpdatingComponent = NO;
  return result.buildTrigger;
}


- (void)_sendDidPrepareLayoutIfNeeded
{
  _mountedRootLayout.apply([&](const auto &rootLayout) {
    CKComponentSendDidPrepareLayoutForComponent(_componentGenerator.scopeRoot, rootLayout);
  });
}

#pragma mark - CKComponentGeneratorDelegate

- (BOOL)componentGeneratorShouldApplyAsynchronousGenerationResult:(CKComponentGenerator *)componentGenerator
{
  return _componentNeedsUpdate;
}

- (void)componentGenerator:(CKComponentGenerator *)componentGenerator didAsynchronouslyGenerateComponentResult:(CKBuildComponentResult)result
{
  _scheduledAsynchronousComponentUpdate = NO;
  [self _applyResult:result];
  [self setNeedsLayout];
  [_delegate componentHostingViewDidInvalidateSize:self];
}

- (void)componentGenerator:(CKComponentGenerator *)componentGenerator didReceiveComponentStateUpdateWithMode:(CKUpdateMode)mode
{
  [self _setNeedsUpdateWithMode:mode];
}

@end
