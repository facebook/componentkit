/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentLifecycleManager.h"
#import "CKComponentLifecycleManagerInternal.h"
#import "CKComponentLifecycleManager_Private.h"

#import <stack>

#import "CKComponent.h"
#import "CKComponentInternal.h"
#import "CKComponentLayout.h"
#import "CKComponentLifecycleManagerAsynchronousUpdateHandler.h"
#import "CKComponentMemoizer.h"
#import "CKComponentProvider.h"
#import "CKComponentScope.h"
#import "CKComponentScopeFrame.h"
#import "CKComponentSizeRangeProviding.h"
#import "CKComponentSubclass.h"
#import "CKComponentViewInterface.h"
#import "CKDimension.h"
#import "CKMutex.h"

using CK::Component::MountContext;

const CKComponentLifecycleManagerState CKComponentLifecycleManagerStateEmpty = {
  .model = nil,
  .constrainedSize = {},
  .layout = {},
  .root = nil,
};

@implementation CKComponentLifecycleManager
{
  UIView *_mountedView;
  NSSet *_mountedComponents;

  Class<CKComponentProvider> _componentProvider;
  id<CKComponentSizeRangeProviding> _sizeRangeProvider;

  CK::Mutex _mutex; // protects _previousRoot and _pendingStateUpdates
  CKComponentScopeRoot *_previousRoot;
  CKComponentStateUpdateMap _pendingStateUpdates;
  CKComponentLifecycleManagerState _state;
}

- (instancetype)initWithComponentProvider:(Class<CKComponentProvider>)componentProvider
{
  return [self initWithComponentProvider:componentProvider sizeRangeProvider:nil];
}

- (instancetype)initWithComponentProvider:(Class<CKComponentProvider>)componentProvider
                        sizeRangeProvider:(id<CKComponentSizeRangeProviding>)sizeRangeProvider
{
  if (self = [super init]) {
    _componentProvider = componentProvider;
    _sizeRangeProvider = sizeRangeProvider;
  }
  return self;
}

- (void)dealloc
{
  if (_mountedComponents) {
    NSSet *componentsToUnmount = _mountedComponents;
    dispatch_block_t unmountBlock = ^{ CKUnmountComponents(componentsToUnmount); };
    if ([NSThread isMainThread]) {
      unmountBlock();
    } else {
      dispatch_async(dispatch_get_main_queue(), unmountBlock);
    }
  }
}

#pragma mark - Updates

- (CKComponentLifecycleManagerState)prepareForUpdateWithModel:(id)model constrainedSize:(CKSizeRange)constrainedSize context:(id<NSObject>)context
{
  CK::MutexLocker locker(_mutex);

  CKComponentScopeRoot *previousRoot = _previousRoot ?: [CKComponentScopeRoot rootWithListener:self];

  // Vend components from the current layout to be available in the new state and layout calculations
  CKComponentMemoizer memoizer(_state.memoizerState);

  CKBuildComponentResult result = CKBuildComponent(previousRoot, _pendingStateUpdates, ^{
    return [_componentProvider componentForModel:model context:context];
  });

  const CKComponentLayout layout = CKComputeRootComponentLayout(result.component, constrainedSize);

  _previousRoot = result.scopeRoot;
  _pendingStateUpdates.clear();

  return {
    .model = model,
    .context = context,
    .constrainedSize = constrainedSize,
    .layout = layout,
    .memoizerState = memoizer.nextMemoizerState(),
    .root = result.scopeRoot,
    .boundsAnimation = result.boundsAnimation,
  };
}

- (void)updateWithState:(const CKComponentLifecycleManagerState &)state
{
  BOOL sizeChanged = !CGSizeEqualToSize(_state.layout.size, state.layout.size);
  [self updateWithStateWithoutMounting:state];

  // Since the state has been updated, re-mount the view if it exists.
  if (_mountedView != nil) {
    CKComponentBoundsAnimationApply(state.boundsAnimation, ^{ [self _mountLayout]; }, nil);
  }

  if (sizeChanged) {
    [_delegate componentLifecycleManager:self sizeDidChangeWithAnimation:state.boundsAnimation];
  }
}

- (void)updateWithStateWithoutMounting:(const CKComponentLifecycleManagerState &)state
{
  _state = state;
}

#pragma mark - Mount/Unmount

- (void)_mountLayout
{
  _mountedComponents = [CKMountComponentLayout(_state.layout, _mountedView, _mountedComponents, nil) copy];
}

- (void)attachToView:(UIView *)view
{
  if (view.ck_componentLifecycleManager != self) {
    /*
     It is possible that another lifecycleManager is already attached to the view
     on which we're trying to attach this lifecycleManager.
     If it is not the lifecycleManager we are trying to attach, we need to detach
     the other lifecycleManager first before attaching this one. We also need
     to detach this lifecycle manager from its current mounted view!
     */
    [self detachFromView];
    [view.ck_componentLifecycleManager detachFromView];
    _mountedView = view;
    view.ck_componentLifecycleManager = self;
  }
  [self _mountLayout];
}

- (void)detachFromView
{
  if (_mountedView) {
    CKAssert(_mountedView.ck_componentLifecycleManager == self, @"");
    CKUnmountComponents(_mountedComponents);
    _mountedComponents = nil;
    _mountedView.ck_componentLifecycleManager = nil;
    _mountedView = nil;
  }
}

- (BOOL)isAttachedToView
{
  return (_mountedView != nil);
}

#pragma mark - Miscellaneous

- (CGSize)size
{
  return _state.layout.size;
}

- (id)model
{
  return _state.model;
}

- (CKComponentScopeRoot *)scopeRoot
{
  return _state.root;
}

- (const CKComponentLayout &)componentLayout
{
  return _state.layout;
}

#pragma mark - CKComponentStateListener

- (void)componentScopeHandleWithIdentifier:(int32_t)globalIdentifier
                            rootIdentifier:(int32_t)rootIdentifier
                     didReceiveStateUpdate:(id (^)(id))stateUpdate
                                      mode:(CKUpdateMode)mode
{
  {
    CK::MutexLocker l(_mutex);
    _pendingStateUpdates.insert({globalIdentifier, stateUpdate});
  }

  if (mode == CKUpdateModeAsynchronous && _asynchronousUpdateHandler) {
    [_asynchronousUpdateHandler handleAsynchronousUpdateForComponentLifecycleManager:self];
  } else {
    const CKSizeRange constrainedSize = _sizeRangeProvider ? [_sizeRangeProvider sizeRangeForBoundingSize:_state.constrainedSize.max] : _state.constrainedSize;
    [self updateWithState:[self prepareForUpdateWithModel:_state.model constrainedSize:constrainedSize context:_state.context]];
  }
}

#pragma mark - Debug

- (const CKComponentLifecycleManagerState &)state
{
  return _state;
}

@end
