/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <objc/runtime.h>
#import "CKComponentInternal.h"

#import "CKComponentAnimations.h"
#import "CKComponentDataSourceAttachController.h"
#import "CKComponentDataSourceAttachControllerInternal.h"
#import "CKDataSourceItem.h"

@implementation CKComponentDataSourceAttachController
{
  /**
   We keep a strong reference to the mounted view to enforce that every view
   being attached will have to be detached before the view is deallocated.
   */
  NSMutableDictionary *_scopeIdentifierToAttachedViewMap;
  BOOL _enableNewAnimationInfrastructure;
  NSMapTable<NSNumber *, id<CKComponentRootLayoutProvider>> *_scopeIdentifierToLayoutProvider;
}

#pragma mark - Initialization/Teardown

+ (instancetype)newWithEnableNewAnimationInfrastructure:(BOOL)enableNewAnimationInfrastructure
{
  return [[self alloc] initWithEnableNewAnimationInfrastructure:enableNewAnimationInfrastructure];
}

- (instancetype)init
{
  return [self initWithEnableNewAnimationInfrastructure:NO];
}

- (instancetype)initWithEnableNewAnimationInfrastructure:(BOOL)enableNewAnimationInfrastructure
{
  self = [super init];
  if (self) {
    _scopeIdentifierToAttachedViewMap = [NSMutableDictionary dictionary];
    _enableNewAnimationInfrastructure = enableNewAnimationInfrastructure;
    if (enableNewAnimationInfrastructure) {
      _scopeIdentifierToLayoutProvider = [NSMapTable strongToWeakObjectsMapTable];
    }
  }
  return self;
}

- (void)dealloc
{
  NSDictionary *scopeIdentifierToAttachedViewMap = _scopeIdentifierToAttachedViewMap;
  dispatch_block_t viewTearDownBlock = ^{
    NSArray *views = [scopeIdentifierToAttachedViewMap allValues];
    tearDownAttachStateFromViews(views);
  };
  if ([[NSThread currentThread] isMainThread]) {
    viewTearDownBlock();
  } else {
    dispatch_async(dispatch_get_main_queue(), viewTearDownBlock);
  }
}

#pragma mark - Public API

void CKComponentDataSourceAttachControllerAttachComponentRootLayout(
    const CKComponentDataSourceAttachController *const self,
    const CKComponentDataSourceAttachControllerAttachComponentRootLayoutParams &params)
{
  CKCAssertMainThread();
  CKCAssertNotNil(params.view, @"Impossible to attach a component layout to a nil view");
  if (self == nil) {
    CKCAssert(self, @"Impossible to attach a component layout to a nil attachController");
    return;
  }

  UIView *currentlyAttachedView = self->_scopeIdentifierToAttachedViewMap[@(params.scopeIdentifier)];
  // If the component tree currently attached to the view is different from the one we want to attach
  if (currentlyAttachedView != params.view) {
    // 1 - If the component layout want to attach is currently attached somewhere else then detach it
    [self _detachComponentLayoutFromView:currentlyAttachedView];
    // 2 - Unmount the component tree currently in the view we want to attach our component layout to
    [self _detachComponentLayoutFromView:params.view];
  }

  const auto &prevLayout = !self->_enableNewAnimationInfrastructure
  ? CKComponentRootLayout {}
  : [&]() {
    if (const auto layoutProvider = [self->_scopeIdentifierToLayoutProvider objectForKey:@(params.scopeIdentifier)]) {
      return layoutProvider.rootLayout;
    } else {
      return CKComponentRootLayout {};
    }
  }();
  // Mount the component tree on the view
  const auto &layout = params.layoutProvider ? params.layoutProvider.rootLayout : CKComponentRootLayout {};
  const auto attachState = mountComponentLayoutInView(layout,
                                                      prevLayout,
                                                      params.view,
                                                      params.scopeIdentifier,
                                                      params.boundsAnimation,
                                                      params.analyticsListener,
                                                      self->_enableNewAnimationInfrastructure);
  // Mark the view as attached and associates it to the right attach state
  self->_scopeIdentifierToAttachedViewMap[@(params.scopeIdentifier)] = params.view;
  if (self->_enableNewAnimationInfrastructure && params.layoutProvider) {
    // Save layout provider in map, it will be used for figuring out animations between two layouts.
    [self->_scopeIdentifierToLayoutProvider setObject:params.layoutProvider
                                               forKey:@(params.scopeIdentifier)];
  }
  params.view.ck_attachState = attachState;
}

- (void)detachComponentLayoutWithScopeIdentifier:(CKComponentScopeRootIdentifier)scopeIdentifier
{
  CKAssertMainThread();
  [self _detachComponentLayoutFromView:[_scopeIdentifierToAttachedViewMap objectForKey:@(scopeIdentifier)]];
  if (_enableNewAnimationInfrastructure) {
    [_scopeIdentifierToLayoutProvider removeObjectForKey:@(scopeIdentifier)];
  }
}

#pragma mark - Internal API

