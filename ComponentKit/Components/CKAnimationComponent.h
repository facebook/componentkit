// Copyright 2004-present Facebook. All Rights Reserved.

#import <ComponentKit/CKDefines.h>

#if CK_NOT_SWIFT

#import <ComponentKit/CKAnimation.h>
#import <ComponentKit/CKCompositeComponent.h>
#import <ComponentKit/CKMacros.h>

/**
 @c CKAnimationComponent is a wrapper component similar to @c CKCompositeComponent, which allows developers to specify
 animations to be used as an initial mount animation and / or a final unmount animation. It can be used to
 provide animations to any component, even if it doesn't have a scope and / or a view.

 Instead of overriding a corresponding animation method in a component subclass or storing a reference to a child
 component in the parent in order to return an animation for it from one of the animation methods later, you just pass
 the component you want to animate to @c CKAnimationComponent initialiser:

 @code
 auto const anyComponent = [AnyComponent newWith...];
 [CKAnimationComponent
  newWithComponent:anyComponent
  onInitialMount:CK::Animation::alphaFrom(0)
  onFinalUnmount:CK::Animation::alphaTo(0)];
 */
@interface CKAnimationComponent : CKCompositeComponent

/**
 @param component Component to animate.
 @param initial Animation that will be applied to the component when it is first mounted.
 */
+ (instancetype)newWithComponent:(CKComponent *)component
                  onInitialMount:(CK::Animation::Initial)initial;

/**
 @param component Component to animate.
 @param final Animation that will be applied to the component when it is no longer in the mounted hierarchy.
 */
+ (instancetype)newWithComponent:(CKComponent *)component
                  onFinalUnmount:(CK::Animation::Final)final;

/**
 @param component Component to animate.
 @param initial Animation that will be applied to the component when it is first mounted.
 @param final Animation that will be applied to the component when it is no longer in the mounted hierarchy.
 */
+ (instancetype)newWithComponent:(CKComponent *)component
                  onInitialMount:(CK::Animation::Initial)initial
                  onFinalUnmount:(CK::Animation::Final)final;

+ (instancetype)newWithView:(const CKComponentViewConfiguration &)view size:(const CKComponentSize &)size CK_NOT_DESIGNATED_INITIALIZER_ATTRIBUTE;
+ (instancetype)newWithView:(const CKComponentViewConfiguration &)view component:(CKComponent *)component CK_NOT_DESIGNATED_INITIALIZER_ATTRIBUTE;
+ (instancetype)newWithComponent:(CKComponent *)component CK_NOT_DESIGNATED_INITIALIZER_ATTRIBUTE;

@end

#endif
