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

#import <UIKit/UIKit.h>

#import <ComponentKit/CKAssert.h>

typedef NS_ENUM(NSInteger, CKComponentBoundsAnimationMode) {
  /** Wraps changes in a UIView animation block */
  CKComponentBoundsAnimationModeDefault = 0,
  /** Wraps changes in a UIView spring animation block */
  CKComponentBoundsAnimationModeSpring,
};

@class CKComponent;

/**
 Specifies how to animate a change to the component tree.

 There are two ways to trigger a change to the component tree: a call to -updateState: within a component, or a change
 to the model (by enqueueing an update to the data source or calling [CKComponentHostingView -setModel:]).

 When the view hierarchy is updated to reflect the new component tree, -boundsAnimationFromPreviousComponent: is called
 on every component in the new tree that has an equivalent in the old tree. If any component returns a bounds animation
 with a duration that is non-zero, the change will be animated. If different components return conflicting animation
 settings, the result is undefined.

 Changes to components that are offscreen in a UICollectionView or UITableView are never animated.

 @warning UITableView does not support customizing its animation in any way. CKComponentTableViewDataSource animates
 the change using UITableView's defaults if duration is non-zero, ignoring all other parameters.
 */
struct CKComponentBoundsAnimation {
  NSTimeInterval duration;
  NSTimeInterval delay;
  CKComponentBoundsAnimationMode mode;
  UIViewAnimationOptions options;

  /** `UIViewAnimationOptionCurve` in `options` will be ignored if this is specified */
  CAMediaTimingFunction *timingFunction;
  /** Ignored unless mode is Spring, in which case it specifies the damping ratio passed to UIKit. */
  CGFloat springDampingRatio;
  /** Ignored unless mode is Spring, in which case it specifies the initial velocity passed to UIKit. */
  CGFloat springInitialVelocity;
#if CK_ASSERTIONS_ENABLED
  __weak CKComponent *component;
#endif
  void (^completion)();
};

auto operator ==(const CKComponentBoundsAnimation &lhs, const CKComponentBoundsAnimation &rhs) -> bool;
auto operator !=(const CKComponentBoundsAnimation &lhs, const CKComponentBoundsAnimation &rhs) -> bool;

/**
 Wraps the given block in the correct UIView animation block for a given bounds animation.
 If duration is zero, wraps [UIView +performWithoutAnimation:].
 If mode is Default, wraps [UIView +animateWithDuration:...].
 If mode is Spring, wraps [UIView +animateWithDuration:delay:usingSpringWithDamping:...]
 */
void CKComponentBoundsAnimationApply(const CKComponentBoundsAnimation &animation,
                                     void (^animations)(void),
                                     void (^completion)(BOOL finished));

#endif
