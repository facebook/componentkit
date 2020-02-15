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

#import <ComponentKit/CKDefines.h>
#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKComponentAnimation.h>
#import <ComponentKit/CKComponentBoundsAnimation.h>
#import <ComponentKit/CKComponentLayout.h>
#import <ComponentKit/CKDimension.h>
#import <ComponentKit/CKUpdateMode.h>

NS_ASSUME_NONNULL_BEGIN

/** A constant that indicates that the parent's size is not yet determined in a given dimension. */
extern CGFloat const kCKComponentParentDimensionUndefined;

/** A constant that indicates that the parent's size is not yet determined in either dimension. */
extern CGSize const kCKComponentParentSizeUndefined;

@class CKComponentController;

@interface CKComponent ()

#if CK_NOT_SWIFT

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
 constrainedSize wins. This allows a component to always override its children's sizes when computing its layout.
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

#endif

/**
 Returns the component's state if available.
 Can be called only *after* the component's creation is done.
 */
- (id _Nullable)state;

/**
 Enqueue a change to the state.

 The state must be immutable since components themselves are. A possible use might be:

   [self updateState:^MyState *(MyState *currentState) {
     MyMutableState *nextState = [currentState mutableCopy];
     [nextState setFoo:[nextState bar] * 2];
     return [nextState copy]; // immutable! :D
   }];

 @param updateBlock A block that takes the current state as a parameter and returns an instance of the new state.
 @param mode The update mode used to apply the state update.
 @@see CKUpdateMode
 */
- (void)updateState:(id _Nullable (^)(id _Nullable currentState))updateBlock mode:(CKUpdateMode)mode;

/**
 Allows an action to be forwarded to another target. By default, returns the receiver if it implements action,
 and proceeds up the responder chain otherwise.
 */
- (id _Nullable)targetForAction:(SEL _Nullable)action withSender:(id _Nullable)sender;

/**
 When an action is triggered, a component may use this method to either capture or ignore the given action. The default
 implementation simply uses respondsToSelector: to determine if the component can perform the given action.

 In practice, this is useful only for integrations with UIMenuController whose API walks the UIResponder chain to
 determine which menu items to display. You should not override this method for standard component actions.
 */
- (BOOL)canPerformAction:(SEL _Nullable)action withSender:(id _Nullable)sender;

#if CK_NOT_SWIFT

/**
 Override to return a list of animations that will be applied to the component when it is first mounted.

 @warning If you override this method, your component MUST declare a scope (see CKComponentScope). This is used to
 identify equivalent components between trees.
 */
- (std::vector<CKComponentAnimation>)animationsOnInitialMount;

/**
 Override to return a list of animations from the previous version of the same component.

 @warning If you override this method, your component MUST declare a scope (see CKComponentScope). This is used to
 identify equivalent components between trees.
 */
- (std::vector<CKComponentAnimation>)animationsFromPreviousComponent:(CKComponent *)previousComponent;

/**
 Override to return how the change to the bounds of the root component should be animated when updating the hierarchy.

 @see CKComponentBoundsAnimation

 @warning If you override this method, your component MUST declare a scope (see CKComponentScope). This is used to
 identify equivalent components between trees.
 */
- (CKComponentBoundsAnimation)boundsAnimationFromPreviousComponent:(CKComponent *)previousComponent;

/**
 **Experimental API, do not use**

 Override to return the list of component / animation pairs that will run when this component is no longer in the mounted
 hierarchy. You can return multiple animations for this component or specify animations for any child components.

 @warning If you override this method, your component MUST declare a scope (see CKComponentScope). This is used to
 identify equivalent components between trees.
 */
- (std::vector<CKComponentFinalUnmountAnimation>)animationsOnFinalUnmount;

#endif

/**
 Attempts to return a view suitable for rendering an animation.

 Since a component may or may not be backed by a view nil may be returned. Composite components may, given the fact
 they are composed of other components, return the animatable view of its descendant. As a rule of thumb:

 1. CKComponent subclasses backed by a view will return the backing view
 2. CKComponent subclasses not backed by a view will return nil
 3. CKCompositeComponent subclasses backed by a view will return the backing view
 4. CKCompositeComponent subclasses not backed by a view will return the animatable view of its descendant

 This method may be overridden in rare situations where a more suitable view should be used for rendering animations.
 */
@property (nonatomic, strong, readonly, nullable) UIView *viewForAnimation;

/** Returns the component's controller, if any. */
- (CKComponentController *_Nullable)controller;

@end

NS_ASSUME_NONNULL_END
