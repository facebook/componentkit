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

#import "CKComponentDataSourceAttachController.h"
#import "CKComponentDataSourceAttachControllerInternal.h"

@implementation CKComponentDataSourceAttachController
{
  /**
   We keep a strong reference to the mounted view to enforce that every view
   being attached will have to be detached before the view is deallocated.
   */
  NSMutableDictionary *_scopeIdentifierToAttachedViewMap;
  BOOL _enableNewAnimationInfrastructure;
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

- (void)attachComponentRootLayout:(const CKComponentRootLayout &)rootLayout
              withScopeIdentifier:(CKComponentScopeRootIdentifier)scopeIdentifier
              withBoundsAnimation:(const CKComponentBoundsAnimation &)boundsAnimation
                           toView:(UIView *)view
                analyticsListener:(id<CKAnalyticsListener>)analyticsListener
{
  CKAssertMainThread();
  CKAssertNotNil(view, @"Impossible to attach a component layout to a nil view");
  UIView *currentlyAttachedView = _scopeIdentifierToAttachedViewMap[@(scopeIdentifier)];
  // If the component tree currently attached to the view is different from the one we want to attach
  if (currentlyAttachedView != view) {
    // 1 - If the component layout want to attach is currently attached somewhere else then detach it
    [self _detachComponentLayoutFromView:currentlyAttachedView];
    // 2 - Unmount the component tree currently in the view we want to attach our component layout to
    [self _detachComponentLayoutFromView:view];
  }
  // Mount the component tree on the view
  CKComponentDataSourceAttachState *attachState = mountComponentLayoutInView(rootLayout, view, scopeIdentifier, boundsAnimation, analyticsListener, _enableNewAnimationInfrastructure);
  // Mark the view as attached and associates it to the right attach state
  _scopeIdentifierToAttachedViewMap[@(scopeIdentifier)] = view;
  view.ck_attachState = attachState;
}

- (void)detachComponentLayoutWithScopeIdentifier:(CKComponentScopeRootIdentifier)scopeIdentifier
{
  CKAssertMainThread();
  [self _detachComponentLayoutFromView:[_scopeIdentifierToAttachedViewMap objectForKey:@(scopeIdentifier)]];
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
                                                                    UIView *view,
                                                                    CKComponentScopeRootIdentifier scopeIdentifier,
                                                                    const CKComponentBoundsAnimation &boundsAnimation,
                                                                    id<CKAnalyticsListener> analyticsListener,
                                                                    BOOL enableNewAnimationInfrastructure)
{
  CKCAssertNotNil(view, @"Impossible to mount a component layout on a nil view");
  NSSet *currentlyMountedComponents = view.ck_attachState.mountedComponents;
  __block NSSet *newMountedComponents = nil;
  CKComponentBoundsAnimationApply(boundsAnimation, ^{
    const auto result = CKMountComponentLayout(rootLayout.layout(), view, currentlyMountedComponents, nil, analyticsListener);
    newMountedComponents = result.mountedComponents;
  }, nil);
  return [[CKComponentDataSourceAttachState alloc] initWithScopeIdentifier:scopeIdentifier mountedComponents:newMountedComponents rootLayout:rootLayout];
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
}

- (instancetype)initWithScopeIdentifier:(CKComponentScopeRootIdentifier)scopeIdentifier
                      mountedComponents:(NSSet *)mountedComponents
                             rootLayout:(const CKComponentRootLayout &)rootLayout
{
  self = [super init];
  if (self) {
    CKAssertNotNil(mountedComponents, @"");
    _scopeIdentifier = scopeIdentifier;
    _mountedComponents = [mountedComponents copy];
    _rootLayout = rootLayout;
  }
  return self;
}

- (const CKComponentRootLayout &)rootLayout
{
  return _rootLayout;
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
