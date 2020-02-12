/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKDefines.h>

#if CK_NOT_SWIFT

#import <Foundation/Foundation.h>

#import <ComponentKit/CKComponentLayout.h>
#import <ComponentKit/CKComponentRootViewInternal.h>
#import <ComponentKit/CKComponentScopeRoot.h>
#import <ComponentKit/CKNonNull.h>
#import <ComponentKit/ComponentRootViewPool.h>

@protocol CKComponentRootLayoutProvider;

/**
 @brief This controller can be used to manage attaching and detaching a component trees to a view.

 Along with dealing with mounting and unmounting component trees to a view it also enforces the two following constraints:
 1) One and only one component tree with the same scope identifier is attached to a view
 2) Component trees with different scope identifiers cannot be attached to the same view

 @warning This controller is affined to the main thread, all the methods should be called on the main thread and it should never
 cross a thread boundary.
 */
@interface CKComponentAttachController : NSObject

/**
 Detaching a component tree will cause it to be unmounted from the view it is currently attached to and will mark the view as available to be
 attached again to a component tree.
 */
- (void)detachComponentLayoutWithScopeIdentifier:(CKComponentScopeRootIdentifier)identifier;

/**
 Detach all previously attached components.
 */
- (void)detachAll;

/**
 A root view pool that is used for attaching component layout when `CKComponentAttachableView` is passed in.
 @see CKComponentAttachableView
 */
- (void)setRootViewPool:(CK::Component::RootViewPool)rootViewPool;

/**
 Calling this method pushes all root views that this attach controller holds to the root view pool immediately
 instead of pushing them upon deallocation.
 */
- (void)pushRootViewsToViewPool;

@end

/**
 This is used as unified parameter of a attachable view. It could be either a `UIView` or a `CKComponentRootViewHost`.
 When a `CKComponentRootViewHost` is used, it's expected to reuse view from a `CK::Component::RootViewPool`.
 */
struct CKComponentAttachableView {
  CKComponentAttachableView(UIView *view) :
  _view(view),
  _rootViewHost(nil),
  _rootViewCategory(nil) {};

  CKComponentAttachableView(CK::NonNull<id<CKComponentRootViewHost>> rootViewHost,
                            CK::NonNull<NSString *> rootViewCategory) :
  _view(nil),
  _rootViewHost(rootViewHost),
  _rootViewCategory(rootViewCategory) {};

  template <typename ViewFunc, typename RootViewHostFunc>
  CK::NonNull<UIView *> match(ViewFunc viewFunc, RootViewHostFunc rootViewHostFunc) const {
    if (_view) {
      return viewFunc(CK::makeNonNull(_view));
    } else {
      return rootViewHostFunc(CK::makeNonNull(_rootViewHost), CK::makeNonNull(_rootViewCategory));
    }
  }

private:
  UIView *_view;
  id<CKComponentRootViewHost> _rootViewHost;
  NSString *_rootViewCategory;
};

/**
 Attaching a component tree to a view, the controller will:
 1) Detach the component tree from the view it is currently attached to, if it is already attached to a view.
 2) Detach the component tree currently attached to the view, if and only if the component tree currently attached has a different
 scope identifier.

 @field rootLayout The component (and layout) tree to attach.
 @field view The view to attach the component tree to
 @field scopeIdentifier The scope identifier for the component tree, this identifier should be stable among multiple versions
 of the component tree representing the same logical item.
 */
struct CKComponentAttachControllerAttachComponentRootLayoutParams {
  const id<CKComponentRootLayoutProvider> layoutProvider;
  CKComponentScopeRootIdentifier scopeIdentifier;
  const CKComponentBoundsAnimation &boundsAnimation;
  const CKComponentAttachableView view;
  id<CKAnalyticsListener> analyticsListener;
  BOOL isUpdate;
};

void CKComponentAttachControllerAttachComponentRootLayout(
    CKComponentAttachController *const self,
    const CKComponentAttachControllerAttachComponentRootLayoutParams &params);

#endif
