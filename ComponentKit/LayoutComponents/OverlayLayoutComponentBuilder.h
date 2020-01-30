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
#import <ComponentKit/CKOverlayLayoutComponent.h>

namespace CK {
namespace BuilderDetails {
namespace OverlayLayoutComponentPropId {
constexpr static auto component = BuilderBasePropId::__max << 1;
constexpr static auto overlay = component << 1;
constexpr static auto __max = overlay;
}

template <PropsBitmapType PropsBitmap = 0>
class __attribute__((__may_alias__)) OverlayLayoutComponentBuilder
: public BuilderBase<OverlayLayoutComponentBuilder, PropsBitmap> {
public:
  OverlayLayoutComponentBuilder() = default;

  ~OverlayLayoutComponentBuilder() = default;

  auto &component(NS_RELEASES_ARGUMENT CKComponent *c)
  {
    constexpr auto componentIsNotSet = !PropBitmap::isSet(PropsBitmap, OverlayLayoutComponentPropId::component);
    static_assert(componentIsNotSet, "Property 'component' is already set.");
    _component = c;
    return reinterpret_cast<OverlayLayoutComponentBuilder<PropsBitmap | OverlayLayoutComponentPropId::component> &>(*this);
  }

  auto &overlay(NS_RELEASES_ARGUMENT CKComponent *c)
  {
    constexpr auto overlayIsNotSet = !PropBitmap::isSet(PropsBitmap, OverlayLayoutComponentPropId::overlay);
    static_assert(overlayIsNotSet, "Property 'overlay' is already set.");
    _overlay = c;
    return reinterpret_cast<OverlayLayoutComponentBuilder<PropsBitmap | OverlayLayoutComponentPropId::overlay> &>(*this);
  }

private:
  friend BuilderBase<OverlayLayoutComponentBuilder, PropsBitmap>;

  /**
  Creates a new component instance with specified properties.

  @note  This method must @b not be called more than once on a given component builder instance.
  */
  NS_RETURNS_RETAINED auto _build() noexcept -> CKOverlayLayoutComponent *
  {
    constexpr auto componentIsSet = PropBitmap::isSet(PropsBitmap, OverlayLayoutComponentPropId::component);
    static_assert(componentIsSet, "Required property 'component' is not set.");
    constexpr auto overlayIsSet = PropBitmap::isSet(PropsBitmap, OverlayLayoutComponentPropId::overlay);
    static_assert(overlayIsSet, "Required property 'overlay' is not set.");

    return [CKOverlayLayoutComponent newWithComponent:_component overlay:_overlay];
  }

private:
  CKComponent *_component;
  CKComponent *_overlay;
};
}

/**
 This component lays out a single component and then overlays a component on top of it streched to its size
 */
using OverlayLayoutComponentBuilder = BuilderDetails::OverlayLayoutComponentBuilder<>;
}

#endif
