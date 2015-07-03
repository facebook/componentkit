/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <UIKit/UIKit.h>

#import <ComponentKit/CKComponent.h>

/**
 A component that wraps another component, applying insets around it.

 If the child component has a size specified as a percentage, the percentage is resolved against this component's parent
 size **after** applying insets.

 @example CKOuterComponent contains an CKInsetComponent with an CKInnerComponent. Suppose that:
 - CKOuterComponent is 200pt wide.
 - CKInnerComponent specifies its width as 100%.
 - The CKInsetComponent has insets of 10pt on every side.
 CKInnerComponent will have size 180pt, not 200pt, because it receives a parent size that has been adjusted for insets.

 If you're familiar with CSS: CKInsetComponent's child behaves similarly to "box-sizing: border-box".

 An infinite inset is resolved as an inset equal to all remaining space after applying the other insets and child size.
 @example An CKInsetComponent with an infinite left inset and 10px for all other edges will position it's child 10px from the right edge.
 */
@interface CKInsetComponent : CKComponent

/** Convenience that calls +newWithView:insets:component: with {} for view. */
+ (instancetype)newWithInsets:(UIEdgeInsets)insets component:(CKComponent *)child;

/**
 @param view Passed to CKComponent +newWithView:size:. The view, if any, will extend outside the insets.
 @param insets The amount of space to inset on each side.
 @param component The wrapped child component to inset. If nil, this method returns nil.
 */
+ (instancetype)newWithView:(const CKComponentViewConfiguration &)view
                     insets:(UIEdgeInsets)insets
                  component:(CKComponent *)component;

@end
