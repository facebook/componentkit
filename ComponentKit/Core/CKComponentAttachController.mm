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

#import <ComponentKit/CKAnalyticsListener.h>
#import <ComponentKit/CKAssociatedObject.h>
#import <ComponentKit/CKDelayedNonNull.h>
#import <ComponentKit/CKOptional.h>

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
  CK::Optional<CK::Component::RootViewPool> _rootViewPool;
  // This is used for pushing all root views to view pool upon deallocation.
  NSHashTable<id<CKComponentRootViewHost>> *_rootViewHosts;
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
  auto rootViewPool = _rootViewPool;
  const auto rootViewHosts = _rootViewHosts;
  dispatch_block_t viewTearDownBlock = ^{
    NSArray *views = [scopeIdentifierToAttachedViewMap allValues];
    tearDownAttachStateFromViews(views, rootViewPool, rootViewHosts);
  };
  if ([[NSThread currentThread] isMainThread]) {
    viewTearDownBlock();
  } else {
    dispatch_async(dispatch_get_main_queue(), viewTearDownBlock);
  }
}

- (void)setRootViewPool:(CK::Component::RootViewPool)rootViewPool
{
  CKAssertFalse(_rootViewPool.hasValue());
  _rootViewPool = rootViewPool;
  _rootViewHosts = [[NSHashTable alloc]
                    initWithOptions:NSHashTableStrongMemory | NSHashTableObjectPointerPersonality
                    capacity:20];
}

- (void)pushRootViewsToViewPool
{
  _rootViewPool.apply([&](auto &rootViewPool) {
    for (id<CKComponentRootViewHost> rootViewHost : _rootViewHosts) {
      if (const auto rootView = rootViewHost.rootView) {
        [self _detachComponentLayoutFromView:rootView];
      }
    }
    pushRootViewsToViewPool(rootViewPool, _rootViewHosts);
  });
}

auto CKUpdateComponentRootViewHost(CK::NonNull<id<CKComponentRootViewHost>> rootViewHost,
                                   CK::NonNull<NSString *> rootViewCategory,
                                   CK::NonNull<CKComponentAttachController *> attachController) -> void
{
  CKCAssert(attachController->_rootViewPool.hasValue(), @"Root view pool must be provided when root view host is used.");

  [attachController->_rootViewHosts addObject:rootViewHost];
  attachController->_rootViewPool.apply([&](auto &rootViewPool) {
    const auto previousRootViewCategory = [rootViewHost rootViewCategory];
    const auto previousRootView = [rootViewHost rootView];

    if ([previousRootViewCategory isEqualToString:rootViewCategory]) {
      return;
    }

    // Detach layout from previous root view so that components are properly unmounted.
    [attachController _detachComponentLayoutFromView:previousRootView];

    // Push previous root view to root view pool.
    if (previousRootViewCategory && previousRootView) {
      rootViewPool.pushRootViewWithCategory(CK::makeNonNull(previousRootView),
                                            CK::makeNonNull(previousRootViewCategory));
    }

    auto rootView = rootViewPool.popRootViewWithCategory(rootViewCategory);
    // New root view will be created when there is no root view available from root view pool.
    if (!rootView) {
      rootView = [rootViewHost createRootView];
    }
    [rootViewHost setRootView:rootView];
    [rootViewHost setRootViewCategory:rootViewCategory];
  });
}

#pragma mark - Public API

