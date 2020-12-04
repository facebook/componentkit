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

namespace CK {
enum class ClippingComponentDimensions {
  none,
  width,
  height
};

namespace BuilderDetails {
namespace ClippingComponentPropId {
constexpr static auto component = ComponentBuilderBaseSizeOnlyPropId::__max << 1;
constexpr static auto clippedDimensions = component << 1;
constexpr static auto __max = clippedDimensions;
}

namespace ClippingComponentDetails {
auto factory(CKComponent *, const CKComponentSize &, ClippingComponentDimensions) -> CKComponent *;
}

template <PropsBitmapType PropsBitmap = 0>
class __attribute__((__may_alias__)) ClippingComponentBuilder
: public ComponentBuilderBaseSizeOnly<ClippingComponentBuilder, PropsBitmap> {
public:
  ClippingComponentBuilder() = default;

  ~ClippingComponentBuilder() = default;

  /**
   The child component whose layout will be clipped to the specified size.
   */
  auto &component(NS_RELEASES_ARGUMENT CKComponent *c)
  {
    constexpr auto componentIsNotSet = !PropBitmap::isSet(PropsBitmap, ClippingComponentPropId::component);
    static_assert(componentIsNotSet, "Property 'component' is already set.");
    _component = c;
    return reinterpret_cast<
    ClippingComponentBuilder<PropsBitmap | ClippingComponentPropId::component> &>(*this);
  }

  /**
   A value determining which dimension(s) of child component layout could potentially be clipped. When calculating the child layout, the corresponding dimension(s)
   will be unconstrained and potentially clipped as a result.
   */
  auto &clippedDimensions(ClippingComponentDimensions d)
  {
    constexpr auto clippedDimenstionsAreNotSet = !PropBitmap::isSet(PropsBitmap, ClippingComponentPropId::clippedDimensions);
    static_assert(clippedDimenstionsAreNotSet, "Property 'clippedDimensions' is already set.");
    _dimensions = d;
    return reinterpret_cast<
    ClippingComponentBuilder<PropsBitmap | ClippingComponentPropId::clippedDimensions> &>(*this);
  }

private:
  friend BuilderBase<ClippingComponentBuilder, PropsBitmap>;

  /**
   Creates a new component instance with specified properties.

   @note  This method must @b not be called more than once on a given component builder instance.
   */
  NS_RETURNS_RETAINED auto _build() noexcept -> CKComponent *
  {
    constexpr auto componentIsSet = PropBitmap::isSet(PropsBitmap, ClippingComponentPropId::component);
    static_assert(componentIsSet, "Required property 'component' is not set.");
    constexpr auto clippedDimenstionsAreSet = PropBitmap::isSet(PropsBitmap, ClippingComponentPropId::clippedDimensions);
    static_assert(clippedDimenstionsAreSet, "Required property 'clippedDimensions' is not set.");

    return ClippingComponentDetails::factory(_component, this->_size, _dimensions);
  }
  
private:
  CKComponent *_component;
  ClippingComponentDimensions _dimensions{};
};

}

/**
 Component that can clip its child component instead of shrinking it i.e. when given a dimension(s) to clip the child 
 component will be given an infinite amount of space in that dimension, but the clipping component itself will maintain 
 the size it was initialised with.
 */
using ClippingComponentBuilder = BuilderDetails::ClippingComponentBuilder<>;
}

#endif
