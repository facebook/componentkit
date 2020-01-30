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
#import <ComponentKit/CKCenterLayoutComponent.h>

namespace CK {
namespace BuilderDetails {
namespace CenterLayoutComponentPropId {
constexpr static auto centeringOptions = ComponentBuilderBaseSizeOnlyPropId::__max << 1;
constexpr static auto sizingOptions = centeringOptions << 1;
constexpr static auto child = sizingOptions << 1;
constexpr static auto __max = child;
}

template <PropsBitmapType PropsBitmap = 0>
class __attribute__((__may_alias__)) CenterLayoutComponentBuilder
: public ComponentBuilderBaseSizeOnly<CenterLayoutComponentBuilder, PropsBitmap> {
public:
  CenterLayoutComponentBuilder() = default;

  ~CenterLayoutComponentBuilder() = default;

  /**
   Specifies how the child component should be aligned within the layout bounds. See \c CKCenterLayoutComponentCenteringOptions.
   */
  auto &centeringOptions(CKCenterLayoutComponentCenteringOptions o) {
    constexpr auto centeringOptionsNotSet = !PropBitmap::isSet(PropsBitmap, CenterLayoutComponentPropId::centeringOptions);
    static_assert(centeringOptionsNotSet, "Property 'centeringOptions' is already set.");
    _centeringOptions = o;
    return reinterpret_cast<CenterLayoutComponentBuilder<PropsBitmap | CenterLayoutComponentPropId::centeringOptions> &>(*this);
  }

  /**
   Specifies how the child component should be sized. See \c CKCenterLayoutComponentSizingOptions.
   */
  auto &sizingOptions(CKCenterLayoutComponentSizingOptions o) {
    constexpr auto sizingOptionsNotSet = !PropBitmap::isSet(PropsBitmap, CenterLayoutComponentPropId::sizingOptions);
    static_assert(sizingOptionsNotSet, "Property 'sizingOptions' is already set.");
    _sizingOptions = o;
    return reinterpret_cast<CenterLayoutComponentBuilder<PropsBitmap | CenterLayoutComponentPropId::sizingOptions> &>(*this);
  }

  /**
   The child to center.
   */
  auto &child(NS_RELEASES_ARGUMENT CKComponent *c) {
    constexpr auto childNotSet = !PropBitmap::isSet(PropsBitmap, CenterLayoutComponentPropId::child);
    static_assert(childNotSet, "Property 'child' is already set.");
    _child = c;
    return reinterpret_cast<CenterLayoutComponentBuilder<PropsBitmap | CenterLayoutComponentPropId::child> &>(*this);
  }

private:
  friend BuilderBase<CenterLayoutComponentBuilder, PropsBitmap>;

  /**
  Creates a new component instance with specified properties.

  @note  This method must @b not be called more than once on a given component builder instance.
  */
  NS_RETURNS_RETAINED auto _build() noexcept -> CKCenterLayoutComponent *
  {
    constexpr auto childIsSet = PropBitmap::isSet(PropsBitmap, CenterLayoutComponentPropId::child);
    static_assert(childIsSet, "Required property 'child' is not set.");

    if (PropBitmap::isSet(PropsBitmap, ComponentBuilderBaseSizeOnlyPropId::size)) {
      return [CKCenterLayoutComponent newWithCenteringOptions:_centeringOptions
                                                sizingOptions:_sizingOptions
                                                        child:_child
                                                         size:this->_size];
    } else {
      return [CKCenterLayoutComponent newWithCenteringOptions:_centeringOptions
                                                sizingOptions:_sizingOptions
                                                        child:_child
                                                         size:{}];
    }
  }

private:
  CKCenterLayoutComponentCenteringOptions _centeringOptions;
  CKCenterLayoutComponentSizingOptions _sizingOptions;
  CKComponent *_child;
};
}

/**
 Lays out a single child component and position it so that it is centered into the layout bounds.
 */
using CenterLayoutComponentBuilder = BuilderDetails::CenterLayoutComponentBuilder<>;
}

#endif
