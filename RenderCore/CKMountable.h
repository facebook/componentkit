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
#import <RenderCore/CKDefines.h>
#import <RenderCore/RCIterable.h>

#if CK_NOT_SWIFT

#import <RenderCore/ComponentMountContext.h>
#import <RenderCore/CKSizeRange.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CKMountable;

struct RCLayout;
struct RCLayoutChild;

struct CKComponentViewContext {
  __kindof UIView *_Nullable view;
  CGRect frame;
};

struct CKMountInfo {
  id<CKMountable> _Nullable supercomponent;
  UIView *_Nullable view;
  CKComponentViewContext viewContext;
};

@protocol CKMountable <RCIterable>

/**
 Call this on children components to compute their layouts.

 @param constrainedSize Specifies a minimum and maximum size. The receiver must choose a size that is in this range.
 @param parentSize The parent component's size. If the parent component does not have a final size in a given dimension,
 then it should be passed as kCKComponentParentDimensionUndefined (for example, if the parent's width
 depends on the child's size).

 @return A struct defining the layout of the receiver and its children.
 */
- (RCLayout)layoutThatFits:(CKSizeRange)constrainedSize
                parentSize:(CGSize)parentSize;

/**
 While the component is mounted, returns information about the component's manifestation in the view hierarchy.

 If this component creates a view, this method returns the view it created (or recycled) and a frame with origin 0,0
 and size equal to the view's bounds, since the component's size is the view's size.

 If this component does not create a view, returns the view this component is mounted within and the logical frame
 of the component's content. In this case, you should **not** make any assumptions about what class the view is.
 */
- (CKComponentViewContext)viewContext;

/** If the component owns its own view and is mounted, returns it. */
@property (nonatomic, readonly, nullable) UIView *mountedView;

/** If the component is mounted, returns it. */
@property (nonatomic, readonly) CKMountInfo mountInfo;

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
 @param layout The layout that is being mounted
 @param supercomponent This component's parent component
 @return An updated mount context. In most cases, this is just be the passed-in context. If a view was created, this is
 used to specify that subcomponents should be mounted inside the view.
 */
- (CK::Component::MountResult)mountInContext:(const CK::Component::MountContext &)context
                                      layout:(const RCLayout &)layout
                              supercomponent:(id<CKMountable> _Nullable)supercomponent;

/**
Unmounts the component:
- Clears the references to supercomponent and superview.
- If the component has a _mountedView:
  - Clears the view's reference back to this component using CKSetMountedComponentForView().
  - Clears _mountedView.
*/
- (void)unmount;

/**
 Called when the component and all its children have been mounted.
 */
- (void)childrenDidMount;

/** Unique identifier of the component */
@property (nonatomic, strong, readonly, nullable) id<NSObject> uniqueIdentifier;

/** Name of the component's class */
@property (nonatomic, copy, readonly) NSString *className;

@end

#else

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(Mountable)
@protocol CKMountable <RCIterable>
@end

#endif

NS_ASSUME_NONNULL_END
