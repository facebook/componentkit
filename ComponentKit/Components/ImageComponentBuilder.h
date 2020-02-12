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
#import <ComponentKit/CKImageComponent.h>

namespace CK {
namespace BuilderDetails {
namespace ImageComponentPropId {
constexpr static auto image = ComponentBuilderBaseSizeOnlyPropId::__max << 1;
constexpr static auto anyAttribute = image << 1;
constexpr static auto __max = image;
}

template <PropsBitmapType PropsBitmap = 0>
class __attribute__((__may_alias__)) ImageComponentBuilder
: public ComponentBuilderBaseSizeOnly<ImageComponentBuilder, PropsBitmap> {
public:
  ImageComponentBuilder() = default;

  ~ImageComponentBuilder() = default;

  /**
   The image to display.
   */
  auto &image(NS_RELEASES_ARGUMENT UIImage *i)
  {
    constexpr auto imageIsNotSet = !PropBitmap::isSet(PropsBitmap, ImageComponentPropId::image);
    static_assert(imageIsNotSet, "Property 'image' is already set.");
    _image = i;
    return reinterpret_cast<
    ImageComponentBuilder<PropsBitmap | ImageComponentPropId::image> &>(*this);
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
    _attributes.insert({ @selector(setBackgroundColor:), c });
    return reinterpret_cast<ImageComponentBuilder<PropsBitmap | ImageComponentPropId::anyAttribute> &>(*this);
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
    _attributes.insert({ @selector(setUserInteractionEnabled:), enabled });
    return reinterpret_cast<ImageComponentBuilder<PropsBitmap | ImageComponentPropId::anyAttribute> &>(*this);
  }

  /**
   Specifies whether subviews of a view for the component should be confined to its bounds.

   @param clip A Boolean value that determines whether subviews are confined

   @note Calling this method on a builder that does not have a view class set will trigger a compilation error.

   @note Calling this method on a builder that already has a complete view configuration set will trigger
   a compilation error.
   */
  auto &clipsToBounds(bool clip)
  {
    _attributes.insert({ @selector(setClipsToBounds:), clip });
    return reinterpret_cast<ImageComponentBuilder<PropsBitmap | ImageComponentPropId::anyAttribute> &>(*this);
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
    _attributes.insert({ @selector(setAlpha:), a });
    return reinterpret_cast<ImageComponentBuilder<PropsBitmap | ImageComponentPropId::anyAttribute> &>(*this);
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
    _attributes.insert({ CKComponentViewAttribute::LayerAttribute(@selector(setBorderWidth:)), w });
    return reinterpret_cast<ImageComponentBuilder<PropsBitmap | ImageComponentPropId::anyAttribute> &>(*this);
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
    _attributes.insert({ CKComponentViewAttribute::LayerAttribute(@selector(setBorderColor:)), (id)c.CGColor });
    return reinterpret_cast<ImageComponentBuilder<PropsBitmap | ImageComponentPropId::anyAttribute> &>(*this);
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
    _attributes.insert({ CKComponentViewAttribute::LayerAttribute(@selector(setCornerRadius:)), r });
    return reinterpret_cast<ImageComponentBuilder<PropsBitmap | ImageComponentPropId::anyAttribute> &>(*this);
  }

  /**
   Specifies the action that should be sent when the user performs a single tap gesture on the component's view.

   @param a A @c CKAction instance to be sent when the gesture is recognized.

   @note Calling this method on a builder that does not have a view class set will trigger a compilation error.

   @note Calling this method on a builder that already has a complete view configuration set will trigger
   a compilation error.
   */
  auto &onTap(CKAction<UIGestureRecognizer *> a)
  {
    _attributes.insert(CKComponentTapGestureAttribute(a));
    return reinterpret_cast<ImageComponentBuilder<PropsBitmap | ImageComponentPropId::anyAttribute> &>(*this);
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
    _attributes.insert({attr, value});
    return reinterpret_cast<ImageComponentBuilder<PropsBitmap | ImageComponentPropId::anyAttribute> &>(*this);
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
    _attributes.insert({attr, value});
    return reinterpret_cast<ImageComponentBuilder<PropsBitmap | ImageComponentPropId::anyAttribute> &>(*this);
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
    _attributes.insert(v);
    return reinterpret_cast<ImageComponentBuilder<PropsBitmap | ImageComponentPropId::anyAttribute> &>(*this);
  }

  /**
   Specifies a selector that should be sent up the responder chain when the component's view receives a 'touch up
   inside' event.

   @param action  An selector to send.

   @note Setting this property on a view that is not a @c UIControl subclass will trigger a runtime error.

   @note Calling this method on a builder that does not have a view class set will trigger a compilation error.

   @note Calling this method on a builder that already has a complete view configuration set will trigger
   a compilation error.
   */
  auto &onTouchUpInside(SEL action)
  {
    _attributes.insert(CKComponentActionAttribute(action));
    return reinterpret_cast<ImageComponentBuilder<PropsBitmap | ImageComponentPropId::anyAttribute> &>(*this);
  }

  /**
   Specifies an action that should be sent when the component's view receives a 'touch up inside' event.

   @param action  An action to send.

   @note Setting this property on a view that is not a @c UIControl subclass will trigger a runtime error.

   @note Calling this method on a builder that does not have a view class set will trigger a compilation error.

   @note Calling this method on a builder that already has a complete view configuration set will trigger
   a compilation error.
   */
  auto &onTouchUpInside(const CKAction<UIEvent *> &action)
  {
    _attributes.insert(CKComponentActionAttribute(action));
    return reinterpret_cast<ImageComponentBuilder<PropsBitmap | ImageComponentPropId::anyAttribute> &>(*this);
  }

  /**
   Specifies a selector that should be sent up the responder chain when the component's view receives any event that
   matches a given event mask.

   @param events  Events that should trigger the action.
   @param action  An selector to send.

   @note Setting this property on a view that is not a @c UIControl subclass will trigger a runtime error.

   @note Calling this method on a builder that does not have a view class set will trigger a compilation error.

   @note Calling this method on a builder that already has a complete view configuration set will trigger
   a compilation error.
   */
  auto &onControlEvents(UIControlEvents events, SEL action)
  {
    _attributes.insert(CKComponentActionAttribute(action, events));
    return reinterpret_cast<ImageComponentBuilder<PropsBitmap | ImageComponentPropId::anyAttribute> &>(*this);
  }

  /**
   Specifies an action that should be sent when the component's view receives any event that matches a given event mask.

   @param events  Events that should trigger the action.
   @param action  An action to send.

   @note Setting this property on a view that is not a @c UIControl subclass will trigger a runtime error.

   @note Calling this method on a builder that does not have a view class set will trigger a compilation error.

   @note Calling this method on a builder that already has a complete view configuration set will trigger
   a compilation error.
   */
  auto &onControlEvents(UIControlEvents events, const CKAction<UIEvent *> &action)
  {
    _attributes.insert(CKComponentActionAttribute(action, events));
    return reinterpret_cast<ImageComponentBuilder<PropsBitmap | ImageComponentPropId::anyAttribute> &>(*this);
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
    constexpr auto noAttributesSet = !PropBitmap::isSet(PropsBitmap, ImageComponentPropId::anyAttribute);
    static_assert(noAttributesSet, "Setting 'attributes' overrides existing attributes.");
    _attributes = std::move(a);
    return reinterpret_cast<ImageComponentBuilder<PropsBitmap> &>(*this);
  }


private:
  friend BuilderBase<ImageComponentBuilder, PropsBitmap>;

  /**
   Creates a new component instance with specified properties.

   @note  This method must @b not be called more than once on a given component builder instance.
   */
  NS_RETURNS_RETAINED auto _build() noexcept -> CKImageComponent *
  {
    constexpr auto imageIsSet = PropBitmap::isSet(PropsBitmap, ImageComponentPropId::image);
    static_assert(imageIsSet, "Required property 'image' is not set.");

    if (PropBitmap::isSet(PropsBitmap, ComponentBuilderBaseSizeOnlyPropId::size)) {
      return [CKImageComponent newWithImage:_image
                                 attributes:std::move(_attributes)
                                       size:this->_size];
    } else {
      return [CKImageComponent newWithImage:_image
                                 attributes:std::move(_attributes)
                                       size:{}];
    }
  }

private:
  UIImage *_image;
  CKViewComponentAttributeValueMap _attributes;
};

}

/**
 Uses a static layout with the given image size and applies additional attributes.
 */
using ImageComponentBuilder = BuilderDetails::ImageComponentBuilder<>;
}

#endif
