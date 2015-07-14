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

@interface CKComponentDataSourceAttachState : NSObject

@property (nonatomic, strong, readonly) NSSet *mountedComponents;
@property (nonatomic, readonly) CKComponentScopeRootIdentifier scopeIdentifier;

- (instancetype)initWithScopeIdentifier:(CKComponentScopeRootIdentifier)scopeIdentifier
                      mountedComponents:(NSSet *)mountedComponents;
@end

@interface UIView(CKComponentDataSourceAttachController)

@property (nonatomic, strong, setter=ck_setAttachState:) CKComponentDataSourceAttachState *ck_attachState;

@end

@implementation CKComponentDataSourceAttachController
{
  /**
   We keep a strong reference to the mounted view to enforce that every view
   being attached will have to be detached before the view is deallocated.
   */
  NSMutableDictionary *_scopeIdentifierToAttachedViewMap;
}

#pragma mark - Initialization/Teardown

- (instancetype)init
{
  self = [super init];
  if (self) {
    _scopeIdentifierToAttachedViewMap = [NSMutableDictionary dictionary];
  }
  return self;
}

- (void)dealloc
{
  CKAssert([[NSThread currentThread] isMainThread], @"This object is affined to the main thread and should be deallocated from the main thread.");
  [self _detachAllViews];
}

#pragma mark - Public API

- (void)attachComponentLayout:(CKComponentLayout)layout
          withScopeIdentifier:(CKComponentScopeRootIdentifier)scopeIdentifier
                       toView:(UIView *)view
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
  CKComponentDataSourceAttachState *attachState = _mountComponentLayoutInView(layout, view, scopeIdentifier);
  // Mark the view as attached and associates it to the right attach state
  _scopeIdentifierToAttachedViewMap[@(scopeIdentifier)] = attachState;
  view.ck_attachState = attachState;
}

- (void)detachComponentLayoutWithScopeIdentifier:(CKComponentScopeRootIdentifier)scopeIdentifier
{
  CKAssertMainThread();
  [self _detachComponentLayoutFromView:[_scopeIdentifierToAttachedViewMap objectForKey:@(scopeIdentifier)]];
}

#pragma mark - Attach helpers

- (void)_detachAllViews
{
  NSArray *views = [_scopeIdentifierToAttachedViewMap allValues];
  for (UIView *view in views) {
    [self _detachComponentLayoutFromView:view];
  }
}

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

CKComponentDataSourceAttachState *_mountComponentLayoutInView(CKComponentLayout layout,
                                                              UIView *view,
                                                              CKComponentScopeRootIdentifier scopeIdentifier)
{
  CKCAssertNotNil(view, @"Impossible to mount a component layout on a nil view");
  NSSet *currentlyMountedComponents = view.ck_attachState.mountedComponents;
  NSSet *newMountedComponents = CKMountComponentLayout(layout, view, currentlyMountedComponents, nil);
  return [[CKComponentDataSourceAttachState alloc] initWithScopeIdentifier:scopeIdentifier mountedComponents:newMountedComponents];
}

@end


@implementation CKComponentDataSourceAttachState

- (instancetype)initWithScopeIdentifier:(CKComponentScopeRootIdentifier)scopeIdentifier
                      mountedComponents:(NSSet *)mountedComponents
{
  self = [super init];
  if (self) {
    CKAssertNotNil(mountedComponents, @"");
    _scopeIdentifier = scopeIdentifier;
    _mountedComponents = [mountedComponents copy];
  }
  return self;
}

@end

@implementation UIView(CKComponentDataSourceAttachController)

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
