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
#import <ComponentKit/CKSizingComponent.h>

namespace CK {
namespace BuilderDetails {
namespace CKSizingComponentPropId {
constexpr static auto component = ComponentBuilderBaseSizeOnlyPropId::__max << 1;
constexpr static auto __max = component;
}

template <PropsBitmapType PropsBitmap = 0>
class __attribute__((__may_alias__)) SizingComponentBuilder
   : public ComponentBuilderBaseSizeOnly<SizingComponentBuilder, PropsBitmap> {
public:
 SizingComponentBuilder() = default;
 SizingComponentBuilder(const CK::ComponentSpecContext &context) : ComponentBuilderBaseSizeOnly<SizingComponentBuilder, PropsBitmap>{context} { }

 ~SizingComponentBuilder() = default;

 /**
  The inner component to layout and size
  */
 auto &component(NS_RELEASES_ARGUMENT CKComponent *component)
 {
   constexpr auto componentIsNotSet = !PropBitmap::isSet(PropsBitmap, CKSizingComponentPropId::component);
   static_assert(componentIsNotSet, "Property 'component' is already set.");
   _component = component;
   return reinterpret_cast<
     SizingComponentBuilder<PropsBitmap | CKSizingComponentPropId::component> &>(*this);
 }
 
private:
 friend BuilderBase<SizingComponentBuilder, PropsBitmap>;

 /**
 Creates a new component instance with specified properties.

 @note  This method must @b not be called more than once on a given component builder instance.
 */
 NS_RETURNS_RETAINED auto _build() noexcept -> CKSizingComponent *
 {
   constexpr auto componentIsSet = PropBitmap::isSet(PropsBitmap, CKSizingComponentPropId::component);
   static_assert(componentIsSet, "Required property 'component' is not set.");
   constexpr auto sizeIsSet = PropBitmap::isSet(PropsBitmap, ComponentBuilderBaseSizeOnlyPropId::size);
   static_assert(sizeIsSet, "Required property 'size' is not set.");

   return [[CKSizingComponent alloc] initWithSize:this->_size component:_component];
 }

private:
  CKComponent *_component;
};

}

using SizingComponentBuilderEmpty = BuilderDetails::SizingComponentBuilder<>;
using SizingComponentBuilderContext = BuilderDetails::SizingComponentBuilder<BuilderDetails::BuilderBasePropId::context>;

/**
 Constrains a child component's layout to a specific size.
*/
auto SizingComponentBuilder() -> SizingComponentBuilderEmpty;

/**
 Constrains a child component's layout to a specific size.

 @param c The spec context to use.

 @note This factory overload is to be used when a key is required to reference the built component in a spec from the
 @c CK_ANIMATION function
*/
auto SizingComponentBuilder(const CK::ComponentSpecContext &c) -> SizingComponentBuilderContext;
}

#endif
