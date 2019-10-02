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

#import <ComponentKit/ComponentMountContext.h>
#import <ComponentKit/CKComponentLayout.h>
#import <ComponentKit/CKComponentProtocol.h>
#import <ComponentKit/CKComponentSize.h>

@protocol CKComponentControllerProtocol;
@protocol CKSystraceListener;

struct CKComponentLayoutChild;

struct CKComponentViewContext {
  __kindof UIView *view;
  CGRect frame;
};

@protocol CKMountable <NSObject>

/**
 Call this on children components to compute their layouts within your implementation of -computeLayoutThatFits:.

 @warning You may not override this method. Override -computeLayoutThatFits: instead.
 @warning In almost all cases, prefer the use of CKComputeComponentLayout in CKComponentLayout

 @param constrainedSize Specifies a minimum and maximum size. The receiver must choose a size that is in this range.
 @param parentSize The parent component's size. If the parent component does not have a final size in a given dimension,
 then it should be passed as kCKComponentParentDimensionUndefined (for example, if the parent's width
 depends on the child's size).

 @return A struct defining the layout of the receiver and its children.
 */
- (CKComponentLayout)layoutThatFits:(CKSizeRange)constrainedSize
                         parentSize:(CGSize)parentSize;

/**
 Override this method to compute your component's layout.

 @discussion Why do you need to override -computeLayoutThatFits: instead of -layoutThatFits:parentSize:?
 The base implementation of -layoutThatFits:parentSize: does the following for you:
 1. First, it uses the parentSize parameter to resolve the component's size (the one passed into -initWithView:size:).
 2. Then, it intersects the resolved size with the constrainedSize parameter. If the two don't intersect,
 constrainedSize wins. This allows a component to always override its childrens' sizes when computing its layout.
 (The analogy for UIView: you might return a certain size from -sizeThatFits:, but a parent view can always override
 that size and set your frame to any size.)

 @param constrainedSize A min and max size. This is computed as described in the description. The CKComponentLayout you
 return MUST have a size between these two sizes. This is enforced by assertion.
 */
- (CKComponentLayout)computeLayoutThatFits:(CKSizeRange)constrainedSize;

/**
 CKComponent's implementation of -layoutThatFits:parentSize: calls this method to resolve the component's size
 against parentSize, intersect it with constrainedSize, and call -computeLayoutThatFits: with the result.

 In certain advanced cases, you may want to customize this logic. Overriding this method allows you to receive all
 three parameters and do the computation yourself.

 @warning Overriding this method should be done VERY rarely.
 */
- (CKComponentLayout)computeLayoutThatFits:(CKSizeRange)constrainedSize
                          restrictedToSize:(const CKComponentSize &)size
                      relativeToParentSize:(CGSize)parentSize;


/**
 While the component is mounted, returns information about the component's manifestation in the view hierarchy.

 If this component creates a view, this method returns the view it created (or recycled) and a frame with origin 0,0
 and size equal to the view's bounds, since the component's size is the view's size.

 If this component does not create a view, returns the view this component is mounted within and the logical frame
 of the component's content. In this case, you should **not** make any assumptions about what class the view is.
 */
- (CKComponentViewContext)viewContext;

/**
 A CKComponentViewConfiguration specifies the class of a view and the attributes that should be applied to it.
 */
- (const CKComponentViewConfiguration &)viewConfiguration;

/** Used to get the root component in the responder chain; don't touch this. */
@property (nonatomic, weak) UIView *rootComponentMountedView;

/** If the component owns its own view and is mounted, returns it. */
@property (nonatomic, readonly) UIView *mountedView;

/** Backward Compatibility */
- (UIView *)viewForAnimation;

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
 @param systraceListener The current systrace listener - will be nil if systrace is not enabled.
 @return An updated mount context. In most cases, this is just be the passed-in context. If a view was created, this is
 used to specify that subcomponents should be mounted inside the view.
 */
- (CK::Component::MountResult)mountInContext:(const CK::Component::MountContext &)context
                                        size:(const CGSize)size
                                    children:(std::shared_ptr<const std::vector<CKComponentLayoutChild>>)children
                              supercomponent:(id<CKMountable>)supercomponent
                            systraceListener:(id<CKSystraceListener>)systraceListener;

/**
 Called when the component and all its children have been mounted.

 @param systraceListener The current systrace listener - will be nil if systrace is not enabled.
 */
- (void)childrenDidMount:(id<CKSystraceListener>)systraceListener;


/** Unique identifier of the component - can be nil */
@property (nonatomic, strong, readonly) id<NSObject> uniqueIdentifier;

/** Backward Compatibility */
- (id<CKComponentControllerProtocol>)controller;

@end