- (CKComponentDataSourceAttachState *)attachStateForScopeIdentifier:(CKComponentScopeRootIdentifier)scopeIdentifier
{
  return ((UIView *)_scopeIdentifierToAttachedViewMap[@(scopeIdentifier)]).ck_attachState;
}

#pragma mark - Attach helpers

- (void)_detachComponentLayoutFromView:(UIView *)view
{
  CKComponentDataSourceAttachState *attachState = view.ck_attachState;
  if (attachState) {
    CKUnmountComponents(attachState.mountedComponents);
    // Mark the view as detached
    [_scopeIdentifierToAttachedViewMap removeObjectForKey:@(attachState.scopeIdentifier)];
    view.ck_attachState = nil;
  }
}

static CKComponentDataSourceAttachState *mountComponentLayoutInView(const CKComponentRootLayout &rootLayout,
                                                                    const CKComponentRootLayout &prevLayout,
                                                                    UIView *view,
                                                                    CKComponentScopeRootIdentifier scopeIdentifier,
                                                                    const CKComponentBoundsAnimation &boundsAnimation,
                                                                    id<CKAnalyticsListener> analyticsListener,
                                                                    BOOL enableNewAnimationInfrastructure)
{
  CKCAssertNotNil(view, @"Impossible to mount a component layout on a nil view");
  const auto animations = enableNewAnimationInfrastructure ?
  [view, &rootLayout, &prevLayout](){
    const auto animatedComponents = CK::animatedComponentsBetweenLayouts(rootLayout, prevLayout);
    const auto animations = CK::animationsForComponents(animatedComponents, view);
    return animations;
  }() : CKComponentAnimations();

  NSSet *currentlyMountedComponents = view.ck_attachState.mountedComponents;
  __block NSSet *newMountedComponents = nil;
  const auto mountPerformer = ^{
    __block NSSet<CKComponent *> *unmountedComponents;
    CKComponentBoundsAnimationApply(boundsAnimation, ^{
      const auto result = CKMountComponentLayout(rootLayout.layout(), view, currentlyMountedComponents, nil, analyticsListener);
      newMountedComponents = result.mountedComponents;
      unmountedComponents = result.unmountedComponents;
    }, nil);
    return unmountedComponents;
  };

  std::shared_ptr<CK::AnimationApplicator<CK::ComponentAnimationsController>> animationApplicator;
  if (enableNewAnimationInfrastructure) {
    animationApplicator = view.ck_attachState != nil ? view.ck_attachState.animationApplicator : CK::AnimationApplicatorFactory::make();
    animationApplicator->runAnimationsWhenMounting(animations, mountPerformer);
  } else {
    mountPerformer();
  }

  const auto attachState = [[CKComponentDataSourceAttachState alloc] initWithScopeIdentifier:scopeIdentifier mountedComponents:newMountedComponents animationApplicator:animationApplicator];
  CKComponentDataSourceAttachStateSetRootLayout(attachState, rootLayout);
  return attachState;
}

static void tearDownAttachStateFromViews(NSArray *views)
{
  for (UIView *view in views) {
    CKComponentDataSourceAttachState *attachState = view.ck_attachState;
    if (attachState) {
      CKUnmountComponents(attachState.mountedComponents);
      view.ck_attachState = nil;
    }
  }
}

@end


@implementation CKComponentDataSourceAttachState
{
  CKComponentRootLayout _rootLayout;
  // The ownership isn't really shared with anyone, this is just to get copying the pointer in and out of the attach state easier
  std::shared_ptr<CK::AnimationApplicator<CK::ComponentAnimationsController>> _animationApplicator;
}

- (instancetype)initWithScopeIdentifier:(CKComponentScopeRootIdentifier)scopeIdentifier
                      mountedComponents:(NSSet *)mountedComponents
                    animationApplicator:(const std::shared_ptr<CK::AnimationApplicator<CK::ComponentAnimationsController>> &)animationApplicator
{
  self = [super init];
  if (self) {
    CKAssertNotNil(mountedComponents, @"");
    _scopeIdentifier = scopeIdentifier;
    _mountedComponents = [mountedComponents copy];
    _animationApplicator = animationApplicator;
  }
  return self;
}

const CKComponentRootLayout &CKComponentDataSourceAttachStateRootLayout(const CKComponentDataSourceAttachState *const self)
{
  return self->_rootLayout;
}

void CKComponentDataSourceAttachStateSetRootLayout(CKComponentDataSourceAttachState *const self, const CKComponentRootLayout &rootLayout)
{
  self->_rootLayout = rootLayout;
}

- (const std::shared_ptr<CK::AnimationApplicator<CK::ComponentAnimationsController>> &)animationApplicator
{
  return _animationApplicator;
}

@end

@implementation UIView (CKComponentDataSourceAttachController)

static char const kViewAttachStateKey = ' ';

- (void)ck_setAttachState:(CKComponentDataSourceAttachState *)ck_attachState
{
  objc_setAssociatedObject(self, &kViewAttachStateKey, ck_attachState, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CKComponentDataSourceAttachState *)ck_attachState
{
  return objc_getAssociatedObject(self, &kViewAttachStateKey);
}

@end

