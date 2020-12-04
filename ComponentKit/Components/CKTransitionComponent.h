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

#import <ComponentKit/ComponentBuilder.h>
#import <ComponentKit/CKIdValueWrapper.h>

namespace CK {
namespace BuilderDetails {
namespace TransitionComponentPropId {
constexpr static auto component = BuilderBasePropId::__max << 1;
constexpr static auto hasTransition = component << 1;
constexpr static auto hasTrigger = hasTransition << 1;
constexpr static auto __max = hasTransition;
}

namespace TransitionComponentDetails {
auto factory(CKComponent *, const Optional<Animation::Initial> &, const Optional<Animation::Final> &, id<NSObject>) -> CKComponent *;
}

template <PropsBitmapType PropsBitmap = 0>
class __attribute__((__may_alias__)) TransitionComponentBuilder
: public BuilderBase<TransitionComponentBuilder, PropsBitmap> {
public:
  TransitionComponentBuilder() = default;
  TransitionComponentBuilder(const CK::ComponentSpecContext &context) : BuilderBase<TransitionComponentBuilder, PropsBitmap>{context} { }

  ~TransitionComponentBuilder() = default;

  /**
   A child component that will transition between states in an animated fashion.
   */
  auto &component(NS_RELEASES_ARGUMENT CKComponent *c)
  {
    constexpr auto componentIsNotSet = !PropBitmap::isSet(PropsBitmap, TransitionComponentPropId::component);
    static_assert(componentIsNotSet, "Property 'component' is already set.");
    _component = c;
    return reinterpret_cast<
    TransitionComponentBuilder<PropsBitmap | TransitionComponentPropId::component> &>(*this);
  }

  /**
   An animation to apply to the new generation of the child component.
   */
  auto &transitioningIn(Animation::Initial i)
  {
    _initial = std::move(i);
    return reinterpret_cast<
    TransitionComponentBuilder<PropsBitmap | TransitionComponentPropId::hasTransition> &>(*this);
  }

  /**
  An animation to apply to the previous generation of the child component.
  */
  auto &transitioningOut(Animation::Final f)
  {
    _final = std::move(f);
    return reinterpret_cast<
    TransitionComponentBuilder<PropsBitmap | TransitionComponentPropId::hasTransition> &>(*this);
  }

  /**
   A value changes in which are used to trigger the transition.

   @note  @c CKObjectIsEqual is used to compare the previous and the new value.
   */
  auto &triggerValue(NS_RELEASES_ARGUMENT id<NSObject> triggerValue)
  {
    _triggerValue = triggerValue;
    return reinterpret_cast<
    TransitionComponentBuilder<PropsBitmap | TransitionComponentPropId::hasTrigger> &>(*this);
  }

  /**
   A value changes in which are used to trigger the transition.

   @note  @c T::operator == is used to compare the previous and the new value.
   */
  template <typename T>
  auto &triggerValue(T triggerValue)
  {
    _triggerValue = CKIdValueWrapperCreate<T>(triggerValue);
    return reinterpret_cast<
    TransitionComponentBuilder<PropsBitmap | TransitionComponentPropId::hasTrigger> &>(*this);
  }

private:
  friend BuilderBase<TransitionComponentBuilder, PropsBitmap>;

  /**
   Creates a new component instance with specified properties.

   @note  This method must @b not be called more than once on a given component builder instance.
   */
  NS_RETURNS_RETAINED auto _build() noexcept -> CKComponent *
  {
    constexpr auto componentIsSet = PropBitmap::isSet(PropsBitmap, TransitionComponentPropId::component);
    static_assert(componentIsSet, "Required property 'component' is not set.");
    constexpr auto hasTransition = PropBitmap::isSet(PropsBitmap, TransitionComponentPropId::hasTransition);
    static_assert(hasTransition, "At least one transition must be specified using 'transitioningIn' or 'transitioningOut'.");
    constexpr auto hasTrigger = PropBitmap::isSet(PropsBitmap, TransitionComponentPropId::hasTrigger);
    static_assert(hasTrigger, "At least one trigger must be specified using 'triggerValue'.");

    return TransitionComponentDetails::factory(_component, _initial, _final, _triggerValue);
  }

private:
  CKComponent *_component;
  Optional<Animation::Initial> _initial{};
  Optional<Animation::Final> _final{};
  id<NSObject> _triggerValue;
};

}

using TransitionComponentBuilderEmpty = BuilderDetails::TransitionComponentBuilder<>;
using TransitionComponentBuilderContext = BuilderDetails::TransitionComponentBuilder<BuilderDetails::BuilderBasePropId::context>;

/**
 The component that allows its child component to transition to a new state in an animated fashion when a specified trigger value changes. The previous and the
 current visual appearance can be animated independently of each other by passing both \c transitioningIn and \c transitioningOut .

 @example A text component that, when the text is changed, fades the previous text out and slides the new text from the bottom:
 @code
 TransitionComponentBuilder()
 .component(textComponent)
 .transitionIn(Animation::parallel(Animation::alphaFrom(0), Animation::transitionYFrom(30)))
 .transitionOut(Animation::alphaTo(0))
 .triggerValue(text)
 .build()
 */
auto TransitionComponentBuilder() -> TransitionComponentBuilderEmpty;

/**
 The component that allows its child component to transition to a new state in an animated fashion when a specified trigger value changes. The previous and the
 current visual appearance can be animated independently of each other by passing both @c transitioningIn and @c transitioningOut .

 @param c The spec context to use.

 @note This factory overload is to be used when a key is required to reference the built component in a spec from the
 @c CK_ANIMATION function.

 @example A text component that, when the text is changed, fades the previous text out and slides the new text from the bottom:
 @code
 TransitionComponentBuilder()
 .component(textComponent)
 .transitionIn(Animation::parallel(Animation::alphaFrom(0), Animation::transitionYFrom(30)))
 .transitionOut(Animation::alphaTo(0))
 .triggerValue(text)
 .build()
 */
auto TransitionComponentBuilder(const CK::ComponentSpecContext &c) -> TransitionComponentBuilderContext;
}

#endif
