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
#import <ComponentKit/CKAutoSizedImageComponent.h>

namespace CK {
namespace BuilderDetails {
namespace AutoSizedImageComponentPropId {
constexpr static auto image = BuilderBasePropId::__max << 1;
constexpr static auto __max = image;
}

template <PropsBitmapType PropsBitmap = 0>
class __attribute__((__may_alias__)) AutoSizedImageComponentBuilder
    : public BuilderBase<AutoSizedImageComponentBuilder, PropsBitmap> {
 public:
  AutoSizedImageComponentBuilder() = default;

  AutoSizedImageComponentBuilder(const CK::ComponentSpecContext &context)
    : BuilderBase<AutoSizedImageComponentBuilder, PropsBitmap>{context} { }

  ~AutoSizedImageComponentBuilder() = default;

  /**
   Size of image will be used in static layout.
   */
  auto &image(NS_RELEASES_ARGUMENT UIImage *image)
  {
    constexpr auto imageIsNotSet = !PropBitmap::isSet(PropsBitmap, AutoSizedImageComponentPropId::image);
    static_assert(imageIsNotSet, "Property 'image' is already set.");
    _image = image;
    return reinterpret_cast<
      AutoSizedImageComponentBuilder<PropsBitmap | AutoSizedImageComponentPropId::image> &>(*this);
  }

  /**
   Specifies a background color that a view for the component should have.

   @param c A background color to set
   */
  auto &backgroundColor(NS_RELEASES_ARGUMENT UIColor *c)
  {
    _attributes.insert({ @selector(setBackgroundColor:), c });
    return *this;
  }

  /**
   Specifies whether a view for the component should ignore user events.

   @param enabled A Boolean value that determines whether user events are ignored
   */
  auto &userInteractionEnabled(bool enabled)
  {
    _attributes.insert({ @selector(setUserInteractionEnabled:), enabled });
    return *this;
  }

  /**
   Specifies whether subviews of a view for the component should be confined to its bounds.

   @param clip A Boolean value that determines whether subviews are confined
   */
  auto &clipsToBounds(bool clip)
  {
    _attributes.insert({ @selector(setClipsToBounds:), clip });
    return *this;
  }

  /**
   Specifies the alpha value for this component's view.

   @param a A floating-point number in the range 0.0 to 1.0, where 0.0 represents totally transparent and 1.0 represents
   totally opaque.
   */
  auto &alpha(CGFloat a)
  {
    _attributes.insert({ @selector(setAlpha:), a });
    return *this;
  }

  /**
   Specifies the width of the border for this component's view.

   @param w The border width. When this value is greater than 0.0, the view draws a border using the current borderColor
   value.
   */
  auto &borderWidth(CGFloat w)
  {
    _attributes.insert({ CKComponentViewAttribute::LayerAttribute(@selector(setBorderWidth:)), w });
    return *this;
  }

  /**
   Specifies the color of the border for this component's view.

   @param c A @c UIColor value that determines the border color. The default value of this property is an opaque black.
   */
  auto &borderColor(NS_RELEASES_ARGUMENT UIColor *c)
  {
    _attributes.insert({ CKComponentViewAttribute::LayerAttribute(@selector(setBorderColor:)), (id)c.CGColor });
    return *this;
  }

  /**
   Specifies the radius to use when drawing rounded corners for the component's view background.

   @param r A floating point value that determines the radius. Setting the radius to a value greater than 0.0 causes the
   view to begin drawing rounded corners on its background.
   */
  auto &cornerRadius(CGFloat r)
  {
    _attributes.insert({ CKComponentViewAttribute::LayerAttribute(@selector(setCornerRadius:)), r });
    return *this;
  }

  /**
   Specifies the action that should be sent when the user performs a single tap gesture on the component's view.

   @param a A @c CKAction instance to be sent when the gesture is recognized.
   */
  auto &onTap(CKAction<UIGestureRecognizer *> a)
  {
    _attributes.insert(CKComponentTapGestureAttribute(a));
    return *this;
  }

  /**
   Used to determine how a view lays out its content when its bounds change. The default is @c UIViewContentModeScaleToFill .

   @param m A mode to set.
   */
  auto &contentMode(UIViewContentMode m)
  {
    _attributes.insert({@selector(setContentMode:), m});
    return *this;
  }

  /**
   Sets a value for an arbitrary view property by specifying a selector that corresponds to the property setter and the
   value.

   @param attr A selector corresponding to a setter.
   @param value A value to set.
   */
  auto &attribute(SEL attr, NS_RELEASES_ARGUMENT id value)
  {
    _attributes.insert({attr, value});
    return *this;
  }

  /**
   Sets a value for an arbitrary view property by specifying a complete attribute descriptor and a value.

   @param attr An view attribute descriptor.
   @param value A value to set. Both expressions of boxable types, such as @c int or @c CGFloat, and ObjC objects are
   supported.
   */
  auto &attribute(const CKComponentViewAttribute &attr, const CKBoxedValue &value)
  {
    _attributes.insert({attr, value});
    return *this;
  }

  /**
   Adds a complete attribute / value pair to the component view configuration, mostly for convenience for helper
   functions that return both an attribute and a value.

   @param v An attribute / value pair.
   */
  auto &attribute(const CKComponentViewAttributeValue &v)
  {
    _attributes.insert(v);
    return *this;
  }

  /**
   Specifies a complete attribute map for a view of this component.

   @param a  The attribute map to set.
   */
  auto &attributes(CKViewComponentAttributeValueMap a)
  {
    _attributes = std::move(a);
    return *this;
  }

 private:
  friend BuilderBase<AutoSizedImageComponentBuilder, PropsBitmap>;

  /**
  Creates a new component instance with specified properties.

  @note This method must @b not be called more than once on a given component builder instance.
  */
  NS_RETURNS_RETAINED auto _build() noexcept -> CKAutoSizedImageComponent *
  {
    constexpr auto imageIsSet = PropBitmap::isSet(PropsBitmap, AutoSizedImageComponentPropId::image);
    static_assert(imageIsSet, "Required property 'image' is not set.");
    return [[CKAutoSizedImageComponent alloc] initWithImage:_image attributes:std::move(_attributes)];
  }

 private:
  UIImage *_image;
  CKViewComponentAttributeValueMap _attributes{};
};

}

using AutoSizedImageComponentBuilderEmpty = BuilderDetails::AutoSizedImageComponentBuilder<>;
using AutoSizedImageComponentBuilderContext = BuilderDetails::AutoSizedImageComponentBuilder<BuilderDetails::BuilderBasePropId::context>;

/**
 A component that displays an image using UIImageView.
 */
auto AutoSizedImageComponentBuilder() -> AutoSizedImageComponentBuilderEmpty;

/**
 A component that displays an image using UIImageView.

 @param c The spec context to use.

 @note This factory overload is to be used when a key is required to reference the built component in a spec from the
 @c CK_ANIMATION function.
 */
auto AutoSizedImageComponentBuilder(const CK::ComponentSpecContext &c) -> AutoSizedImageComponentBuilderContext;
}

#endif
