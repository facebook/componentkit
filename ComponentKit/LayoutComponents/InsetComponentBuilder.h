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
#import <ComponentKit/CKInsetComponent.h>

namespace CK {
namespace BuilderDetails {
namespace InsetComponentPropId {
constexpr static auto insets = ViewConfigBuilderPropId::__max << 1;
constexpr static auto component = insets << 1;
constexpr static auto __max = component;
}

template <PropsBitmapType PropsBitmap = 0>
class __attribute__((__may_alias__)) InsetComponentBuilder
    : public ViewConfigBuilderBase<InsetComponentBuilder, PropsBitmap>, public BuilderBase<InsetComponentBuilder, PropsBitmap> {
 public:
  InsetComponentBuilder() = default;

  ~InsetComponentBuilder() = default;

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
    return reinterpret_cast<InsetComponentBuilder<PropsBitmap | ViewConfigBuilderPropId::viewConfig> &>(*this);
  }

  /**
   The amount of space to inset on each side.
   */
  auto &insets(UIEdgeInsets i)
  {
    _insets = i;
    return reinterpret_cast<InsetComponentBuilder<PropsBitmap | InsetComponentPropId::insets> &>(*this);
  }

  /**
  The amount of space to inset on the top.
  */
  auto &insetsTop(CGFloat i)
  {
    _insets.top = i;
    return reinterpret_cast<InsetComponentBuilder<PropsBitmap | InsetComponentPropId::insets> &>(*this);
  }

  /**
  The amount of space to inset on the left.
  */
  auto &insetsLeft(CGFloat i)
  {
    _insets.left = i;
    return reinterpret_cast<InsetComponentBuilder<PropsBitmap | InsetComponentPropId::insets> &>(*this);
  }

  /**
  The amount of space to inset on the bottom.
  */
  auto &insetsBottom(CGFloat i)
  {
    _insets.bottom = i;
    return reinterpret_cast<InsetComponentBuilder<PropsBitmap | InsetComponentPropId::insets> &>(*this);
  }

  /**
  The amount of space to inset on the right.
  */
  auto &insetsRight(CGFloat i)
  {
    _insets.right = i;
    return reinterpret_cast<InsetComponentBuilder<PropsBitmap | InsetComponentPropId::insets> &>(*this);
  }

  /**
   The wrapped child component to inset.
   */
  auto &component(NS_RELEASES_ARGUMENT CKComponent *c)
  {
    _component = c;
    return reinterpret_cast<InsetComponentBuilder<PropsBitmap | InsetComponentPropId::component> &>(*this);
  }

 private:
  friend BuilderBase<InsetComponentBuilder, PropsBitmap>;

  /**
  Creates a new component instance with specified properties.

  @note  This method must @b not be called more than once on a given component builder instance.
  */
  NS_RETURNS_RETAINED auto _build() noexcept -> CKInsetComponent *
  {
    constexpr auto insetsAreSet = PropBitmap::isSet(PropsBitmap, InsetComponentPropId::insets);
    static_assert(insetsAreSet, "Required property 'insets' is not set.");
    constexpr auto componentIsSet = PropBitmap::isSet(PropsBitmap, InsetComponentPropId::component);
    static_assert(componentIsSet, "Required property 'component' is not set.");

    if (PropBitmap::isSet(PropsBitmap, ViewConfigBuilderPropId::viewClass)) {
      return [CKInsetComponent newWithView:{std::move(this->_viewClass),
                                            std::move(this->_attributes),
                                            std::move(this->_accessibilityCtx),
                                            this->_blockImplicitAnimations}
                                    insets:_insets
                                 component:_component];
    } else if (PropBitmap::isSet(PropsBitmap, ViewConfigBuilderPropId::viewConfig)) {
      return [CKInsetComponent newWithView:this->_viewConfig insets:_insets component:_component];
    } else {
      return [CKInsetComponent newWithInsets:_insets component:_component];
    }
  }

 private:
  CKComponentViewConfiguration _viewConfig;
  UIEdgeInsets _insets;
  CKComponent *_component;
};
}

using InsetComponentBuilder = BuilderDetails::InsetComponentBuilder<>;
}

#endif
