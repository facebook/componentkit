/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <memory>

#import <ComponentKit/ComponentMountContext.h>
#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKComponentLayout.h>

@interface CKComponent ()

/**
 Mounts the component in the given context:
 - Stores references to the supercomponent and superview for -nextResponder and -viewConfiguration.
 - Creates or updates a controller for this component, if one should exist.
 - If this component has a view, creates or recycles a view by fetching one from the given MountContext, and:
   - Unmounts the view's previous component (if any).
   - Applies attributes to the view.
   - Stores a reference to the view in _mountedView (for -viewContext, transient view state, and -unmount).
   - Stores a reference back to this component in view.ck_component. (This sets up a retain cycle which must be torn
     down in -unmount.)

 Override this if your component wants to perform a custom mounting action, but this should be very rare!

 @param context The component's content should be positioned within the given view at the given position.
 @param size The size for this component
 @param children The positioned children for this component. Normally this parameter is ignored.
 @param supercomponent This component's parent component
 @return An updated mount context. In most cases, this is just be the passed-in context. If a view was created, this is
 used to specify that subcomponents should be mounted inside the view.
 */
- (CK::Component::MountResult)mountInContext:(const CK::Component::MountContext &)context
                                        size:(const CGSize)size
                                    children:(std::shared_ptr<const std::vector<CKComponentLayoutChild>>)children
                              supercomponent:(CKComponent *)supercomponent NS_REQUIRES_SUPER;

/**
 Unmounts the component:
 - Clears the references to supercomponent and superview.
 - If the component has a _mountedView:
   - Calls the unapplicator for any attributes that have one.
   - Clears the view's reference back to this component in ck_component.
   - Clears _mountedView.
 */
- (void)unmount;

- (const CKComponentViewConfiguration &)viewConfiguration;

- (id)nextResponderAfterController;

/** Called by the CKComponentLifecycleManager when the component and all its children have been mounted. */
- (void)childrenDidMount;

/** Called by the animation machinery. Do not access this externally. */
- (UIView *)viewForAnimation;

/** Used by CKComponentLifecycleManager to get the root component in the responder chain; don't touch this. */
@property (nonatomic, weak) UIView *rootComponentMountedView;

/** For internal use only; don't touch this. */
@property (nonatomic, strong, readonly) id<NSObject> scopeFrameToken;

@end

// Internal, for CKComponent
CKComponentLayout CKMemoizeOrComputeLayout(CKComponent *component, CKSizeRange constrainedSize, const CKComponentSize& size, CGSize parentSize);
