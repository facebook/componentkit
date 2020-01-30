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

#import <vector>

#import <UIKit/UIKit.h>
#import <ComponentKit/CKComponentControllerProtocol.h>
#import <ComponentKit/CKComponentLayout.h>
#import <ComponentKit/CKComponent.h>

@class CKComponent;

@interface CKComponentController<__covariant ComponentType:CKComponent *> : NSObject <CKComponentControllerProtocol>

/** The controller was initialised. Called on the main thread. */
- (void)didInit NS_REQUIRES_SUPER;

/** The controller's component is not mounted, but is about to be. */
- (void)willMount NS_REQUIRES_SUPER;

/** The controller's component was not previously mounted, but now it is (including all of its children). */
- (void)didMount NS_REQUIRES_SUPER;

/**
 The controller's component is mounted and is about to be mounted again. This can happen in two scenarios:
 1. The component is updating. In that case, the controller has already received a call to -willUpdateComponent, and
    the component property already reflects the updated component that will be mounted.
 2. The root component is being attached to a different root view.
 */
- (void)willRemount NS_REQUIRES_SUPER;

/** The controller's component was mounted after a call to willRemount. */
- (void)didRemount NS_REQUIRES_SUPER;

/** The controller's component is mounted, but is about to be unmounted. */
- (void)willUnmount NS_REQUIRES_SUPER;

/** The controller's component was previously mounted, but now it no longer is. */
- (void)didUnmount NS_REQUIRES_SUPER;

/** If the controller's component is changing, invoked immediately before the updated component is mounted. */
- (void)willUpdateComponent NS_REQUIRES_SUPER;

/** If the controller's component has changed, invoked immediately after the updated component is mounted. */
- (void)didUpdateComponent NS_REQUIRES_SUPER;

/** Invoked immediately after the component has acquired a view. */
- (void)componentDidAcquireView NS_REQUIRES_SUPER;

/** Invoked immediately before the component relinquishes its view to be reused by other components. */
- (void)componentWillRelinquishView NS_REQUIRES_SUPER;

/**
 As suggested in name, this lifecycle method will only be called when the entire component tree will appear on screen.
 That means if a component tree has already appeared on screen and it's still visible, a component that is added to this
 component tree hierarchy will not have this lifecycle method called.
 NOTE:
 - In the context of `UICollectionView`, this corresponds to `willDisplayCell:forItemAtIndexPath:`.
 - In the context of `CKComponentHostingView`, this corresponds to `hostingViewWillAppear`.
 */
- (void)componentTreeWillAppear NS_REQUIRES_SUPER;

/**
 As suggested in name, this lifecycle method will only be called when the entire component tree did disappear.
 That means if a component is removed from its component tree hierarchy, this lifecycle method will not be called.
 NOTE:
 - In the context of `UICollectionView`, this corresponds to `didEndDisplayingCell:forItemAtIndexPath:`.
 - In the context of `CKComponentHostingView`, this corresponds to `hostingViewDidDisappear`.
 */
- (void)componentTreeDidDisappear NS_REQUIRES_SUPER;

/** Called on the main thread prior to controller deallocation **/
- (void)invalidateController NS_REQUIRES_SUPER;

/**
 Called on the main thread when a new component has been created and its layout has been calculated.
 This layout will be used during the next mount (unless another state update will be triggered).
 */
- (void)didPrepareLayout:(const CKComponentLayout &)layout forComponent:(CKComponent *)component;

/** The current version of the component. */
@property (nonatomic, weak, readonly) ComponentType component;

/** The view created by the component, if currently mounted. */
@property (nonatomic, strong, readonly) UIView *view;

/**
 This returns the component that was last mounted. It can be `nil` if the latest generation hasn't been mounted.
 NOTE: this is for code migration purpose, please DO NOT USE.
 */
- (ComponentType)lastMountedComponent;

/**
 While the controller's component is mounted, returns its next responder. This is the first of:
 - The supercomponent of the controller's component;
 - The view the controller's component is mounted within, if it is the root component.
 */
- (id)nextResponder;

/**
 When an action is triggered, a component controller may use this method to either capture or ignore the given action.
 The default implementation simply uses respondsToSelector: to determine if the controller can perform the given action.

 In practice, this is useful only for integrations with UIMenuController whose API walks the UIResponder chain to
 determine which menu items to display. You should not override this method for standard component actions.
 */
- (BOOL)canPerformAction:(SEL)action withSender:(id)sender;

/**
 Initializes a controller with the first generation of component. You should not directly initialize a controller,
 they are initialized for you by the infrastructure.
 */
- (instancetype)initWithComponent:(ComponentType)component NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

#endif
