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
#import <ComponentKit/CKBackgroundLayoutComponent.h>

namespace CK {
namespace BuilderDetails {
namespace BackgroundLayoutComponentPropId {
constexpr static auto component = BuilderBasePropId::__max << 1;
constexpr static auto background = component << 1;
constexpr static auto __max = background;
}

template <PropsBitmapType PropsBitmap = 0>
class __attribute__((__may_alias__)) BackgroundLayoutComponentBuilder
    : public BuilderBase<BackgroundLayoutComponentBuilder, PropsBitmap> {
 public:
  BackgroundLayoutComponentBuilder() = default;

  ~BackgroundLayoutComponentBuilder() = default;

  /**
   A child that is laid out to determine the size of this component.
   */
  auto &component(NS_RELEASES_ARGUMENT CKComponent *c)
  {
    constexpr auto componentIsNotSet = !PropBitmap::isSet(PropsBitmap, BackgroundLayoutComponentPropId::component);
    static_assert(componentIsNotSet, "Property 'component' is already set.");
    _component = c;
    return reinterpret_cast<
      BackgroundLayoutComponentBuilder<PropsBitmap | BackgroundLayoutComponentPropId::component> &>(*this);
  }

  /**
   A child that is laid out behind the component. May be nil, in which case the background is omitted.
   */
  auto &background(NS_RELEASES_ARGUMENT CKComponent *c)
  {
    constexpr auto backgroundIsNotSet = !PropBitmap::isSet(PropsBitmap, BackgroundLayoutComponentPropId::background);
    static_assert(backgroundIsNotSet, "Property 'background' is already set.");
    _background = c;
    return reinterpret_cast<
      BackgroundLayoutComponentBuilder<PropsBitmap | BackgroundLayoutComponentPropId::background> &>(*this);
  }

 private:
  friend BuilderBase<BackgroundLayoutComponentBuilder, PropsBitmap>;

  /**
  Creates a new component instance with specified properties.

  @note  This method must @b not be called more than once on a given component builder instance.
  */
  NS_RETURNS_RETAINED auto _build() noexcept -> CKBackgroundLayoutComponent *
  {
    constexpr auto componentIsSet = PropBitmap::isSet(PropsBitmap, BackgroundLayoutComponentPropId::component);
    static_assert(componentIsSet, "Required property 'component' is not set.");
    constexpr auto backgroundIsSet = PropBitmap::isSet(PropsBitmap, BackgroundLayoutComponentPropId::background);
    static_assert(backgroundIsSet, "Required property 'background' is not set.");

    return [CKBackgroundLayoutComponent newWithComponent:_component background:_background];
  }

 private:
  CKComponent *_component;
  CKComponent *_background;
};

}

/**
 Lays out a single child component, then lays out a background component behind it stretched to its size.
 */
using BackgroundLayoutComponentBuilder = BuilderDetails::BackgroundLayoutComponentBuilder<>;
}

#endif
