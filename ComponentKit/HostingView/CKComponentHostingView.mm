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

/**
 A cache for storing information about a component layout for given size.
 */
struct CKComponentLayoutAndBuildResultCache {
private:
  CKComponentLayout _layout = {};
  CKBuildComponentResult _buildComponentResult = {};

public:
  // We need to declare a default initializer that can make this type compliant to be used as ivar.
  CKComponentLayoutAndBuildResultCache() { }


  /**
   The designated initializer.

   @param layout The layout to store.
   @param buildComponentResult The build componente result to store.
   */
  CKComponentLayoutAndBuildResultCache(CKComponentLayout layout, CKBuildComponentResult buildComponentResult) : _layout(layout), _buildComponentResult(buildComponentResult) { }

  /**
   @param c The component holding the information needed to check cache's eligibility.
   @param s The size to use to check cache's eligibility.
   @return `YES` if cache is eligible for the given in inpute parameter. `NO` otherwise.
   */
  auto isEligibleForComponentAndSize(CKComponent * const c, const CGSize s) const
  {
    return CGSizeEqualToSize(s, _layout.size) && _layout.component == c;
  }

  auto layout() const
  {
    return _layout;
  }

  auto buildComponentResult() const
  {
    return _buildComponentResult;
  }
};

@interface CKComponentHostingView () <CKComponentStateListener, CKComponentDebugReflowListener>
{
  Class<CKComponentProvider> _componentProvider;
  id<CKComponentSizeRangeProviding> _sizeRangeProvider;

  CKComponentHostingViewInputs _pendingInputs;

  CKComponentBoundsAnimation _boundsAnimation;

  CKComponent *_component;
  BOOL _componentNeedsUpdate;
  CKUpdateMode _requestedUpdateMode;

  CKComponentLayout _mountedLayout;
  NSSet *_mountedComponents;

  BOOL _scheduledAsynchronousComponentUpdate;
  BOOL _scheduledAsynchronousBuildAndLayoutUpdate;
  BOOL _isSynchronouslyUpdatingComponent;
  BOOL _isMountingComponent;
  BOOL _unifyBuildAndLayout;
  BOOL _useCacheLayoutAndBuildResult;
  BOOL _allowTapPassthrough;

  // A convenience cache used to improve the layout calculation of the mounted component.
  CKComponentLayoutAndBuildResultCache _cacheComponentLayoutAndBuildResult;
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
                     componentPredicates:{}
           componentControllerPredicates:{}
                       analyticsListener:nil
                                 options:{}];
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
                      componentPredicates:(const std::unordered_set<CKComponentScopePredicate> &)componentPredicates
            componentControllerPredicates:(const std::unordered_set<CKComponentControllerScopePredicate> &)componentControllerPredicates
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
    _useCacheLayoutAndBuildResult = options.cacheLayoutAndBuildResult;

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

    if (_useCacheLayoutAndBuildResult) {
      [self _updateMountedComponentLayoutUsingCacheForSize:size];
    } else {
      if (!_unifyBuildAndLayout) {
        [self _synchronouslyUpdateComponentIfNeeded];
        if (_mountedLayout.component != _component || !CGSizeEqualToSize(_mountedLayout.size, size)) {
          _mountedLayout = CKComputeRootComponentLayout(_component, {size, size}, _pendingInputs.scopeRoot.analyticsListener).layout();
          [self _sendDidPrepareLayoutIfNeeded];
        }
      } else {
        [self _synchronouslyBuildAndLayoutComponentIfNeeded:{size,size} forceUpdate:(_mountedLayout.component != _component || !CGSizeEqualToSize(_mountedLayout.size, size))];
      }
    }
    CKComponentBoundsAnimationApply(_boundsAnimation, ^{
      const auto result = CKMountComponentLayout(_mountedLayout, _containerView, _mountedComponents, nil, _pendingInputs.scopeRoot.analyticsListener);
      _mountedComponents = result.mountedComponents;
    }, nil);
    _boundsAnimation = {};
    _isMountingComponent = NO;
  }
}

