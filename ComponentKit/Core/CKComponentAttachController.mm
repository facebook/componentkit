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
#import "CKComponentAttachController.h"
#import "CKComponentAttachControllerInternal.h"
#import "CKDataSourceItem.h"

@implementation CKComponentAttachController
{
  /**
   We keep a strong reference to the mounted view to enforce that every view
   being attached will have to be detached before the view is deallocated.
   */
  NSMutableDictionary *_scopeIdentifierToAttachedViewMap;
  NSMapTable<NSNumber *, id<CKComponentRootLayoutProvider>> *_scopeIdentifierToLayoutProvider;
}

#pragma mark - Initialization/Teardown

- (instancetype)init
{
  self = [super init];
  if (self) {
    _scopeIdentifierToAttachedViewMap = [NSMutableDictionary dictionary];
    _scopeIdentifierToLayoutProvider = [NSMapTable strongToWeakObjectsMapTable];
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

void CKComponentAttachControllerAttachComponentRootLayout(
    const CKComponentAttachController *const self,
    const CKComponentAttachControllerAttachComponentRootLayoutParams &params)
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

  const auto &prevLayout = [&]() {
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
                                                      params.isUpdate);
  // Mark the view as attached and associates it to the right attach state
  self->_scopeIdentifierToAttachedViewMap[@(params.scopeIdentifier)] = params.view;
  // Save layout provider in map, it will be used for figuring out animations between two layouts.
  [self->_scopeIdentifierToLayoutProvider setObject:params.layoutProvider
                                             forKey:@(params.scopeIdentifier)];
  CKSetAttachStateForView(params.view, attachState);
}

- (void)detachComponentLayoutWithScopeIdentifier:(CKComponentScopeRootIdentifier)scopeIdentifier
{
  CKAssertMainThread();
  [self _detachComponentLayoutWithScopeIdentifier:@(scopeIdentifier)];
}

- (void)detachAll
{
  CKAssertMainThread();
  for (NSNumber *const scopeIdentifier in _scopeIdentifierToAttachedViewMap.allKeys) {
    [self _detachComponentLayoutWithScopeIdentifier:scopeIdentifier];
  }
}

#pragma mark - Internal API

- (CKComponentAttachState *)attachStateForScopeIdentifier:(CKComponentScopeRootIdentifier)scopeIdentifier
{
  return CKGetAttachStateForView(((UIView *)_scopeIdentifierToAttachedViewMap[@(scopeIdentifier)]));
}

- (id<CKComponentRootLayoutProvider>)layoutProviderForScopeIdentifier:(CKComponentScopeRootIdentifier)scopeIdentifier
{
  return [_scopeIdentifierToLayoutProvider objectForKey:@(scopeIdentifier)];
}

#pragma mark - Attach helpers

- (void)_detachComponentLayoutWithScopeIdentifier:(NSNumber *)scopeIdentifier
{
  [self _detachComponentLayoutFromView:[_scopeIdentifierToAttachedViewMap objectForKey:scopeIdentifier]];
  [_scopeIdentifierToLayoutProvider removeObjectForKey:scopeIdentifier];
}

- (void)_detachComponentLayoutFromView:(UIView *)view
{
  CKComponentAttachState *attachState = CKGetAttachStateForView(view);
  if (attachState) {
    CKUnmountComponents(attachState.mountedComponents);
    // Mark the view as detached
    [_scopeIdentifierToAttachedViewMap removeObjectForKey:@(attachState.scopeIdentifier)];
    CKSetAttachStateForView(view, nil);
  }
}

static CKComponentAttachState *mountComponentLayoutInView(const CKComponentRootLayout &rootLayout,
                                                          const CKComponentRootLayout &prevLayout,
                                                          UIView *view,
                                                          CKComponentScopeRootIdentifier scopeIdentifier,
                                                          const CKComponentBoundsAnimation &boundsAnimation,
                                                          id<CKAnalyticsListener> analyticsListener,
                                                          BOOL isUpdate)
{
  CKCAssertNotNil(view, @"Impossible to mount a component layout on a nil view");
  [analyticsListener willCollectAnimationsFromComponentTreeWithRootComponent:rootLayout.component()];
  const auto animatedComponents = CK::animatedComponentsBetweenLayouts(rootLayout, prevLayout);
  const auto animations = CK::animationsForComponents(animatedComponents, view);
  [analyticsListener didCollectAnimationsFromComponentTreeWithRootComponent:rootLayout.component()];

  auto const oldAttachState = CKGetAttachStateForView(view);
  NSSet *currentlyMountedComponents = oldAttachState.mountedComponents;
  __block NSSet *newMountedComponents = nil;
  const auto mountPerformer = ^{
    __block NSSet<CKComponent *> *unmountedComponents;
    CKComponentBoundsAnimationApply(boundsAnimation, ^{
      const auto result = CKMountComponentLayout(rootLayout.layout(), view, currentlyMountedComponents, nil, analyticsListener, isUpdate);
      newMountedComponents = result.mountedComponents;
      unmountedComponents = result.unmountedComponents;
    }, nil);
    return unmountedComponents;
  };

  std::shared_ptr<CK::AnimationApplicator<>> animationApplicator;
  animationApplicator = oldAttachState != nil ? oldAttachState.animationApplicator : CK::AnimationApplicatorFactory::make();
  animationApplicator->runAnimationsWhenMounting(animations, mountPerformer);

  const auto attachState = [[CKComponentAttachState alloc] initWithScopeIdentifier:scopeIdentifier mountedComponents:newMountedComponents animationApplicator:animationApplicator];
  CKComponentAttachStateSetRootLayout(attachState, rootLayout);
  return attachState;
}

static void tearDownAttachStateFromViews(NSArray *views)
{
  for (UIView *view in views) {
    CKComponentAttachState *attachState = CKGetAttachStateForView(view);
    if (attachState) {
      CKUnmountComponents(attachState.mountedComponents);
      CKSetAttachStateForView(view, nil);
    }
  }
}

@end


@implementation CKComponentAttachState
{
  CKComponentRootLayout _rootLayout;
  // The ownership isn't really shared with anyone, this is just to get copying the pointer in and out of the attach state easier
  std::shared_ptr<CK::AnimationApplicator<>> _animationApplicator;
}

- (instancetype)initWithScopeIdentifier:(CKComponentScopeRootIdentifier)scopeIdentifier
                      mountedComponents:(NSSet *)mountedComponents
                    animationApplicator:(const std::shared_ptr<CK::AnimationApplicator<>> &)animationApplicator
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

const CKComponentRootLayout &CKComponentAttachStateRootLayout(const CKComponentAttachState *const self)
{
  return self->_rootLayout;
}

void CKComponentAttachStateSetRootLayout(CKComponentAttachState *const self, const CKComponentRootLayout &rootLayout)
{
  self->_rootLayout = rootLayout;
}

- (const std::shared_ptr<CK::AnimationApplicator<>> &)animationApplicator
{
  return _animationApplicator;
}

@end

static char const kViewAttachStateKey = ' ';

auto CKGetAttachStateForView(UIView *view) -> CKComponentAttachState *
{
  return objc_getAssociatedObject(view, &kViewAttachStateKey);
}

auto CKSetAttachStateForView(UIView *view, CKComponentAttachState *attachState) -> void
{
  objc_setAssociatedObject(view, &kViewAttachStateKey, attachState, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
