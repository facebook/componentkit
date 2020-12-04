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
constexpr static auto anyOption = action << 1;
constexpr static auto options = anyOption << 1;
constexpr static auto __max = options;
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

   @note  Calling this method on a builder that already has a complete set of options specified using \c options() will
   trigger a compilation error.
   */
  auto &title(NS_RELEASES_ARGUMENT NSString *t)
  {
    constexpr auto titleOverridesExistingOptions = PropBitmap::isSet(PropsBitmap, ButtonComponentPropId::options);
    static_assert(!titleOverridesExistingOptions, "Setting 'title' overrides existing options");
    _titles[UIControlStateNormal] = t;
    return reinterpret_cast<ButtonComponentBuilder<PropsBitmap | ButtonComponentPropId::anyOption> &>(*this);
  }

  /**
   The title of the button for a given control state.

   @note  Calling this method on a builder that already has a complete set of options specified using \c options() will
   trigger a compilation error.
   */
  auto &title(NS_RELEASES_ARGUMENT NSString *t, UIControlState s)
  {
    constexpr auto titleOverridesExistingOptions = PropBitmap::isSet(PropsBitmap, ButtonComponentPropId::options);
    static_assert(!titleOverridesExistingOptions, "Setting 'title' overrides existing options");
    _titles[s] = t;
    return reinterpret_cast<ButtonComponentBuilder<PropsBitmap | ButtonComponentPropId::anyOption> &>(*this);
  }

  /**
   The title of the button for different states.

   @note  Calling this method on a builder that already has a complete set of options specified using \c options() will
   trigger a compilation error.
   */
  auto &titles(const CKButtonComponentStateMap<NSString *>::Map &m)
  {
    constexpr auto titlesOverrideExistingOptions = PropBitmap::isSet(PropsBitmap, ButtonComponentPropId::options);
    static_assert(!titlesOverrideExistingOptions, "Setting 'titles' overrides existing options");
    _titles = m;
    return reinterpret_cast<ButtonComponentBuilder<PropsBitmap | ButtonComponentPropId::anyOption> &>(*this);
  }

  /**
   The title color of the button for \c UIControlStateNormal .

   @note  Calling this method on a builder that already has a complete set of options specified using \c options() will
   trigger a compilation error.
   */
  auto &titleColor(NS_RELEASES_ARGUMENT UIColor *c)
  {
    constexpr auto titleColorOverridesExistingOptions = PropBitmap::isSet(PropsBitmap, ButtonComponentPropId::options);
    static_assert(!titleColorOverridesExistingOptions, "Setting 'titleColor' overrides existing options");
    _titleColors[UIControlStateNormal] = c;
    return reinterpret_cast<ButtonComponentBuilder<PropsBitmap | ButtonComponentPropId::anyOption> &>(*this);
  }

  /**
   The title color of the button for a given control state.

   @note  Calling this method on a builder that already has a complete set of options specified using \c options() will
   trigger a compilation error.
   */
  auto &titleColor(NS_RELEASES_ARGUMENT UIColor *c, UIControlState s)
  {
    constexpr auto titleColorOverridesExistingOptions = PropBitmap::isSet(PropsBitmap, ButtonComponentPropId::options);
    static_assert(!titleColorOverridesExistingOptions, "Setting 'titleColor' overrides existing options");
    _titleColors[s] = c;
    return reinterpret_cast<ButtonComponentBuilder<PropsBitmap | ButtonComponentPropId::anyOption> &>(*this);
  }

  /**
   Title colors of the button for given states.

   @note  Calling this method on a builder that already has a complete set of options specified using \c options() will
   trigger a compilation error.
   */
  auto &titleColors(const CKButtonComponentStateMap<UIColor *>::Map &m)
  {
    constexpr auto titleColorsOverrideExistingOptions = PropBitmap::isSet(PropsBitmap, ButtonComponentPropId::options);
    static_assert(!titleColorsOverrideExistingOptions, "Setting 'titleColors' overrides existing options");
    _titleColors = m;
    return reinterpret_cast<ButtonComponentBuilder<PropsBitmap | ButtonComponentPropId::anyOption> &>(*this);
  }

  /**
   The image of the button for \c UIControlStateNormal .

   @note  Calling this method on a builder that already has a complete set of options specified using \c options() will
   trigger a compilation error.
   */
  auto &image(NS_RELEASES_ARGUMENT UIImage *i)
  {
    constexpr auto imageOverridesExistingOptions = PropBitmap::isSet(PropsBitmap, ButtonComponentPropId::options);
    static_assert(!imageOverridesExistingOptions, "Setting 'image' overrides existing options");
    _images[UIControlStateNormal] = i;
    return reinterpret_cast<ButtonComponentBuilder<PropsBitmap | ButtonComponentPropId::anyOption> &>(*this);
  }

  /**
   The image of the button for a given control state.

   @note  Calling this method on a builder that already has a complete set of options specified using \c options() will
   trigger a compilation error.
   */
  auto &image(NS_RELEASES_ARGUMENT UIImage *i, UIControlState s)
  {
    constexpr auto imageOverridesExistingOptions = PropBitmap::isSet(PropsBitmap, ButtonComponentPropId::options);
    static_assert(!imageOverridesExistingOptions, "Setting 'image' overrides existing options");
    _images[s] = i;
    return reinterpret_cast<ButtonComponentBuilder<PropsBitmap | ButtonComponentPropId::anyOption> &>(*this);
  }

  /**
   The images of the button for different states.

   @note  Calling this method on a builder that already has a complete set of options specified using \c options() will
   trigger a compilation error.
   */
  auto &images(const CKButtonComponentStateMap<UIImage *>::Map &m)
  {
    constexpr auto imagesOverrideExistingOptions = PropBitmap::isSet(PropsBitmap, ButtonComponentPropId::options);
    static_assert(!imagesOverrideExistingOptions, "Setting 'images' overrides existing options");
    _images = m;
    return reinterpret_cast<ButtonComponentBuilder<PropsBitmap | ButtonComponentPropId::anyOption> &>(*this);
  }

  /**
   The background image of the button for \c UIControlStateNormal .

   @note  Calling this method on a builder that already has a complete set of options specified using \c options() will
   trigger a compilation error.
   */
  auto &backgroundImage(NS_RELEASES_ARGUMENT UIImage *i)
  {
    constexpr auto backgroundImageOverridesExistingOptions =
      PropBitmap::isSet(PropsBitmap, ButtonComponentPropId::options);
    static_assert(!backgroundImageOverridesExistingOptions, "Setting 'backgroundImage' overrides existing options");
    _backgroundImages[UIControlStateNormal] = i;
    return reinterpret_cast<ButtonComponentBuilder<PropsBitmap | ButtonComponentPropId::anyOption> &>(*this);
  }

  /**
   The background image of the button for a given control state.

   @note  Calling this method on a builder that already has a complete set of options specified using \c options() will
   trigger a compilation error.
   */
  auto &backgroundImage(NS_RELEASES_ARGUMENT UIImage *i, UIControlState s)
  {
    constexpr auto backgroundImageOverridesExistingOptions =
      PropBitmap::isSet(PropsBitmap, ButtonComponentPropId::options);
    static_assert(!backgroundImageOverridesExistingOptions, "Setting 'backgroundImage' overrides existing options");
    _backgroundImages[s] = i;
    return reinterpret_cast<ButtonComponentBuilder<PropsBitmap | ButtonComponentPropId::anyOption> &>(*this);
  }

  /**
   The background images of the button for different states.

   @note  Calling this method on a builder that already has a complete set of options specified using \c options() will
   trigger a compilation error.
   */
  auto &backgroundImages(const CKButtonComponentStateMap<UIImage *>::Map &m)
  {
    constexpr auto backgroundImagesOverrideExistingOptions =
      PropBitmap::isSet(PropsBitmap, ButtonComponentPropId::options);
    static_assert(!backgroundImagesOverrideExistingOptions, "Setting 'backgroundImages' overrides existing options");
    _backgroundImages = m;
    return reinterpret_cast<ButtonComponentBuilder<PropsBitmap | ButtonComponentPropId::anyOption> &>(*this);
  }

  /**
   The title font the button.

   @note  Calling this method on a builder that already has a complete set of options specified using \c options() will
   trigger a compilation error.
   */
  auto &titleFont(NS_RELEASES_ARGUMENT UIFont *f)
  {
    constexpr auto titleFontOverridesExistingOptions = PropBitmap::isSet(PropsBitmap, ButtonComponentPropId::options);
    static_assert(!titleFontOverridesExistingOptions, "Setting 'titleFont' overrides existing options");
    _options.titleFont = f;
    return reinterpret_cast<ButtonComponentBuilder<PropsBitmap | ButtonComponentPropId::anyOption> &>(*this);
  }

  /**
   The title alignment

   @note  Calling this method on a builder that already has a complete set of options specified using \c options() will
   trigger a compilation error.
   */
  auto &titleAlignment(NSTextAlignment a)
  {
    constexpr auto titleAlignmentOverridesExistingOptions =
      PropBitmap::isSet(PropsBitmap, ButtonComponentPropId::options);
    static_assert(!titleAlignmentOverridesExistingOptions, "Setting 'titleAlignment' overrides existing options");
    _options.titleAlignment = a;
    return reinterpret_cast<ButtonComponentBuilder<PropsBitmap | ButtonComponentPropId::anyOption> &>(*this);
  }

  /**
   Whether the button is selected. Default is \c NO .

   @note  Calling this method on a builder that already has a complete set of options specified using \c options() will
   trigger a compilation error.
   */
  auto &selected(BOOL s)
  {
    constexpr auto selectedOverridesExistingOptions = PropBitmap::isSet(PropsBitmap, ButtonComponentPropId::options);
    static_assert(!selectedOverridesExistingOptions, "Setting 'selected' overrides existing options");
    _options.selected = s;
    return reinterpret_cast<ButtonComponentBuilder<PropsBitmap | ButtonComponentPropId::anyOption> &>(*this);
  }

  /**
   Whether the button is enabled. Default is \c YES .

   @note  Calling this method on a builder that already has a complete set of options specified using \c options() will
   trigger a compilation error.
   */
  auto &enabled(BOOL e)
  {
    constexpr auto enabledOverridesExistingOptions = PropBitmap::isSet(PropsBitmap, ButtonComponentPropId::options);
    static_assert(!enabledOverridesExistingOptions, "Setting 'enabled' overrides existing options");
    _options.enabled = e;
    return reinterpret_cast<ButtonComponentBuilder<PropsBitmap | ButtonComponentPropId::anyOption> &>(*this);
  }

  /**
   The maximum number of lines to use for rendering text. Default is 1 .

   @warning Setting \c numberOfLines to 0 or less can create unpredictible behaviour between displaying the label and
   the buttons size. \c UIButton 's \c titleLabel property isn't bound to the bounds of it's housing \c UIButton, which
   can lead to the text displaying incorrectly.

   @note  Calling this method on a builder that already has a complete set of options specified using \c options() will
   trigger a compilation error.
   */
  auto &numberOfLines(NSInteger n)
  {
    constexpr auto numberOfLinesOverridesExistingOptions =
      PropBitmap::isSet(PropsBitmap, ButtonComponentPropId::options);
    static_assert(!numberOfLinesOverridesExistingOptions, "Setting 'numberOfLines' overrides existing options");
    _options.numberOfLines = n;
    return reinterpret_cast<ButtonComponentBuilder<PropsBitmap | ButtonComponentPropId::anyOption> &>(*this);
  }

  /**
   The line break mode for the title label. Default is \c NSLineBreakByTruncatingMiddle .

   @note  Calling this method on a builder that already has a complete set of options specified using \c options() will
   trigger a compilation error.
   */
  auto &lineBreakMode(NSLineBreakMode m)
  {
    constexpr auto lineBreakModeOverridesExistingOptions =
      PropBitmap::isSet(PropsBitmap, ButtonComponentPropId::options);
    static_assert(!lineBreakModeOverridesExistingOptions, "Setting 'lineBreakMode' overrides existing options");
    _options.lineBreakMode = m;
    return reinterpret_cast<ButtonComponentBuilder<PropsBitmap | ButtonComponentPropId::anyOption> &>(*this);
  }

  /**
   The inset or outset margins for the rectangle around the button's content. Default is \c UIEdgeInsetsZero .

   @note  Calling this method on a builder that already has a complete set of options specified using \c options() will
   trigger a compilation error.
   */
  auto &contentEdgeInsets(UIEdgeInsets i)
  {
    constexpr auto contentEdgeInsetsOverridesExistingOptions =
      PropBitmap::isSet(PropsBitmap, ButtonComponentPropId::options);
    static_assert(!contentEdgeInsetsOverridesExistingOptions, "Setting 'contentEdgeInsets' overrides existing options");
    _options.contentEdgeInsets = i;
    return reinterpret_cast<ButtonComponentBuilder<PropsBitmap | ButtonComponentPropId::anyOption> &>(*this);
  }

  /**
   The inset or outset margins for the rectangle around the button's title text. Default is \c UIEdgeInsetsZero .

   @note  Calling this method on a builder that already has a complete set of options specified using \c options() will
   trigger a compilation error.
   */
  auto &titleEdgeInsets(UIEdgeInsets i)
  {
    constexpr auto titleEdgeInsetsOverridesExistingOptions =
      PropBitmap::isSet(PropsBitmap, ButtonComponentPropId::options);
    static_assert(!titleEdgeInsetsOverridesExistingOptions, "Setting 'titleEdgeInsets' overrides existing options");
    _options.titleEdgeInsets = i;
    return reinterpret_cast<ButtonComponentBuilder<PropsBitmap | ButtonComponentPropId::anyOption> &>(*this);
  }

  /**
   The inset or outset margins for the rectangle around the button's image. Default is \c UIEdgeInsetsZero .

   @note  Calling this method on a builder that already has a complete set of options specified using \c options() will
   trigger a compilation error.
   */
  auto &imageEdgeInsets(UIEdgeInsets i)
  {
    constexpr auto imageEdgeInsetsOverridesExistingOptions =
      PropBitmap::isSet(PropsBitmap, ButtonComponentPropId::options);
    static_assert(!imageEdgeInsetsOverridesExistingOptions, "Setting 'imageEdgeInsets' overrides existing options");
    _options.imageEdgeInsets = i;
    return reinterpret_cast<ButtonComponentBuilder<PropsBitmap | ButtonComponentPropId::anyOption> &>(*this);
  }

  /**
   The outset for tap target expansion Default is \c UIEdgeInsetsZero .

   @note  Calling this method on a builder that already has a complete set of options specified using \c options() will
   trigger a compilation error.
   */
  auto &tapTargetExpansion(UIEdgeInsets i)
  {
    constexpr auto tapTargetExpansionOverridesExistingOptions =
      PropBitmap::isSet(PropsBitmap, ButtonComponentPropId::options);
    static_assert(!tapTargetExpansionOverridesExistingOptions,
                  "Setting 'tapTargetExpansion' overrides existing options");
    _options.tapTargetExpansion = i;
    return reinterpret_cast<ButtonComponentBuilder<PropsBitmap | ButtonComponentPropId::anyOption> &>(*this);
  }

  /**
   Specifies the options for the component.

   @note Calling this method on a builder that already has any of the options set will trigger a compilation error.
   */
  auto &options(const CKButtonComponentOptions &opts)
  {
    constexpr auto optionsOverrideExistingOptions = PropBitmap::isSet(PropsBitmap, ButtonComponentPropId::anyOption);
    static_assert(!optionsOverrideExistingOptions, "Setting options overrides existing options");
    _options = opts;
    return reinterpret_cast<ButtonComponentBuilder<PropsBitmap | ButtonComponentPropId::options> &>(*this);
  }

  /**
   Specifies a background color that a view for the component should have.

   @param c A background color to set

   @note Calling this method on a builder that already has a complete set of options specified using \c options() will
   trigger a compilation error.
   */
  auto &backgroundColor(NS_RELEASES_ARGUMENT UIColor *c)
  {
    constexpr auto backgroundColorOverridesExistingOptions =
      PropBitmap::isSet(PropsBitmap, ButtonComponentPropId::options);
    static_assert(!backgroundColorOverridesExistingOptions, "Setting 'backgroundColor' overrides existing options");
    _options.attributes.insert({ @selector(setBackgroundColor:), c });
    return reinterpret_cast<ButtonComponentBuilder<PropsBitmap | ButtonComponentPropId::anyOption> &>(*this);
  }

  /**
   Specifies whether a view for the component should ignore user events.

   @param enabled A Boolean value that determines whether user events are ignored

   @note  Calling this method on a builder that already has a complete set of options specified using \c options() will
   trigger a compilation error.
   */
  auto &userInteractionEnabled(bool enabled)
  {
    constexpr auto userInteractionEnabledOverridesExistingOptions =
      PropBitmap::isSet(PropsBitmap, ButtonComponentPropId::options);
    static_assert(!userInteractionEnabledOverridesExistingOptions,
                  "Setting 'userInteractionEnabled' overrides existing options");
    _options.attributes.insert({ @selector(setUserInteractionEnabled:), enabled });
    return reinterpret_cast<ButtonComponentBuilder<PropsBitmap | ButtonComponentPropId::anyOption> &>(*this);
  }

  /**
   Specifies whether subviews of a view for the component should be confined to its bounds.

   @param clip A Boolean value that determines whether subviews are confined

   @note  Calling this method on a builder that already has a complete set of options specified using \c options() will
   trigger a compilation error.
   */
  auto &clipsToBounds(bool clip)
  {
    constexpr auto clipsToBoundsOverridesExistingOptions =
      PropBitmap::isSet(PropsBitmap, ButtonComponentPropId::options);
    static_assert(!clipsToBoundsOverridesExistingOptions, "Setting 'clipsToBounds' overrides existing options");
    _options.attributes.insert({ @selector(setClipsToBounds:), clip });
    return reinterpret_cast<ButtonComponentBuilder<PropsBitmap | ButtonComponentPropId::anyOption> &>(*this);
  }

  /**
   Specifies the alpha value for this component's view.

   @param a A floating-point number in the range 0.0 to 1.0, where 0.0 represents totally transparent and 1.0 represents
   totally opaque.

   @note  Calling this method on a builder that already has a complete set of options specified using \c options() will
   trigger a compilation error.
   */
  auto &alpha(CGFloat a)
  {
    constexpr auto alphaOverridesExistingOptions = PropBitmap::isSet(PropsBitmap, ButtonComponentPropId::options);
    static_assert(!alphaOverridesExistingOptions, "Setting 'alpha' overrides existing options");
    _options.attributes.insert({ @selector(setAlpha:), a });
    return reinterpret_cast<ButtonComponentBuilder<PropsBitmap | ButtonComponentPropId::anyOption> &>(*this);
  }

  /**
   Specifies the width of the border for this component's view.

   @param w The border width. When this value is greater than 0.0, the view draws a border using the current borderColor
   value.

   @note  Calling this method on a builder that already has a complete set of options specified using \c options() will
   trigger a compilation error.
   */
  auto &borderWidth(CGFloat w)
  {
    constexpr auto borderWidthOverridesExistingOptions = PropBitmap::isSet(PropsBitmap, ButtonComponentPropId::options);
    static_assert(!borderWidthOverridesExistingOptions, "Setting 'borderWidth' overrides existing options");
    _options.attributes.insert({ CKComponentViewAttribute::LayerAttribute(@selector(setBorderWidth:)), w });
    return reinterpret_cast<ButtonComponentBuilder<PropsBitmap | ButtonComponentPropId::anyOption> &>(*this);
  }

  /**
   Specifies the color of the border for this component's view.

   @param c A @c UIColor value that determines the border color. The default value of this property is an opaque black.

   @note  Calling this method on a builder that already has a complete set of options specified using \c options() will
   trigger a compilation error.
   */
  auto &borderColor(NS_RELEASES_ARGUMENT UIColor *c)
  {
    constexpr auto borderColorOverridesExistingOptions = PropBitmap::isSet(PropsBitmap, ButtonComponentPropId::options);
    static_assert(!borderColorOverridesExistingOptions, "Setting 'borderColor' overrides existing options");
    _options.attributes.insert({ CKComponentViewAttribute::LayerAttribute(@selector(setBorderColor:)), (id)c.CGColor });
    return reinterpret_cast<ButtonComponentBuilder<PropsBitmap | ButtonComponentPropId::anyOption> &>(*this);
  }

  /**
   Specifies the radius to use when drawing rounded corners for the component's view background.

   @param r A floating point value that determines the radius. Setting the radius to a value greater than 0.0 causes the
   view to begin drawing rounded corners on its background.

   @note  Calling this method on a builder that already has a complete set of options specified using \c options() will
   trigger a compilation error.
   */
  auto &cornerRadius(CGFloat r)
  {
    constexpr auto cornerRadiusOverridesExistingOptions =
      PropBitmap::isSet(PropsBitmap, ButtonComponentPropId::options);
    static_assert(!cornerRadiusOverridesExistingOptions, "Setting 'cornerRadius' overrides existing options");
    _options.attributes.insert({ CKComponentViewAttribute::LayerAttribute(@selector(setCornerRadius:)), r });
    return reinterpret_cast<ButtonComponentBuilder<PropsBitmap | ButtonComponentPropId::anyOption> &>(*this);
  }

  /**
   Specifies the action that should be sent when the user performs a single tap gesture on the component's view.

   @param a A @c CKAction instance to be sent when the gesture is recognized.

   @note  Calling this method on a builder that already has a complete set of options specified using \c options() will
   trigger a compilation error.
   */
  auto &onTap(CKAction<UIGestureRecognizer *> a)
  {
    constexpr auto onTapOverridesExistingOptions = PropBitmap::isSet(PropsBitmap, ButtonComponentPropId::options);
    static_assert(!onTapOverridesExistingOptions, "Setting 'onTap' overrides existing options");
    _options.attributes.insert(CKComponentTapGestureAttribute(a));
    return reinterpret_cast<ButtonComponentBuilder<PropsBitmap | ButtonComponentPropId::anyOption> &>(*this);
  }

  /**
   Specifies a selector that should be sent up the responder chain when the component's view receives any event that
   matches a given event mask.

   @param events  Events that should trigger the action.
   @param action  A selector to send.

   @note  Calling this method on a builder that already has a complete set of options specified using \c options() will
   trigger a compilation error.
   */
  auto &onControlEvents(UIControlEvents events, SEL action)
  {
    constexpr auto onControlEventsOverridesExistingOptions =
      PropBitmap::isSet(PropsBitmap, ButtonComponentPropId::options);
    static_assert(!onControlEventsOverridesExistingOptions, "Setting 'onControlEvents' overrides existing options");
    _options.attributes.insert(CKComponentActionAttribute(action, events));
    return reinterpret_cast<ButtonComponentBuilder<PropsBitmap | ButtonComponentPropId::anyOption> &>(*this);
  }

  /**
   Specifies an action that should be invoked when the component's view receives any event that
   matches a given event mask.

   @param events  Events that should trigger the action.
   @param action  An action to invoke.

   @note  Calling this method on a builder that already has a complete set of options specified using \c options() will
   trigger a compilation error.
   */
  auto &onControlEvents(UIControlEvents events, CKAction<> action)
  {
    constexpr auto onControlEventsOverridesExistingOptions =
      PropBitmap::isSet(PropsBitmap, ButtonComponentPropId::options);
    static_assert(!onControlEventsOverridesExistingOptions, "Setting 'onControlEvents' overrides existing options");
    _options.attributes.insert(CKComponentActionAttribute(action, events));
    return reinterpret_cast<ButtonComponentBuilder<PropsBitmap | ButtonComponentPropId::anyOption> &>(*this);
  }

  /**
   Used to determine how a view lays out its content when its bounds change. The default is @c
   UIViewContentModeScaleToFill .

   @param m A mode to set.

   @note  Calling this method on a builder that already has a complete set of options specified using \c options() will
   trigger a compilation error.
   */
  auto &contentMode(UIViewContentMode m)
  {
    constexpr auto contentModeOverridesExistingOptions = PropBitmap::isSet(PropsBitmap, ButtonComponentPropId::options);
    static_assert(!contentModeOverridesExistingOptions, "Setting 'contentMode' overrides existing options");
    _options.attributes.insert({ @selector(setContentMode:), m });
    return reinterpret_cast<ButtonComponentBuilder<PropsBitmap | ButtonComponentPropId::anyOption> &>(*this);
  }

  /**
   Sets a value for an arbitrary view property by specifying a selector that corresponds to the property setter and the
   value.

   @param attr A selector corresponding to a setter.
   @param value A value to set.

   @note  Calling this method on a builder that already has a complete set of options specified using \c options() will
   trigger a compilation error.
   */
  auto &attribute(SEL attr, NS_RELEASES_ARGUMENT id value)
  {
    constexpr auto attributeOverridesExistingOptions = PropBitmap::isSet(PropsBitmap, ButtonComponentPropId::options);
    static_assert(!attributeOverridesExistingOptions, "Setting 'attribute' overrides existing options");
    _options.attributes.insert({attr, value});
    return reinterpret_cast<ButtonComponentBuilder<PropsBitmap | ButtonComponentPropId::anyOption> &>(*this);
  }

  /**
   Sets a value for an arbitrary view property by specifying a complete attribute descriptor and a value.

   @param attr An view attribute descriptor.
   @param value A value to set. Both expressions of boxable types, such as @c int or @c CGFloat, and ObjC objects are
   supported.

   @note  Calling this method on a builder that already has a complete set of options specified using \c options() will
   trigger a compilation error.
   */
  auto &attribute(const CKComponentViewAttribute &attr, const CKBoxedValue &value)
  {
    constexpr auto attributeOverridesExistingOptions = PropBitmap::isSet(PropsBitmap, ButtonComponentPropId::options);
    static_assert(!attributeOverridesExistingOptions, "Setting 'attribute' overrides existing options");
    _options.attributes.insert({attr, value});
    return reinterpret_cast<ButtonComponentBuilder<PropsBitmap | ButtonComponentPropId::anyOption> &>(*this);
  }

  /**
   Adds a complete attribute / value pair to the component view configuration, mostly for convenience for helper
   functions that return both an attribute and a value.

   @param v An attribute / value pair.

   @note  Calling this method on a builder that already has a complete set of options specified using \c options() will
   trigger a compilation error.
   */
  auto &attribute(const CKComponentViewAttributeValue &v)
  {
    constexpr auto attributeOverridesExistingOptions = PropBitmap::isSet(PropsBitmap, ButtonComponentPropId::options);
    static_assert(!attributeOverridesExistingOptions, "Setting 'attribute' overrides existing options");
    _options.attributes.insert(v);
    return reinterpret_cast<ButtonComponentBuilder<PropsBitmap | ButtonComponentPropId::anyOption> &>(*this);
  }

  /**
   Specifies a complete attribute map for a view of this component.

   @param a  The attribute map to set.

   @note  Calling this method on a builder that already has a complete set of options specified using \c options() will
   trigger a compilation error.
   */
  auto &attributes(CKViewComponentAttributeValueMap a)
  {
    constexpr auto attributesOverrideExistingOptions = PropBitmap::isSet(PropsBitmap, ButtonComponentPropId::options);
    static_assert(!attributesOverrideExistingOptions, "Setting 'attributes' overrides existing options");
    _options.attributes = std::move(a);
    return reinterpret_cast<ButtonComponentBuilder<PropsBitmap | ButtonComponentPropId::anyOption> &>(*this);
  }

  /**
   Specifies an accessibility configuration for a view of this component, which will be applied when accessibility is
   enabled.

   @param c  Accessibility configuration to set.

   @note  Calling this method on a builder that already has a complete set of options specified using \c options() will
   trigger a compilation error.
   */
  auto &accessibilityContext(CKAccessibilityContext c)
  {
    constexpr auto accessibilityContextOverridesExistingOptions =
      PropBitmap::isSet(PropsBitmap, ButtonComponentPropId::options);
    static_assert(!accessibilityContextOverridesExistingOptions,
                  "Setting 'accessibilityContext' overrides existing options");
    _options.accessibilityContext = std::move(c);
    return reinterpret_cast<ButtonComponentBuilder<PropsBitmap | ButtonComponentPropId::anyOption> &>(*this);
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

    if (!PropBitmap::isSet(PropsBitmap, ButtonComponentPropId::options)) {
      // Only set these when a complete `CKButtonComponentOptions` struct wasn't specified explicitly.
      _options.titles = std::move(_titles);
      _options.titleColors = std::move(_titleColors);
      _options.images = std::move(_images);
      _options.backgroundImages = std::move(_backgroundImages);

      if (PropBitmap::isSet(PropsBitmap, ComponentBuilderBasePropId::size)) {
        _options.size = this->_size;
      }
    }

    return [[CKButtonComponent alloc] initWithAction:std::move(_action) options:std::move(_options)];
  }

 private:
  CKButtonComponentStateMap<NSString *>::Map _titles{};
  CKButtonComponentStateMap<UIColor *>::Map _titleColors{};
  CKButtonComponentStateMap<UIImage *>::Map _images{};
  CKButtonComponentStateMap<UIImage *>::Map _backgroundImages{};

  CKAction<UIEvent *> _action{};
  CKButtonComponentOptions _options{};
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