- (CGSize)sizeThatFits:(CGSize)size
{
  CKAssertMainThread();

  if (_useCacheLayoutAndBuildResult) {
    // The size to return might have been already calculated before and, if eligible, it can be re-used directly from our cache.
    //  Otherwise, we calculate the component layout needed to return the requested size and update the cache.

    if (!_unifyBuildAndLayout) {
      [self _synchronouslyUpdateComponentIfNeeded];
      if (_cacheComponentLayoutAndBuildResult.isEligibleForComponentAndSize(_component, size)) {
        return _cacheComponentLayoutAndBuildResult.layout().size;
      }

      const CKSizeRange constrainedSize = [_sizeRangeProvider sizeRangeForBoundingSize:size];
      return [self _buildComponentLayoutWithSizeRange:constrainedSize].size;
    } else {
      if (_cacheComponentLayoutAndBuildResult.isEligibleForComponentAndSize(_component, size)) {
        return _cacheComponentLayoutAndBuildResult.layout().size;
      }

      const CKSizeRange constrainedSize = [_sizeRangeProvider sizeRangeForBoundingSize:size];
      auto componentLayoutAndBuildResult = [self _buildAndLayoutComponentIfNeeded:constrainedSize pendingInputs:_pendingInputs];
      return componentLayoutAndBuildResult.computedLayout.layout().size;
    }
  } else {
    if (!_unifyBuildAndLayout) {
      [self _synchronouslyUpdateComponentIfNeeded];
      const CKSizeRange constrainedSize = [_sizeRangeProvider sizeRangeForBoundingSize:size];
      return CKComputeRootComponentLayout(_component, constrainedSize, _pendingInputs.scopeRoot.analyticsListener).layout().size;
    } else {
      const CKSizeRange constrainedSize = [_sizeRangeProvider sizeRangeForBoundingSize:size];
      return [self _synchronouslyCalculateLayoutSize:constrainedSize];
    }
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
  return _mountedLayout;
}

- (id<CKComponentScopeEnumeratorProvider>)scopeEnumeratorProvider
{
  return _pendingInputs.scopeRoot;
}

/**
 @return A build component result from current component settings.
 */
- (CKBuildComponentResult)currentBuildComponentResult {
  auto result = CKBuildComponentResult();
  result.component = _component;
  result.scopeRoot = _pendingInputs.scopeRoot;
  result.boundsAnimation = _boundsAnimation;
  return result;
}

/**
 Update the cache layer that holds computed layout and build results.

 @param componentLayout The component layout to store in cache
 @param buildComponentResult The build component result to store in cache
 */
- (void)_updateCachedComponentLayoutWithComponentLayout:(CKComponentLayout)componentLayout andBuildComponentResult:(CKBuildComponentResult)buildComponentResult {
  CKAssertTrue(_useCacheLayoutAndBuildResult);
  _cacheComponentLayoutAndBuildResult = CKComponentLayoutAndBuildResultCache {componentLayout, buildComponentResult};
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
  [self _applyResult:CKBuildComponent(_pendingInputs.scopeRoot, _pendingInputs.stateUpdates, ^CKComponent *{
    return [_componentProvider componentForModel:_pendingInputs.model context:_pendingInputs.context];
  })];
  _isSynchronouslyUpdatingComponent = NO;
}


- (void)_sendDidPrepareLayoutIfNeeded
{
  CKComponentSendDidPrepareLayoutForComponent(_pendingInputs.scopeRoot, _mountedLayout);
}


/**
 @param sizeRange The size range to use for calculating the proper computed layout.
 @return The componet layout computed for the in input size range.
 */
- (CKComponentLayout)_buildComponentLayoutWithSizeRange:(const CKSizeRange &)sizeRange {
  CKAssert(!_unifyBuildAndLayout, @"Use -_buildAndLayoutComponentIfNeeded:pendingInputs: for computing component layout in an unifyBuildAndLayout config");
  auto computedLayout = CKComputeRootComponentLayout(_component, sizeRange, _pendingInputs.scopeRoot.analyticsListener).layout();

  if (_useCacheLayoutAndBuildResult) {
    [self _updateCachedComponentLayoutWithComponentLayout:computedLayout andBuildComponentResult:[self currentBuildComponentResult]];
  }

  return computedLayout;
}

#pragma mark - Unified Build And Layout methods

- (CKBuildAndLayoutComponentResult)_buildAndLayoutComponentIfNeeded:(const CKSizeRange &)sizeRange pendingInputs:(const CKComponentHostingViewInputs &)pendingInputs{
  id<NSObject> model = pendingInputs.model;
  id<NSObject> context = pendingInputs.context;
  CKBuildAndLayoutComponentResult results = CKBuildAndLayoutComponent(pendingInputs.scopeRoot,
                                                                      pendingInputs.stateUpdates,
                                                                      sizeRange,
                                                                      ^{
                                                                        return [_componentProvider componentForModel:model context:context];
                                                                      });
  if (_useCacheLayoutAndBuildResult) {
    [self _updateCachedComponentLayoutWithComponentLayout:results.computedLayout.layout() andBuildComponentResult:results.buildComponentResult];
  }

  return results;
}

- (CGSize)_synchronouslyCalculateLayoutSize:(const CKSizeRange &)sizeRange {
  CKBuildAndLayoutComponentResult results = [self _buildAndLayoutComponentIfNeeded:sizeRange pendingInputs:_pendingInputs];
  return results.computedLayout.layout().size;
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
        _mountedLayout = results.computedLayout.layout();
        [self _applyResult:results.buildComponentResult];
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
  [self _updateMountedLayoutWithLayout:results.computedLayout.layout() buildComponentResult:results.buildComponentResult];
  _isSynchronouslyUpdatingComponent = NO;
}

/**
 Updates the mount layout with a new layout and build component result passed in input.

 @param computedLayout The computed layout to assign to the mounted layout.
 @param buildComponentResult The build component result to apply after the mounted layout has been updated
 */
- (void)_updateMountedLayoutWithLayout:(const CKComponentLayout &)computedLayout buildComponentResult:(const CKBuildComponentResult &)buildComponentResult {
  _mountedLayout = computedLayout;
  [self _applyResult:buildComponentResult];
  [self _sendDidPrepareLayoutIfNeeded];
}

/**
 Updates the mounted component layout by reusing any eligible cached layout for the in input size.

 @param size The size to use for updating the mounted layout.
 */
- (void)_updateMountedComponentLayoutUsingCacheForSize:(CGSize) size {
  CKAssertTrue(_useCacheLayoutAndBuildResult);

  // Shared lambda to estimate if an update of the component is needed
  const auto shouldUpdate = [](CGSize size, CKComponentLayout mountedLayout, CKComponent *component) { return (mountedLayout.component != component || !CGSizeEqualToSize(mountedLayout.size, size)); };

  if (!_unifyBuildAndLayout) {
    [self _synchronouslyUpdateComponentIfNeeded];
    if (shouldUpdate(size, _mountedLayout, _component)) {
      const auto componentLayout = _cacheComponentLayoutAndBuildResult.isEligibleForComponentAndSize(_component, size) ?
        _cacheComponentLayoutAndBuildResult.layout() :
        [self _buildComponentLayoutWithSizeRange:{size, size}];

      [self _updateMountedLayoutWithLayout:componentLayout buildComponentResult:[self currentBuildComponentResult]];
    }
  } else {
    if (_cacheComponentLayoutAndBuildResult.isEligibleForComponentAndSize(_component, size) &&
        shouldUpdate(size, _mountedLayout, _component)) {
      [self _updateMountedLayoutWithLayout:_cacheComponentLayoutAndBuildResult.layout() buildComponentResult:_cacheComponentLayoutAndBuildResult.buildComponentResult()];
    } else {
      [self _synchronouslyBuildAndLayoutComponentIfNeeded:{size,size} forceUpdate:shouldUpdate(size, _mountedLayout, _component)];
    }
  }
}

@end
