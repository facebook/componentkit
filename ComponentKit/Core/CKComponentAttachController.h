/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <Foundation/Foundation.h>

#import <ComponentKit/CKComponentLayout.h>
#import <ComponentKit/CKComponentScopeRoot.h>

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

@end

/**
 Attaching a component tree to a view, the controller will:
 1) Detach the component tree from the view it is currently attached to, if it is already attached to a view.
 2) Detach the component tree currently attached to the view, if and only if the component tree currently attached has a different
 scope identifier.

 @param rootLayout The component (and layout) tree to attach.
 @param view The view to attach the component tree to
 @param scopeIdentifier The scope identifier for the component tree, this identifier should be stable among multiple versions
 of the component tree representing the same logical item.
 */
struct CKComponentAttachControllerAttachComponentRootLayoutParams {
  const id<CKComponentRootLayoutProvider> layoutProvider;
  CKComponentScopeRootIdentifier scopeIdentifier;
  const CKComponentBoundsAnimation &boundsAnimation;
  UIView *view;
  id<CKAnalyticsListener> analyticsListener;
  BOOL isUpdate;
};

void CKComponentAttachControllerAttachComponentRootLayout(
    const CKComponentAttachController *const self,
    const CKComponentAttachControllerAttachComponentRootLayoutParams &params);
