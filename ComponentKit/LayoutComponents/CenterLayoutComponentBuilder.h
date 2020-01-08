/*
*  Copyright (c) 2014-present, Facebook, Inc.
*  All rights reserved.
*
*  This source code is licensed under the BSD-style license found in the
*  LICENSE file in the root directory of this source tree. An additional grant
*  of patent rights can be found in the PATENTS file in the same directory.
*
*/

namespace CK {
namespace BuilderDetails {
namespace CenterLayoutComponentPropId {
constexpr static auto centeringOptions = BuilderBasePropId::__max << 1;
constexpr static auto sizingOptions = centeringOptions << 1;
constexpr static auto child = sizingOptions << 1;
constexpr static auto size = child << 1;
constexpr static auto __max = size;
}

template <PropsBitmapType PropsBitmap = 0>
class __attribute__((__may_alias__)) CenterLayoutComponentBuilder
: public BuilderBase<CenterLayoutComponentBuilder, PropsBitmap> {
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

  /**
   The width of the component relative to its parent's size.
   */
  auto &width(CKRelativeDimension w)
  {
    _size.width = w;
    return reinterpret_cast<CenterLayoutComponentBuilder<PropsBitmap | CenterLayoutComponentPropId::size> &>(*this);
  }

  /**
   The width of the component.
   */
  auto &width(CGFloat w)
  {
    _size.width = w;
    return reinterpret_cast<CenterLayoutComponentBuilder<PropsBitmap | CenterLayoutComponentPropId::size> &>(*this);
  }

  /**
   The height of the component relative to its parent's size.
   */
  auto &height(CKRelativeDimension h)
  {
    _size.height = h;
    return reinterpret_cast<CenterLayoutComponentBuilder<PropsBitmap | CenterLayoutComponentPropId::size> &>(*this);
  }

  /**
   The height of the component.
   */
  auto &height(CGFloat h)
  {
    _size.height = h;
    return reinterpret_cast<CenterLayoutComponentBuilder<PropsBitmap | CenterLayoutComponentPropId::size> &>(*this);
  }

  /**
   The minumum allowable width of the component relative to its parent's size.
   */
  auto &minWidth(CKRelativeDimension w)
  {
    _size.minWidth = w;
    return reinterpret_cast<CenterLayoutComponentBuilder<PropsBitmap | CenterLayoutComponentPropId::size> &>(*this);
  }

  /**
   The minumum allowable height of the component relative to its parent's size.
   */
  auto &minHeight(CKRelativeDimension h)
  {
    _size.minHeight = h;
    return reinterpret_cast<CenterLayoutComponentBuilder<PropsBitmap | CenterLayoutComponentPropId::size> &>(*this);
  }

  /**
   The maximum allowable width of the component relative to its parent's size.
   */
  auto &maxWidth(CKRelativeDimension w)
  {
    _size.maxWidth = w;
    return reinterpret_cast<CenterLayoutComponentBuilder<PropsBitmap | CenterLayoutComponentPropId::size> &>(*this);
  }

  /**
   The maximum allowable height of the component relative to its parent's size.
   */
  auto &maxHeight(CKRelativeDimension h)
  {
    _size.maxHeight = h;
    return reinterpret_cast<CenterLayoutComponentBuilder<PropsBitmap | CenterLayoutComponentPropId::size> &>(*this);
  }

  /**
   Specifies a size constraint that should apply to this component.
   */
  auto &size(CKComponentSize &&s)
  {
    _size = std::move(s);
    return reinterpret_cast<CenterLayoutComponentBuilder<PropsBitmap | CenterLayoutComponentPropId::size> &>(*this);
  }

  /**
   Specifies a size constraint that should apply to this component.
   */
  auto &size(const CKComponentSize &s)
  {
    _size = s;
    return reinterpret_cast<CenterLayoutComponentBuilder<PropsBitmap | CenterLayoutComponentPropId::size> &>(*this);
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

    if (PropBitmap::isSet(PropsBitmap, CenterLayoutComponentPropId::size)) {
      return [CKCenterLayoutComponent newWithCenteringOptions:_centeringOptions
                                                sizingOptions:_sizingOptions
                                                        child:_child
                                                         size:_size];
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
  CKComponentSize _size;
};
}

/**
 Lays out a single child component and position it so that it is centered into the layout bounds.
 */
using CenterLayoutComponentBuilder = BuilderDetails::CenterLayoutComponentBuilder<>;
}
