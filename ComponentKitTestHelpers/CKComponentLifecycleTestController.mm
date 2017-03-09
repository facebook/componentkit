/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentLifecycleTestController.h"

#import <ComponentKit/CKComponentDataSourceAttachController.h>
#import <ComponentKit/CKComponentLayout.h>
#import <ComponentKit/CKComponentProvider.h>
#import <ComponentKit/CKComponentScopeRoot.h>
#import <ComponentKit/CKComponentSizeRangeProviding.h>
#import <ComponentKit/CKDimension.h>

@interface CKComponentLifecycleTestController () <CKComponentStateListener>
@end

@implementation CKComponentLifecycleTestController
{
  Class<CKComponentProvider> _componentProvider;
  id<CKComponentSizeRangeProviding> _sizeRangeProvider;
  CKComponentScopeRoot *_previousScopeRoot;
  CKComponentStateUpdateMap _pendingStateUpdates;
  CKComponentLifecycleTestControllerState _state;
  UIView *_mountedView;
  CKComponentDataSourceAttachController *_componentDataSourceAttachController;
}

- (instancetype)initWithComponentProvider:(Class<CKComponentProvider>)componentProvider
                        sizeRangeProvider:(id<CKComponentSizeRangeProviding>)sizeRangeProvider
{
  if (self = [super init]) {
    _componentProvider = componentProvider;
    _sizeRangeProvider = sizeRangeProvider;
    _componentDataSourceAttachController = [CKComponentDataSourceAttachController new];
  }
  return self;
}

- (CKComponentLifecycleTestControllerState)prepareForUpdateWithModel:(id)model
                                                     constrainedSize:(CKSizeRange)constrainedSize
                                                             context:(id<NSObject>)context
{
  CKAssertMainThread();
  CKComponentScopeRoot *previousScopeRoot = _previousScopeRoot ?: [CKComponentScopeRoot rootWithListener:self];
  CKBuildComponentResult result = CKBuildComponent(previousScopeRoot, _pendingStateUpdates, ^{
    return [_componentProvider componentForModel:model context:context];
  });
  const CKComponentLayout componentLayout = CKComputeRootComponentLayout(result.component, constrainedSize);
  _previousScopeRoot = result.scopeRoot;
  _pendingStateUpdates.clear();
  return {
    .model = model,
    .context = context,
    .constrainedSize = constrainedSize,
    .componentLayout = componentLayout,
    .scopeRoot = result.scopeRoot,
    .boundsAnimation = result.boundsAnimation,
  };
}

- (void)updateWithState:(const CKComponentLifecycleTestControllerState &)state
{
  CKAssertMainThread();
  [self updateWithStateWithoutMounting:state];
  if (_mountedView) {
    CKComponentBoundsAnimationApply(state.boundsAnimation, ^{
      [self attachToView:_mountedView];
    }, nil);
  }
}

- (void)updateWithStateWithoutMounting:(const CKComponentLifecycleTestControllerState &)state
{
  CKAssertMainThread();
  _state = state;
}

- (void)attachToView:(UIView *)view
{
  CKAssertMainThread();
  _mountedView = view;
  [_componentDataSourceAttachController attachComponentLayout:_state.componentLayout
                                          withScopeIdentifier:_state.scopeRoot.globalIdentifier
                                          withBoundsAnimation:_state.boundsAnimation
                                                       toView:view];
}

- (void)detachFromView
{
  CKAssertMainThread();
  _mountedView = nil;
  [_componentDataSourceAttachController detachComponentLayoutWithScopeIdentifier:_state.scopeRoot.globalIdentifier];
}

- (const CKComponentLifecycleTestControllerState &)state
{
  CKAssertMainThread();
  return _state;
}

- (void)componentScopeHandleWithIdentifier:(CKComponentScopeHandleIdentifier)globalIdentifier
                            rootIdentifier:(CKComponentScopeRootIdentifier)rootIdentifier
                     didReceiveStateUpdate:(id (^)(id))stateUpdate
                                      mode:(CKUpdateMode)mode
{
  CKAssertMainThread();
  _pendingStateUpdates.insert({globalIdentifier, stateUpdate});
  const CKSizeRange constrainedSize = _sizeRangeProvider ? [_sizeRangeProvider sizeRangeForBoundingSize:_state.constrainedSize.max] : _state.constrainedSize;
  [self updateWithState:[self prepareForUpdateWithModel:_state.model
                                        constrainedSize:constrainedSize
                                                context:_state.context]];
}

@end
