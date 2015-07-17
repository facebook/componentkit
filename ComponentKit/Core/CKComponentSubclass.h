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

#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKComponentAnimation.h>
#import <ComponentKit/CKComponentBoundsAnimation.h>
#import <ComponentKit/CKComponentLayout.h>
#import <ComponentKit/CKDimension.h>

/** A constant that indicates that the parent's size is not yet determined in a given dimension. */
extern CGFloat const kCKComponentParentDimensionUndefined;

/** A constant that indicates that the parent's size is not yet determined in either dimension. */
extern CGSize const kCKComponentParentSizeUndefined;

@class CKComponentController;

@interface CKComponent ()

/**
 Called to get the component's initial state; the default implementation returns nil.
 @see CKComponentScopeFrame
 */
+ (id)initialState;

/**
 Call this on children components to compute their layouts within your implementation of -computeLayoutThatFits:.

 @warning You may not override this method. Override -computeLayoutThatFits: instead.

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
 Call this to enqueue a change to the state.

 The block takes the current state as a parameter and returns an instance of the new state.
 The state *must* be immutable since components themselves are. A possible use might be:

 [self updateState:^MyState *(MyState *currentState) {
   MyMutableState *nextState = [currentState mutableCopy];
   [nextState setFoo:[nextState bar] * 2];
   return [nextState copy]; // immutable! :D
 }];
 */
- (void)updateState:(id (^)(id))updateBlock;

/**
 Allows an action to be forwarded to another target. By default, returns the receiver if it implements action,
 and proceeds up the responder chain otherwise.
 */
- (id)targetForAction:(SEL)action withSender:(id)sender;

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

/** Returns the component's controller, if any. */
- (CKComponentController *)controller;

@end
