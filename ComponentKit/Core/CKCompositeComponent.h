/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKComponent.h>

/**
 CKCompositeComponent allows you to hide your implementation details and avoid subclassing layout components like
 CKStackLayoutComponent. In almost all cases, you should subclass CKCompositeComponent instead of subclassing any other
 class directly.

 For example, suppose you create a component that should lay out some children in a vertical stack.
 Incorrect: subclass CKStackLayoutComponent and call `self newWithChildren:`.
 Correct: subclass CKCompositeComponent and call `super newWithComponent:[CKStackLayoutComponent newWithChildren...`

 This hides your layout implementation details from the outside world.

 @warning Overriding -layoutThatFits:parentSize: or -computeLayoutThatFits: is **not allowed** for any subclass.
 */
@interface CKCompositeComponent : CKComponent

/** Calls the initializer with {} for view. */
+ (instancetype)newWithComponent:(CKComponent *)component;

/**
 @param view Passed to CKComponent's initializer. This should be used sparingly for CKCompositeComponent. Prefer
 delegating view configuration completely to the child component to hide implementation details.
 @param component The component the composite component uses for layout and sizing.
 */
+ (instancetype)newWithView:(const CKComponentViewConfiguration &)view component:(CKComponent *)component;

@end
