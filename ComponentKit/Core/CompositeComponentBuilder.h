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
#import <ComponentKit/CKCompositeComponent.h>

namespace CK {
namespace BuilderDetails {
namespace CompositeComponentPropId {
constexpr static auto component = ViewConfigBuilderPropId::__max << 1;
constexpr static auto __max = component;
}

template <PropsBitmapType PropsBitmap = 0>
class __attribute__((__may_alias__)) CompositeComponentBuilder
    : public ViewConfigBuilderBase<CompositeComponentBuilder, PropsBitmap>,
      public BuilderBase<CompositeComponentBuilder, PropsBitmap> {
 public:
  CompositeComponentBuilder() = default;

  ~CompositeComponentBuilder() = default;

  /**
   Specifies a complete view configuration which will be used to create a view for the component.

   @param c A struct describing the view for this component.

   @note Calling this method on a builder that already has a view class or any of the view properties set will trigger
   a compilation error.

   @note This method only accepts temporaries as its argument. If you need to pass an existing variable use
   @c std::move().
   */
  auto &view(CKComponentViewConfiguration &&c)
  {
    constexpr auto viewConfigurationOverridesExistingViewClass =
      PropBitmap::isSet(PropsBitmap, ViewConfigBuilderPropId::viewClass);
    static_assert(!viewConfigurationOverridesExistingViewClass,
                  "Setting view configuration overrides existing view class");
    _viewConfig = std::move(c);
    return reinterpret_cast<CompositeComponentBuilder<PropsBitmap | ViewConfigBuilderPropId::viewConfig> &>(*this);
  }

  /**
   The component the composite component uses for layout and sizing.
   */
  auto &component(NS_RELEASES_ARGUMENT CKComponent *c)
  {
    constexpr auto componentIsNotSet = !PropBitmap::isSet(PropsBitmap, CompositeComponentPropId::component);
    static_assert(componentIsNotSet, "Property 'component' is already set.");
    _component = c;
    return reinterpret_cast<CompositeComponentBuilder<PropsBitmap | CompositeComponentPropId::component> &>(*this);
  }

 private:
  friend BuilderBase<CompositeComponentBuilder, PropsBitmap>;

  /**
  Creates a new component instance with specified properties.

  @note  This method must @b not be called more than once on a given component
  builder instance.
  */
  NS_RETURNS_RETAINED auto _build() noexcept -> CKCompositeComponent *
  {
    constexpr auto componentIsSet = PropBitmap::isSet(PropsBitmap, CompositeComponentPropId::component);
    static_assert(componentIsSet, "Required property 'component' is not set.");

    if (PropBitmap::isSet(PropsBitmap, ViewConfigBuilderPropId::viewClass)) {
      return [CKCompositeComponent newWithView:{std::move(this->_viewClass),
                                                std::move(this->_attributes),
                                                std::move(this->_accessibilityCtx),
                                                this->_blockImplicitAnimations}
                                     component:_component];
    } else if (PropBitmap::isSet(PropsBitmap, ViewConfigBuilderPropId::viewConfig)) {
      return [CKCompositeComponent newWithView:this->_viewConfig component:_component];
    } else {
      return [CKCompositeComponent newWithComponent:_component];
    }
  }

 private:
  CKComponentViewConfiguration _viewConfig;
  CKComponent *_component;
};
}

using CompositeComponentBuilder = BuilderDetails::CompositeComponentBuilder<>;
}

#endif