void CKComponentAttachControllerAttachComponentRootLayout(
    CKComponentAttachController *const self,
    const CKComponentAttachControllerAttachComponentRootLayoutParams &params)
{
  CKCAssertMainThread();
  if (self == nil) {
    CKCAssert(self, @"Impossible to attach a component layout to a nil attachController");
    return;
  }

  const auto view = params.view.match([&](CK::NonNull<UIView *> v) {
    return v;
  }, [&](CK::NonNull<id<CKComponentRootViewHost>> rootViewHost,
         CK::NonNull<NSString *> rootViewCategory) {
    CKUpdateComponentRootViewHost(rootViewHost, rootViewCategory, CK::makeNonNull(self));
    return CK::makeNonNull([rootViewHost rootView]);
  });

  UIView *currentlyAttachedView = self->_scopeIdentifierToAttachedViewMap[@(params.scopeIdentifier)];
  // If the component tree currently attached to the view is different from the one we want to attach
  if (currentlyAttachedView != view) {
    // 1 - If the component layout want to attach is currently attached somewhere else then detach it
    [self _detachComponentLayoutFromView:currentlyAttachedView];
    // 2 - Unmount the component tree currently in the view we want to attach our component layout to
    [self _detachComponentLayoutFromView:view];
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
                                                      view,
                                                      params.scopeIdentifier,
                                                      params.boundsAnimation,
                                                      params.analyticsListener,
                                                      params.isUpdate);
  // Mark the view as attached and associates it to the right attach state
  self->_scopeIdentifierToAttachedViewMap[@(params.scopeIdentifier)] = view;
  // Save layout provider in map, it will be used for figuring out animations between two layouts.
  [self->_scopeIdentifierToLayoutProvider setObject:params.layoutProvider
                                             forKey:@(params.scopeIdentifier)];
  CKSetAttachStateForView(view, attachState);
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

  const auto attachState = [[CKComponentAttachState alloc] initWithScopeIdentifier:scopeIdentifier
                                                                 mountedComponents:CK::makeNonNull(newMountedComponents)
                                                               animationApplicator:animationApplicator];
  CKComponentAttachStateSetRootLayout(attachState, rootLayout);
  return attachState;
}

static void pushRootViewsToViewPool(CK::Component::RootViewPool &rootViewPool,
                                    NSHashTable<id<CKComponentRootViewHost>> *rootViewHosts)
{
  for (id<CKComponentRootViewHost> rootViewHost : rootViewHosts) {
    const auto rootViewCategory = rootViewHost.rootViewCategory;
    const auto rootView = rootViewHost.rootView;
    if (rootViewCategory && rootView) {
      [rootViewHost rootViewWillEnterViewPool];
      rootViewPool.pushRootViewWithCategory(CK::makeNonNull(rootView),
                                            CK::makeNonNull(rootViewCategory));
    }
  }
  [rootViewHosts removeAllObjects];
}

static void tearDownAttachStateFromViews(NSArray<UIView *> *views,
                                         CK::Optional<CK::Component::RootViewPool> rootViewPool,
                                         NSHashTable<id<CKComponentRootViewHost>> *rootViewHosts)
{
  for (UIView *view in views) {
    CKComponentAttachState *attachState = CKGetAttachStateForView(view);
    if (attachState) {
      CKUnmountComponents(attachState.mountedComponents);
      CKSetAttachStateForView(view, nil);
    }
  }

  // Push root views to view pool when attach controller is deallocated.
  rootViewPool.apply([&](auto &rootViewPool) {
    pushRootViewsToViewPool(rootViewPool, rootViewHosts);
  });
}

@end


@implementation CKComponentAttachState
{
  CKComponentRootLayout _rootLayout;
  // The ownership isn't really shared with anyone, this is just to get copying the pointer in and out of the attach state easier
  std::shared_ptr<CK::AnimationApplicator<>> _animationApplicator;
  CK::DelayedNonNull<NSSet *> _mountedComponents;
}

- (instancetype)initWithScopeIdentifier:(CKComponentScopeRootIdentifier)scopeIdentifier
                      mountedComponents:(CK::NonNull<NSSet *>)mountedComponents
                    animationApplicator:(const std::shared_ptr<CK::AnimationApplicator<>> &)animationApplicator
{
  self = [super init];
  if (self) {
    _scopeIdentifier = scopeIdentifier;
    _mountedComponents = CK::makeNonNull([mountedComponents copy]);
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

- (CK::NonNull<NSSet *>)mountedComponents
{
  return _mountedComponents;
}

@end

static char const kViewAttachStateKey = ' ';

auto CKGetAttachStateForView(UIView *view) -> CKComponentAttachState *
{
  return CKGetAssociatedObject_MainThreadAffined(view, &kViewAttachStateKey);
}

auto CKSetAttachStateForView(UIView *view, CKComponentAttachState *attachState) -> void
{
  CKSetAssociatedObject_MainThreadAffined(view, &kViewAttachStateKey, attachState);
}
