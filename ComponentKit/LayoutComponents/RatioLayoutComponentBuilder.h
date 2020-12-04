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
#import <ComponentKit/CKRatioLayoutComponent.h>

namespace CK {
namespace BuilderDetails {
namespace RatioLayoutComponentPropId {
constexpr static auto ratio = ComponentBuilderBaseSizeOnlyPropId::__max << 1;
constexpr static auto component = ratio << 1;
constexpr static auto __max = component;
}

template <PropsBitmapType PropsBitmap = 0>
class __attribute__((__may_alias__)) RatioLayoutComponentBuilder
    : public ComponentBuilderBaseSizeOnly<RatioLayoutComponentBuilder, PropsBitmap> {
 public:
  RatioLayoutComponentBuilder() = default;

  RatioLayoutComponentBuilder(const CK::ComponentSpecContext &context)
    : ComponentBuilderBaseSizeOnly<RatioLayoutComponentBuilder, PropsBitmap>{context} { }

  ~RatioLayoutComponentBuilder() = default;

  /**
   The ratio passed is the ratio of height / width you expect.

   For a ratio 0.5, the component will have a flat rectangle shape
    _ _ _ _
   |       |
   |_ _ _ _|

   For a ratio 2.0, the component will be twice as tall as it is wide
    _ _
   |   |
   |   |
   |   |
   |_ _|
   */
  auto &ratio(CGFloat ratio)
  {
    constexpr auto ratioIsNotSet = !PropBitmap::isSet(PropsBitmap, RatioLayoutComponentPropId::ratio);
    static_assert(ratioIsNotSet, "Property 'ratio' is already set.");
    _ratio = ratio;
    return reinterpret_cast<
      RatioLayoutComponentBuilder<PropsBitmap | RatioLayoutComponentPropId::ratio> &>(*this);
  }

  /**
   The component that will be laid out according to given ratio.
   */
  auto &component(NS_RELEASES_ARGUMENT CKComponent *component)
  {
    constexpr auto componentIsNotSet = !PropBitmap::isSet(PropsBitmap, RatioLayoutComponentPropId::component);
    static_assert(componentIsNotSet, "Property `component` is already set.");
    _component = component;
    return reinterpret_cast<
      RatioLayoutComponentBuilder<PropsBitmap | RatioLayoutComponentPropId::component> &>(*this);
  }

 private:
  friend BuilderBase<RatioLayoutComponentBuilder, PropsBitmap>;

  /**
  Creates a new component instance with specified properties.

  @note This method must @b not be called more than once on a given component builder instance.
  */
  NS_RETURNS_RETAINED auto _build() noexcept -> CKRatioLayoutComponent *
  {
    constexpr auto ratioIsSet = PropBitmap::isSet(PropsBitmap, RatioLayoutComponentPropId::ratio);
    static_assert(ratioIsSet, "Required property 'ratio' is not set.");
    constexpr auto componentIsSet = PropBitmap::isSet(PropsBitmap, RatioLayoutComponentPropId::component);
    static_assert(componentIsSet, "Required property 'component' is not set.");

    if (PropBitmap::isSet(PropsBitmap, ComponentBuilderBaseSizeOnlyPropId::size)) {
      return [[CKRatioLayoutComponent alloc] initWithRatio:_ratio
                                                 size:this->_size
                                                 component:_component];
    } else {
      return [[CKRatioLayoutComponent alloc] initWithRatio:_ratio
                                                      size:{}
                                                 component:_component];
    }
  }

 private:
  CGFloat _ratio{};
  CKComponent *_component;
};

}

using RatioLayoutComponentBuilderEmpty = BuilderDetails::RatioLayoutComponentBuilder<>;
using RatioLayoutComponentBuilderContext = BuilderDetails::RatioLayoutComponentBuilder<BuilderDetails::BuilderBasePropId::context>;

/**
 @uidocs https://fburl.com/CKRatioLayoutComponent:b4d0

 Ratio layout component
 For when the content should respect a certain inherent ratio but can be scaled (think photos or videos)
 The ratio passed is the ratio of height / width you expect

 For a ratio 0.5, the component will have a flat rectangle shape
  _ _ _ _
 |       |
 |_ _ _ _|

 For a ratio 2.0, the component will be twice as tall as it is wide
  _ _
 |   |
 |   |
 |   |
 |_ _|
 
 */
auto RatioLayoutComponentBuilder() -> RatioLayoutComponentBuilderEmpty;

/**
 @uidocs https://fburl.com/CKRatioLayoutComponent:b4d0

 Ratio layout component
 For when the content should respect a certain inherent ratio but can be scaled (think photos or videos)
 The ratio passed is the ratio of height / width you expect

 For a ratio 0.5, the component will have a flat rectangle shape
  _ _ _ _
 |       |
 |_ _ _ _|

 For a ratio 2.0, the component will be twice as tall as it is wide
  _ _
 |   |
 |   |
 |   |
 |_ _|

 @param c The spec context to use.

 @note This factory overload is to be used when a key is required to reference the built component in a spec from the
 @c CK_ANIMATION function.
 */
auto RatioLayoutComponentBuilder(const CK::ComponentSpecContext &c) -> RatioLayoutComponentBuilderContext;
}

#endif
