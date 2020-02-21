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

NS_ASSUME_NONNULL_BEGIN

/**
 CKCompositeComponent allows you to hide your implementation details and avoid subclassing layout components like
 CKFlexboxComponent. In almost all cases, you should subclass CKCompositeComponent instead of subclassing any other
 class directly.

 For example, suppose you create a component that should lay out some children in a vertical stack.
 Incorrect: subclass CKFlexboxComponent and call `self newWithChildren:`.
 Correct: subclass CKCompositeComponent and call `super newWithComponent:[CKFlexboxComponent newWithChildren...`

 This hides your layout implementation details from the outside world.

 @warning Overriding -layoutThatFits:parentSize: or -computeLayoutThatFits: is **not allowed** for any subclass.
 */
NS_SWIFT_NAME(CompositeComponent)
@interface CKCompositeComponent : CKComponent

CK_COMPONENT_INIT_UNAVAILABLE;

// TODO: Remove when `-initWithView:component` is exposed to Swift.
- (instancetype _Nullable)initWithComponent:(NS_RELEASES_ARGUMENT CKComponent *_Nullable)component CK_SWIFT_DESIGNATED_INITIALIZER;

#if CK_NOT_SWIFT

- (instancetype _Nullable)initWithView:(const CKComponentViewConfiguration &)view
                             component:(NS_RELEASES_ARGUMENT CKComponent  * _Nullable)component NS_DESIGNATED_INITIALIZER;

/** Calls the initializer with {} for view. */
+ (instancetype _Nullable)newWithComponent:(NS_RELEASES_ARGUMENT CKComponent * _Nullable)component;

/**
 @param view Passed to CKComponent's initializer. This should be used sparingly for CKCompositeComponent. Prefer
 delegating view configuration completely to the child component to hide implementation details.
 @param component The component the composite component uses for layout and sizing.
 */
+ (instancetype _Nullable)newWithView:(const CKComponentViewConfiguration &)view component:(NS_RELEASES_ARGUMENT CKComponent  * _Nullable)component;

#endif

/** Access the child component. For internal use only. */
@property (nonatomic, strong, readonly, nullable) CKComponent *child;

@end

#if CK_SWIFT
#define CK_COMPOSITE_COMPONENT_INIT_UNAVAILABLE \
  - (instancetype _Nullable)initWithComponent:(NS_RELEASES_ARGUMENT CKComponent *_Nullable)component NS_UNAVAILABLE
#else
#define CK_COMPOSITE_COMPONENT_INIT_UNAVAILABLE \
  - (instancetype _Nullable)initWithView:(const CKComponentViewConfiguration &)view \
                               component:(NS_RELEASES_ARGUMENT CKComponent  * _Nullable)component NS_UNAVAILABLE; \
  + (instancetype _Nullable)newWithComponent:(NS_RELEASES_ARGUMENT CKComponent * _Nullable)component NS_UNAVAILABLE; \
  + (instancetype _Nullable)newWithView:(const CKComponentViewConfiguration &)view component:(NS_RELEASES_ARGUMENT CKComponent  * _Nullable)component NS_UNAVAILABLE;
#endif

NS_ASSUME_NONNULL_END

#import <ComponentKit/CompositeComponentBuilder.h>
