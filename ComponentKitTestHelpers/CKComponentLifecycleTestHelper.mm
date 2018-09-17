/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentLifecycleTestHelper.h"

#import <ComponentKit/CKBuildComponent.h>
#import <ComponentKit/CKComponentDataSourceAttachController.h>
#import <ComponentKit/CKComponentLayout.h>
#import <ComponentKit/CKComponentProvider.h>
#import <ComponentKit/CKComponentScopeHandle.h>
#import <ComponentKit/CKComponentScopeRoot.h>
#import <ComponentKit/CKComponentScopeRootFactory.h>
#import <ComponentKit/CKComponentSizeRangeProviding.h>
#import <ComponentKit/CKComponentRootLayoutProvider.h>
#import <ComponentKit/CKDimension.h>

@interface CKComponentLifecycleTestHelper () <CKComponentStateListener, CKComponentRootLayoutProvider>
@end

@implementation CKComponentLifecycleTestHelper
{
  Class<CKComponentProvider> _componentProvider;
  id<CKComponentSizeRangeProviding> _sizeRangeProvider;
  CKComponentScopeRoot *_previousScopeRoot;
  CKComponentStateUpdateMap _pendingStateUpdates;
  CKComponentLifecycleTestHelperState _state;
  CKComponentRootLayout _rootLayout;
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

- (CKComponentLifecycleTestHelperState)prepareForUpdateWithModel:(id)model
                                                     constrainedSize:(CKSizeRange)constrainedSize
                                                             context:(id<NSObject>)context
{
  CKAssertMainThread();
  CKComponentScopeRoot *previousScopeRoot = _previousScopeRoot ?: CKComponentScopeRootWithDefaultPredicates(self, nil);
  CKBuildComponentResult result = CKBuildComponent(previousScopeRoot, _pendingStateUpdates, ^{
    return [_componentProvider componentForModel:model context:context];
  });
  const CKComponentLayout componentLayout = CKComputeRootComponentLayout(result.component, constrainedSize).layout();
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

- (void)updateWithState:(const CKComponentLifecycleTestHelperState &)state
{
  CKAssertMainThread();
  [self updateWithStateWithoutMounting:state];
  if (_mountedView) {
    CKComponentBoundsAnimationApply(state.boundsAnimation, ^{
      [self attachToView:_mountedView];
    }, nil);
  }
}

- (void)updateWithStateWithoutMounting:(const CKComponentLifecycleTestHelperState &)state
{
  CKAssertMainThread();
  _state = state;
  _rootLayout = CKComponentRootLayout{_state.componentLayout};
}

- (void)attachToView:(UIView *)view
{
  CKAssertMainThread();
  _mountedView = view;
  CKComponentDataSourceAttachControllerAttachComponentRootLayout(
      _componentDataSourceAttachController,
      {.layoutProvider = self,
       .scopeIdentifier = _state.scopeRoot.globalIdentifier,
       .boundsAnimation = _state.boundsAnimation,
       .view = view,
       .analyticsListener = nil});
}

- (void)detachFromView
{
  CKAssertMainThread();
  _mountedView = nil;
  [_componentDataSourceAttachController detachComponentLayoutWithScopeIdentifier:_state.scopeRoot.globalIdentifier];
}

- (const CKComponentLifecycleTestHelperState &)state
{
  CKAssertMainThread();
  return _state;
}

- (void)componentScopeHandle:(CKComponentScopeHandle *)handle
              rootIdentifier:(CKComponentScopeRootIdentifier)rootIdentifier
       didReceiveStateUpdate:(id (^)(id))stateUpdate
                    metadata:(const CKStateUpdateMetadata)metadata
                        mode:(CKUpdateMode)mode
{
  CKAssertMainThread();

  _pendingStateUpdates[handle].push_back(stateUpdate);
  const CKSizeRange constrainedSize = _sizeRangeProvider ? [_sizeRangeProvider sizeRangeForBoundingSize:_state.constrainedSize.max] : _state.constrainedSize;
  [self updateWithState:[self prepareForUpdateWithModel:_state.model
                                        constrainedSize:constrainedSize
                                                context:_state.context]];
}

#pragma mark - CKComponentRootLayoutProvider

- (const CKComponentRootLayout &)rootLayout
{
  return _rootLayout;
}

@end
