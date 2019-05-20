// Copyright 2004-present Facebook. All Rights Reserved.

#import <ComponentKit/CKAnimation.h>
#import <ComponentKit/CKCompositeComponent.h>
#import <ComponentKit/CKMacros.h>

struct CKAnimationComponentOptions {
  /* Animation that will be applied to the component when it is first mounted. Optional. */
  CAAnimation *animationOnInitialMount;
  /* Animation that will be applied to the component when it is no longer in the mounted hierarchy. Optional. */
  CAAnimation *animationOnFinalUnmount;
};

/**
 CKAnimationComponent is a wrapper component similar to CKCompositeComponent, which allows developers to specify
 instances of CAAnimation to be used as an initial mount animation or a final unmount animation. It can be used to
 provide animations to any component, even if it doesn't have a scope and / or a view.

 Instead of overriding a corresponding animation method in a component subclass or storing a reference to a child
 component in the parent in order to return an animation for it from one of the animation methods later, you just pass
 the component you want to animate to CKAnimationComponent initialiser:

 @code
 auto const anyComponent = [CKComponent newWith...];
 [CKAnimationComponent
   newWithComponent:anyComponent
   options:{
     .animationOnInitialMount = [CABasicAnimation animationForKeyPath...]
   }];
 */
@interface CKAnimationComponent : CKCompositeComponent

+ (instancetype)newWithView:(const CKComponentViewConfiguration &)view size:(const CKComponentSize &)size CK_NOT_DESIGNATED_INITIALIZER_ATTRIBUTE;
+ (instancetype)newWithView:(const CKComponentViewConfiguration &)view component:(CKComponent *)component CK_NOT_DESIGNATED_INITIALIZER_ATTRIBUTE;
+ (instancetype)newWithComponent:(CKComponent *)component CK_NOT_DESIGNATED_INITIALIZER_ATTRIBUTE;

/**
 @param component component to animate
 @param options a struct specifying animations to be applied
 */
+ (instancetype)newWithComponent:(CKComponent *)component
                         options:(CKAnimationComponentOptions)options;

@end

namespace CK {
  struct AnimationComponentFor {
    AnimationComponentFor(CKComponent *component) :_component(component) {}

    template <typename A>
    auto &onInitialMount(A a)
    {
      static_assert(A::type == Animation::Type::initial, "Animation on initial mount should come from CK::Animation::Initial namespace");
      _animationOnInitialMount = a.toCA();
      return *this;
    };

    template <typename A>
    auto &onFinalUnmount(A a)
    {
      static_assert(A::type == Animation::Type::final, "Animation on final unmount should come from CK::Animation::Final namespace");
      _animationOnFinalUnmount = a.toCA();
      return *this;
    }

    auto build() const -> CKAnimationComponent *;

    operator CKComponent *() const
    {
      return build();
    }

  private:
    CKComponent *_component;
    CAAnimation *_animationOnInitialMount;
    CAAnimation *_animationOnFinalUnmount;
  };
}
