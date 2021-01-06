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
#import <ComponentKit/CKWritingDirection.h>

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
    _top = i.top;
    _left = i.left;
    _bottom = i.bottom;
    _right = i.right;
    return reinterpret_cast<InsetComponentBuilder<PropsBitmap | InsetComponentPropId::insets> &>(*this);
  }

  /**
  The amount of space to inset on the top, left, bottom and right.
  */
  auto &insets(CKRelativeDimension i)
  {
    _top = i;
    _left = i;
    _bottom = i;
    _right = i;
    return reinterpret_cast<InsetComponentBuilder<PropsBitmap | InsetComponentPropId::insets> &>(*this);
  }

  /**
  The amount of space to inset on the top and bottom.
  */
  auto &insetsVertical(CKRelativeDimension i)
  {
    _top = i;
    _bottom = i;
    return reinterpret_cast<InsetComponentBuilder<PropsBitmap | InsetComponentPropId::insets> &>(*this);
  }

  /**
  The amount of space to inset on the left and right.
  */
  auto &insetsHorizontal(CKRelativeDimension i)
  {
    _left = i;
    _right = i;
    return reinterpret_cast<InsetComponentBuilder<PropsBitmap | InsetComponentPropId::insets> &>(*this);
  }

  /**
  The amount of space to inset on the top.
  */
  auto &insetsTop(CGFloat i)
  {
    _top = i;
    return reinterpret_cast<InsetComponentBuilder<PropsBitmap | InsetComponentPropId::insets> &>(*this);
  }

  /**
  Relative amount of inset to parent component's width.
  */
  auto &insetsTop(CKRelativeDimension i)
  {
    _top = i;
    return reinterpret_cast<InsetComponentBuilder<PropsBitmap | InsetComponentPropId::insets> &>(*this);
  }

  /**
  The amount of space to inset on the left.
  */
  auto &insetsLeft(CGFloat i)
  {
    _left = i;
    return reinterpret_cast<InsetComponentBuilder<PropsBitmap | InsetComponentPropId::insets> &>(*this);
  }

  /**
  Relative amount of inset to parent component's width.
  */
  auto &insetsLeft(CKRelativeDimension i)
  {
    _left = i;
    return reinterpret_cast<InsetComponentBuilder<PropsBitmap | InsetComponentPropId::insets> &>(*this);
  }

  /**
  The amount of space to inset on the bottom.
  */
  auto &insetsBottom(CGFloat i)
  {
    _bottom = i;
    return reinterpret_cast<InsetComponentBuilder<PropsBitmap | InsetComponentPropId::insets> &>(*this);
  }

  /**
  Relative amount of inset to parent component's width.
  */
  auto &insetsBottom(CKRelativeDimension i)
  {
    _bottom = i;
    return reinterpret_cast<InsetComponentBuilder<PropsBitmap | InsetComponentPropId::insets> &>(*this);
  }

  /**
  The amount of space to inset on the right.
  */
  auto &insetsRight(CGFloat i)
  {
    _right = i;
    return reinterpret_cast<InsetComponentBuilder<PropsBitmap | InsetComponentPropId::insets> &>(*this);
  }

  /**
  Relative amount of inset to parent component's width.
  */
  auto &insetsRight(CKRelativeDimension i)
  {
    _right = i;
    return reinterpret_cast<InsetComponentBuilder<PropsBitmap | InsetComponentPropId::insets> &>(*this);
  }

  /**
  The amount of space to inset. Left in left-to-right languages, right in right-to-left languages.
  */
  auto &insetsStart(CGFloat i)
  {
    if (CKGetWritingDirection() == CKWritingDirection::RightToLeft) {
      _right = i;
    } else {
      _left = i;
    }

    return reinterpret_cast<InsetComponentBuilder<PropsBitmap | InsetComponentPropId::insets> &>(*this);
  }

  /**
  The amount of space to inset. Right in left-to-right languages, left in right-to-left languages.
  */
  auto &insetsEnd(CGFloat i)
  {
    if (CKGetWritingDirection() == CKWritingDirection::RightToLeft) {
      _left = i;
    } else {
      _right = i;
    }

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
      return [[CKInsetComponent alloc] initWithView:{std::move(this->_viewClass),
                                                     std::move(this->_attributes),
                                                     std::move(this->_accessibilityCtx),
                                                     this->_blockImplicitAnimations}
                                                top:_top
                                               left:_left
                                             bottom:_bottom
                                              right:_right
                                          component:_component];
    } else if (PropBitmap::isSet(PropsBitmap, ViewConfigBuilderPropId::viewConfig)) {
      return [[CKInsetComponent alloc] initWithView:this->_viewConfig top:_top left:_left bottom:_bottom right:_right component:_component];
    } else {
      return [[CKInsetComponent alloc] initWithView:{} top:_top left:_left bottom:_bottom right:_right component:_component];
    }
  }

 private:
  CKComponentViewConfiguration _viewConfig{};
  CKRelativeDimension _top{};
  CKRelativeDimension _left{};
  CKRelativeDimension _bottom{};
  CKRelativeDimension _right{};
  CKComponent *_component;
};
}

using InsetComponentBuilder = BuilderDetails::InsetComponentBuilder<>;
}

#endif
