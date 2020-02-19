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

#import <ComponentKit/CKButtonComponent.h>
#import <ComponentKit/ComponentBuilder.h>

namespace CK {
namespace BuilderDetails {
namespace ButtonComponentPropId {
constexpr static auto action = ComponentBuilderBaseSizeOnlyPropId::__max << 1;
constexpr static auto anyAttribute = action << 1;
constexpr static auto __max = anyAttribute;
}

template <PropsBitmapType PropsBitmap = 0>
class __attribute__((__may_alias__)) ButtonComponentBuilder
    : public ComponentBuilderBaseSizeOnly<ButtonComponentBuilder, PropsBitmap> {
 public:
  ButtonComponentBuilder() = default;

  ~ButtonComponentBuilder() = default;

  /**
   An action that will be triggered when the button is tapped.
   */
  auto &action(CKAction<UIEvent *> a)
  {
    constexpr auto actionIsNotSet = !PropBitmap::isSet(PropsBitmap, ButtonComponentPropId::action);
    static_assert(actionIsNotSet, "Property 'action' is already set.");
    _action = std::move(a);
    return reinterpret_cast<ButtonComponentBuilder<PropsBitmap | ButtonComponentPropId::action> &>(*this);
  }

  /**
   The title of the button for \c UIControlStateNormal .
   */
  auto &title(NS_RELEASES_ARGUMENT NSString *t)
  {
    _titles[UIControlStateNormal] = t;
    return *this;
  }

  /**
   The title of the button for a given control state.
   */
  auto &title(NS_RELEASES_ARGUMENT NSString *t, UIControlState s)
  {
    _titles[s] = t;
    return *this;
  }

  /**
   The title color of the button for \c UIControlStateNormal .
   */
  auto &titleColor(NS_RELEASES_ARGUMENT UIColor *c)
  {
    _titleColors[UIControlStateNormal] = c;
    return *this;
  }

  /**
   The title color of the button for a given control state.
   */
  auto &titleColor(NS_RELEASES_ARGUMENT UIColor *c, UIControlState s)
  {
    _titleColors[s] = c;
    return *this;
  }

  /**
   Title colors of the button for given states.
   */
  auto &titleColors(const CKButtonComponentStateMap<UIColor *>::Map &m)
  {
    _titleColors = m;
    return *this;
  }

  /**
   The image of the button for \c UIControlStateNormal .
   */
  auto &image(NS_RELEASES_ARGUMENT UIImage *i)
  {
    _images[UIControlStateNormal] = i;
    return *this;
  }

  /**
   The image of the button for a given control state.
   */
  auto &image(NS_RELEASES_ARGUMENT UIImage *i, UIControlState s)
  {
    _images[s] = i;
    return *this;
  }

  /**
   The background image of the button for \c UIControlStateNormal .
   */
  auto &backgroundImage(NS_RELEASES_ARGUMENT UIImage *i)
  {
    _backgroundImages[UIControlStateNormal] = i;
    return *this;
  }

  /**
   The background image of the button for a given control state.
   */
  auto &backgroundImage(NS_RELEASES_ARGUMENT UIImage *i, UIControlState s)
  {
    _backgroundImages[s] = i;
    return *this;
  }

  /**
   The title font the button.
   */
  auto &titleFont(NS_RELEASES_ARGUMENT UIFont *f)
  {
    _options.titleFont = f;
    return reinterpret_cast<
      ButtonComponentBuilder<PropsBitmap | ButtonComponentPropId::anyAttribute> &>(*this);
  }

  /**
   The title alignment
   */
  auto &titleAlignment(NSTextAlignment a)
  {
    _options.titleAlignment = a;
    return reinterpret_cast<
      ButtonComponentBuilder<PropsBitmap | ButtonComponentPropId::anyAttribute> &>(*this);
  }

  /**
   Whether the button is selected. Default is \c NO .
   */
  auto &selected(BOOL s)
  {
    _options.selected = s;
    return reinterpret_cast<
      ButtonComponentBuilder<PropsBitmap | ButtonComponentPropId::anyAttribute> &>(*this);
  }

  /**
   Whether the button is enabled. Default is \c YES .
   */
  auto &enabled(BOOL e)
  {
    _options.enabled = e;
    return reinterpret_cast<
      ButtonComponentBuilder<PropsBitmap | ButtonComponentPropId::anyAttribute> &>(*this);
  }

  /**
   The maximum number of lines to use for rendering text. Default is 1 .

   \warning Setting \c numberOfLines to 0 or less can create unpredictible behaviour between displaying the label and the buttons size. \c UIButton 's \c titleLabel property isn't bound to the bounds of it's housing \c UIButton, which can lead to the text displaying incorrectly.
   */
  auto &numberOfLines(NSInteger n)
  {
    _options.numberOfLines = n;
    return reinterpret_cast<
      ButtonComponentBuilder<PropsBitmap | ButtonComponentPropId::anyAttribute> &>(*this);
  }

  /**
   The line break mode for the title label. Default is \c NSLineBreakByTruncatingMiddle .
   */
  auto &lineBreakMode(NSLineBreakMode m)
  {
    _options.lineBreakMode = m;
    return reinterpret_cast<
      ButtonComponentBuilder<PropsBitmap | ButtonComponentPropId::anyAttribute> &>(*this);
  }

  /**
   The inset or outset margins for the rectangle around the button's content. Default is \c UIEdgeInsetsZero .
   */
  auto &contentEdgeInsets(UIEdgeInsets i)
  {
    _options.contentEdgeInsets = i;
    return reinterpret_cast<
      ButtonComponentBuilder<PropsBitmap | ButtonComponentPropId::anyAttribute> &>(*this);
  }

  /**
   The inset or outset margins for the rectangle around the button's title text. Default is \c UIEdgeInsetsZero .
   */
  auto &titleEdgeInsets(UIEdgeInsets i)
  {
    _options.titleEdgeInsets = i;
    return reinterpret_cast<
      ButtonComponentBuilder<PropsBitmap | ButtonComponentPropId::anyAttribute> &>(*this);
  }

  /**
   The inset or outset margins for the rectangle around the button's image. Default is \c UIEdgeInsetsZero .
   */
  auto &imageEdgeInsets(UIEdgeInsets i)
  {
    _options.imageEdgeInsets = i;
    return reinterpret_cast<
      ButtonComponentBuilder<PropsBitmap | ButtonComponentPropId::anyAttribute> &>(*this);
  }

  /**
   The outset for tap target expansion Default is \c UIEdgeInsetsZero .
   */
  auto &tapTargetExpansion(UIEdgeInsets i)
  {
    _options.tapTargetExpansion = i;
    return reinterpret_cast<
      ButtonComponentBuilder<PropsBitmap | ButtonComponentPropId::anyAttribute> &>(*this);
  }

  /**
   Specifies a background color that a view for the component should have.

   @param c A background color to set

   @note Calling this method on a builder that does not have a view class set will trigger a compilation error.

   @note Calling this method on a builder that already has a complete view configuration set will trigger
   a compilation error.
   */
  auto &backgroundColor(NS_RELEASES_ARGUMENT UIColor *c)
  {
    _options.attributes.insert({ @selector(setBackgroundColor:), c });
    return reinterpret_cast<ButtonComponentBuilder<PropsBitmap | ButtonComponentPropId::anyAttribute> &>(*this);
  }

  /**
   Specifies whether a view for the component should ignore user events.

   @param enabled A Boolean value that determines whether user events are ignored

   @note Calling this method on a builder that does not have a view class set will trigger a compilation error.

   @note Calling this method on a builder that already has a complete view configuration set will trigger
   a compilation error.
   */
  auto &userInteractionEnabled(bool enabled)
  {
    _options.attributes.insert({ @selector(setUserInteractionEnabled:), enabled });
    return reinterpret_cast<ButtonComponentBuilder<PropsBitmap | ButtonComponentPropId::anyAttribute> &>(*this);
  }

  /**
   Specifies whether subviews of a view for the component should be confined to its bounds.

   @param enabled A Boolean value that determines whether subviews are confined

   @note Calling this method on a builder that does not have a view class set will trigger a compilation error.

   @note Calling this method on a builder that already has a complete view configuration set will trigger
   a compilation error.
   */
  auto &clipsToBounds(bool clip)
  {
    _options.attributes.insert({ @selector(setClipsToBounds:), clip });
    return reinterpret_cast<ButtonComponentBuilder<PropsBitmap | ButtonComponentPropId::anyAttribute> &>(*this);
  }

  /**
   Specifies the alpha value for this component's view.

   @param a A floating-point number in the range 0.0 to 1.0, where 0.0 represents totally transparent and 1.0 represents
   totally opaque.

   @note Calling this method on a builder that does not have a view class set will trigger a compilation error.

   @note Calling this method on a builder that already has a complete view configuration set will trigger
   a compilation error.
   */
  auto &alpha(CGFloat a)
  {
    _options.attributes.insert({ @selector(setAlpha:), a });
    return reinterpret_cast<ButtonComponentBuilder<PropsBitmap | ButtonComponentPropId::anyAttribute> &>(*this);
  }

  /**
   Specifies the width of the border for this component's view.

   @param w The border width. When this value is greater than 0.0, the view draws a border using the current borderColor
   value.

   @note Calling this method on a builder that does not have a view class set will trigger a compilation error.

   @note Calling this method on a builder that already has a complete view configuration set will trigger
   a compilation error.
   */
  auto &borderWidth(CGFloat w)
  {
    _options.attributes.insert({ CKComponentViewAttribute::LayerAttribute(@selector(setBorderWidth:)), w });
    return reinterpret_cast<ButtonComponentBuilder<PropsBitmap | ButtonComponentPropId::anyAttribute> &>(*this);
  }

  /**
   Specifies the color of the border for this component's view.

   @param c A @c UIColor value that determines the border color. The default value of this property is an opaque black.

   @note Calling this method on a builder that does not have a view class set will trigger a compilation error.

   @note Calling this method on a builder that already has a complete view configuration set will trigger
   a compilation error.
   */
  auto &borderColor(NS_RELEASES_ARGUMENT UIColor *c)
  {
    _options.attributes.insert({ CKComponentViewAttribute::LayerAttribute(@selector(setBorderColor:)), (id)c.CGColor });
    return reinterpret_cast<ButtonComponentBuilder<PropsBitmap | ButtonComponentPropId::anyAttribute> &>(*this);
  }

  /**
   Specifies the radius to use when drawing rounded corners for the component's view background.

   @param r A floating point value that determines the radius. Setting the radius to a value greater than 0.0 causes the
   view to begin drawing rounded corners on its background.

   @note Calling this method on a builder that does not have a view class set will trigger a compilation error.

   @note Calling this method on a builder that already has a complete view configuration set will trigger
   a compilation error.
   */
  auto &cornerRadius(CGFloat r)
  {
    _options.attributes.insert({ CKComponentViewAttribute::LayerAttribute(@selector(setCornerRadius:)), r });
    return reinterpret_cast<ButtonComponentBuilder<PropsBitmap | ButtonComponentPropId::anyAttribute> &>(*this);
  }

  /**
   Sets a value for an arbitrary view property by specifying a selector that corresponds to the property setter and the
   value.

   @param attr A selector corresponding to a setter.
   @param value A value to set.

   @note Calling this method on a builder that does not have a view class set will trigger a compilation error.

   @note Calling this method on a builder that already has a complete view configuration set will trigger
   a compilation error.
   */
  auto &attribute(SEL attr, NS_RELEASES_ARGUMENT id value)
  {
    _options.attributes.insert({attr, value});
    return reinterpret_cast<ButtonComponentBuilder<PropsBitmap | ButtonComponentPropId::anyAttribute> &>(*this);
  }

  /**
   Sets a value for an arbitrary view property by specifying a complete attribute descriptor and a value.

   @param attr An view attribute descriptor.
   @param value A value to set. Both expressions of boxable types, such as @c int or @c CGFloat, and ObjC objects are
   supported.

   @note Calling this method on a builder that does not have a view class set will trigger a compilation error.

   @note Calling this method on a builder that already has a complete view configuration set will trigger
   a compilation error.
   */
  auto &attribute(const CKComponentViewAttribute &attr, const CKBoxedValue &value)
  {
    _options.attributes.insert({attr, value});
    return reinterpret_cast<ButtonComponentBuilder<PropsBitmap | ButtonComponentPropId::anyAttribute> &>(*this);
  }

  /**
   Adds a complete attribute / value pair to the component view configuration, mostly for convenience for helper
   functions that return both an attribute and a value.

   @param v An attribute / value pair.

   @note Calling this method on a builder that does not have a view class set will trigger a compilation error.

   @note Calling this method on a builder that already has a complete view configuration set will trigger
   a compilation error.
   */
  auto &attribute(const CKComponentViewAttributeValue &v)
  {
    _options.attributes.insert(v);
    return reinterpret_cast<ButtonComponentBuilder<PropsBitmap | ButtonComponentPropId::anyAttribute> &>(*this);
  }

  /**
   Specifies a complete attribute map for a view of this component.

   @param a  The attribute map to set.

   @note Calling this method on a builder that does not have a view class set will trigger a compilation error.

   @note Calling this method on a builder that already has a complete view configuration set will trigger
   a compilation error.
   */
  auto &attributes(CKViewComponentAttributeValueMap a)
  {
    constexpr auto noAttributesSet = !PropBitmap::isSet(PropsBitmap, ButtonComponentPropId::anyAttribute);
    static_assert(noAttributesSet, "Setting 'attributes' overrides existing attributes.");
    _options.attributes = std::move(a);
    return reinterpret_cast<ButtonComponentBuilder<PropsBitmap> &>(*this);
  }

  /**
   Specifies an accessibility configuration for a view of this component, which will be applied when accessibility is
   enabled.

   @param c  Accessibility configuration to set.

   @note Calling this method on a builder that does not have a view class set will trigger a compilation error.

   @note Calling this method on a builder that already has a complete view configuration set will trigger
   a compilation error.
   */
  auto &accessibilityContext(CKComponentAccessibilityContext c)
  {
    _options.accessibilityContext = std::move(c);
    return reinterpret_cast<ButtonComponentBuilder<PropsBitmap> &>(*this);
  }

 private:
  friend BuilderBase<ButtonComponentBuilder, PropsBitmap>;

  /**
  Creates a new component instance with specified properties.

  @note  This method must @b not be called more than once on a given component builder instance.
  */
  NS_RETURNS_RETAINED auto _build() noexcept -> CKButtonComponent *
  {
    constexpr auto actionIsSet = PropBitmap::isSet(PropsBitmap, ButtonComponentPropId::action);
    static_assert(actionIsSet, "Required property 'action' is not set.");

    _options.titles = std::move(_titles);
    _options.titleColors = std::move(_titleColors);
    _options.images = std::move(_images);
    _options.backgroundImages = std::move(_backgroundImages);

    if (PropBitmap::isSet(PropsBitmap, ComponentBuilderBasePropId::size)) {
      _options.size = this->_size;
    }

    return [CKButtonComponent newWithAction:std::move(_action)
                                    options:std::move(_options)];
  }

 private:
  CKButtonComponentStateMap<NSString *>::Map _titles;
  CKButtonComponentStateMap<UIColor *>::Map _titleColors;
  CKButtonComponentStateMap<UIImage *>::Map _images;
  CKButtonComponentStateMap<UIImage *>::Map _backgroundImages;

  CKAction<UIEvent *> _action;
  CKButtonComponentOptions _options;
};

}

/**
 A component that creates a \c UIButton.

 This component chooses the smallest size within its size range that will fit its content. If its max size is smaller
 than the size required to fit its content, it will be truncated.
 */
using ButtonComponentBuilder = BuilderDetails::ButtonComponentBuilder<>;
}

#endif
