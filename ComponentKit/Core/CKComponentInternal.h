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

#import <memory>

#import <ComponentKit/CKBuildComponent.h>
#import <ComponentKit/ComponentMountContext.h>
#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKComponentLayout.h>
#import <ComponentKit/CKComponentScopeEnumeratorProvider.h>
#import <ComponentKit/CKTreeNodeProtocol.h>

@protocol CKSystraceListener;

@interface CKComponent () <CKTreeNodeComponentProtocol>

/**
 Mounts the component in the given context:
 - Stores references to the supercomponent and superview for -nextResponder and -viewConfiguration.
 - Creates or updates a controller for this component, if one should exist.
 - If this component has a view, creates or recycles a view by fetching one from the given MountContext, and:
   - Unmounts the view's previous component (if any).
   - Applies attributes to the view.
   - Stores a reference to the view in _mountedView (for -viewContext, transient view state, and -unmount).
   - Stores a reference back to this component using CKSetMountedComponentForView. (This sets up a
     retain cycle which must be torn down in -unmount.)

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
 For internal use only; don't use this directly.
 */
- (void)setViewConfiguration:(const CKComponentViewConfiguration &)viewConfiguration;

- (id)nextResponderAfterController;

- (void)didFinishComponentInitialization;

/**
 A CKComponentViewConfiguration specifies the class of a view and the attributes that should be applied to it.
 */
- (const CKComponentViewConfiguration &)viewConfiguration;

/** Used to get the root component in the responder chain; don't touch this. */
@property (nonatomic, weak) UIView *rootComponentMountedView;

/** The size that was passed into the component; don't touch this. */
@property (nonatomic, assign, readonly) CKComponentSize size;

/** Used to get the scope root enumerator; during component creation only */
@property (nonatomic, strong, readonly) id<CKComponentScopeEnumeratorProvider> scopeEnumeratorProvider;

/** For internal debug use only; don't touch this. */
@property (nonatomic, copy, readonly) NSString *backtraceStackDescription;

/** For internal use; don't touch this. */
@property (nonatomic, assign, readonly) BOOL hasAnimations;

/** For internal use; don't touch this. */
@property (nonatomic, assign, readonly) BOOL hasBoundsAnimations;

/** For internal use; don't touch this. */
@property (nonatomic, assign, readonly) BOOL controllerOverridesDidPrepareLayout;

/**
 Update component in controller right after new generation is created.
 NOTE: This should only be used by ComponentKit infra.
 */
@property (nonatomic, assign, readonly, class) BOOL shouldUpdateComponentInController;

@end

#endif
