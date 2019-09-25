/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#pragma once

#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKComponentGestureActions.h>
#import <ComponentKit/CKPropBitmap.h>

namespace CK {
namespace BuilderDetails {
enum class ComponentBuilderBasePropId { viewClass = 1 << 0, viewConfig = 1 << 1, size = 1 << 2 };

using ComponentBuilderBaseBitmapType = std::underlying_type_t<ComponentBuilderBasePropId>;

template <template <ComponentBuilderBaseBitmapType> class Derived, ComponentBuilderBaseBitmapType PropsBitmap>
class __attribute__((__may_alias__)) ComponentBuilderBase {
 public:
  __attribute__((noinline)) ComponentBuilderBase() = default;
  ComponentBuilderBase(const ComponentBuilderBase &) = delete;

  auto operator=(const ComponentBuilderBase &) = delete;

  /**
   Specifies that the component should have a view of the given class. The class will be instantiated with UIView's
   designated initializer @c-initWithFrame:.
   */
  __attribute__((noinline)) auto &viewClass(Class c)
  {
    constexpr auto viewClassOverridesExistingViewConfiguration =
        PropBitmap::isSet(PropsBitmap, ComponentBuilderBasePropId::viewConfig);
    static_assert(!viewClassOverridesExistingViewConfiguration,
                  "Setting 'viewClass' overrides existing view configuration");
    _viewClass = c;
    return reinterpret_cast<Derived<PropBitmap::set(PropsBitmap, ComponentBuilderBasePropId::viewClass)> &>(*this);
  }

  /**
   Specifies a view class that cannot be instantiated with @c-initWithFrame:.

   @param f A pointer to a function that returns a new instance of a view.
   */
  __attribute__((noinline)) auto &viewClass(CKComponentViewFactoryFunc f)
  {
    constexpr auto viewClassOverridesExistingViewConfiguration =
        PropBitmap::isSet(PropsBitmap, ComponentBuilderBasePropId::viewConfig);
    static_assert(!viewClassOverridesExistingViewConfiguration,
                  "Setting 'viewClass' overrides existing view configuration");
    _viewClass = f;
    return reinterpret_cast<Derived<PropBitmap::set(PropsBitmap, ComponentBuilderBasePropId::viewClass)> &>(*this);
  }

  /**
   Specifies an arbitrary view class.
   */
  __attribute__((noinline)) auto &viewClass(CKComponentViewClass c)
  {
    constexpr auto viewClassOverridesExistingViewConfiguration =
        PropBitmap::isSet(PropsBitmap, ComponentBuilderBasePropId::viewConfig);
    static_assert(!viewClassOverridesExistingViewConfiguration,
                  "Setting 'viewClass' overrides existing view configuration");
    _viewClass = std::move(c);
    return reinterpret_cast<Derived<PropBitmap::set(PropsBitmap, ComponentBuilderBasePropId::viewClass)> &>(*this);
  }

  /**
   Specifies a complete view configuration which will be used to create a view for the component.

   @param c A struct describing the view for this component.

   @note Calling this method on a builder that already has a view class or any of the view properties set will trigger
   a compilation error.

   @note This method only accepts temporaries as its argument. If you need to pass an existing variable use
   @c std::move().
   */
  __attribute__((noinline)) auto &view(CKComponentViewConfiguration &&c)
  {
    constexpr auto viewConfigurationOverridesExistingViewClass =
        PropBitmap::isSet(PropsBitmap, ComponentBuilderBasePropId::viewClass);
    static_assert(!viewConfigurationOverridesExistingViewClass,
                  "Setting view configuration overrides existing view class");
    _viewConfig = std::move(c);
    return reinterpret_cast<Derived<PropBitmap::set(PropsBitmap, ComponentBuilderBasePropId::viewConfig)> &>(*this);
  }

  /**
   Specifies a background color that a view for the component should have.

   @param c A background color to set

   @note Calling this method on a builder that does not have a view class set will trigger a compilation error.

   @note Calling this method on a builder that already has a complete view configuration set will trigger
   a compilation error.
   */
  __attribute__((noinline)) auto &backgroundColor(NS_RELEASES_ARGUMENT UIColor *c)
  {
    constexpr auto backgroundColorOverridesExistingViewConfiguration =
        PropBitmap::isSet(PropsBitmap, ComponentBuilderBasePropId::viewConfig);
    static_assert(!backgroundColorOverridesExistingViewConfiguration,
                  "Setting 'backgroundColor' overrides existing view configuration");
    constexpr auto viewClassIsSet = PropBitmap::isSet(PropsBitmap, ComponentBuilderBasePropId::viewClass);
    static_assert(viewClassIsSet, "Cannot set 'backgroundColor' without setting 'viewClass' first");
    _attributes.insert({ @selector(setBackgroundColor:), c });
    return reinterpret_cast<Derived<PropsBitmap> &>(*this);
  }

  /**
   Specifies whether a view for the component should ignore user events.

   @param enabled A Boolean value that determines whether user events are ignored

   @note Calling this method on a builder that does not have a view class set will trigger a compilation error.

   @note Calling this method on a builder that already has a complete view configuration set will trigger
   a compilation error.
   */
  __attribute__((noinline)) auto &userInteractionEnabled(bool enabled)
  {
    constexpr auto userInteractionEnabledOverridesExistingViewConfiguration =
        PropBitmap::isSet(PropsBitmap, ComponentBuilderBasePropId::viewConfig);
    static_assert(!userInteractionEnabledOverridesExistingViewConfiguration,
                  "Setting 'userInteractionEnabled' overrides existing view configuration");
    constexpr auto viewClassIsSet = PropBitmap::isSet(PropsBitmap, ComponentBuilderBasePropId::viewClass);
    static_assert(viewClassIsSet, "Cannot set 'userInteractionEnabled' without setting 'viewClass' first");
    _attributes.insert({ @selector(setUserInteractionEnabled:), enabled });
    return reinterpret_cast<Derived<PropsBitmap> &>(*this);
  }

  /**
   Specifies whether subviews of a view for the component should be confined to its bounds.

   @param enabled A Boolean value that determines whether subviews are confined

   @note Calling this method on a builder that does not have a view class set will trigger a compilation error.

   @note Calling this method on a builder that already has a complete view configuration set will trigger
   a compilation error.
   */
  __attribute__((noinline)) auto &clipsToBounds(bool clip)
  {
    constexpr auto clipsToBoundsOverridesExistingViewConfiguration =
        PropBitmap::isSet(PropsBitmap, ComponentBuilderBasePropId::viewConfig);
    static_assert(!clipsToBoundsOverridesExistingViewConfiguration,
                  "Setting 'clipsToBounds' overrides existing view configuration");
    constexpr auto viewClassIsSet = PropBitmap::isSet(PropsBitmap, ComponentBuilderBasePropId::viewClass);
    static_assert(viewClassIsSet, "Cannot set 'clipsToBounds' without setting 'viewClass' first");
    _attributes.insert({ @selector(setClipsToBounds:), clip });
    return reinterpret_cast<Derived<PropsBitmap> &>(*this);
  }

  /**
   Specifies the alpha value for this component's view.

   @param a A floating-point number in the range 0.0 to 1.0, where 0.0 represents totally transparent and 1.0 represents
   totally opaque.

   @note Calling this method on a builder that does not have a view class set will trigger a compilation error.

   @note Calling this method on a builder that already has a complete view configuration set will trigger
   a compilation error.
   */
  __attribute__((noinline)) auto &alpha(CGFloat a)
  {
    constexpr auto alphaOverridesExistingViewConfiguration =
        PropBitmap::isSet(PropsBitmap, ComponentBuilderBasePropId::viewConfig);
    static_assert(!alphaOverridesExistingViewConfiguration, "Setting 'alpha' overrides existing view configuration");
    constexpr auto viewClassIsSet = PropBitmap::isSet(PropsBitmap, ComponentBuilderBasePropId::viewClass);
    static_assert(viewClassIsSet, "Cannot set 'alpha' without setting 'viewClass' first");
    _attributes.insert({ @selector(setAlpha:), a });
    return reinterpret_cast<Derived<PropsBitmap> &>(*this);
  }

  /**
   Specifies the width of the border for this component's view.

   @param w The border width. When this value is greater than 0.0, the view draws a border using the current borderColor
   value.

   @note Calling this method on a builder that does not have a view class set will trigger a compilation error.

   @note Calling this method on a builder that already has a complete view configuration set will trigger
   a compilation error.
   */
  __attribute__((noinline)) auto &borderWidth(CGFloat w)
  {
    constexpr auto borderWidthOverridesExistingViewConfiguration =
        PropBitmap::isSet(PropsBitmap, ComponentBuilderBasePropId::viewConfig);
    static_assert(!borderWidthOverridesExistingViewConfiguration,
                  "Setting 'borderWidth' overrides existing view configuration");
    constexpr auto viewClassIsSet = PropBitmap::isSet(PropsBitmap, ComponentBuilderBasePropId::viewClass);
    static_assert(viewClassIsSet, "Cannot set 'borderWidth' without setting 'viewClass' first");
    _attributes.insert({ CKComponentViewAttribute::LayerAttribute(@selector(setBorderWidth:)), w });
    return reinterpret_cast<Derived<PropsBitmap> &>(*this);
  }

  /**
   Specifies the color of the border for this component's view.

   @param c A @c UIColor value that determines the border color. The default value of this property is an opaque black.

   @note Calling this method on a builder that does not have a view class set will trigger a compilation error.

   @note Calling this method on a builder that already has a complete view configuration set will trigger
   a compilation error.
   */
  __attribute__((noinline)) auto &borderColor(NS_RELEASES_ARGUMENT UIColor *c)
  {
    constexpr auto borderColorOverridesExistingViewConfiguration =
        PropBitmap::isSet(PropsBitmap, ComponentBuilderBasePropId::viewConfig);
    static_assert(!borderColorOverridesExistingViewConfiguration,
                  "Setting 'borderColor' overrides existing view configuration");
    constexpr auto viewClassIsSet = PropBitmap::isSet(PropsBitmap, ComponentBuilderBasePropId::viewClass);
    static_assert(viewClassIsSet, "Cannot set 'borderColor' without setting 'viewClass' first");
    _attributes.insert({ CKComponentViewAttribute::LayerAttribute(@selector(setBorderColor:)), (id)c.CGColor });
    return reinterpret_cast<Derived<PropsBitmap> &>(*this);
  }

  /**
   Specifies the radius to use when drawing rounded corners for the component's view background.

   @param r A floating point value that determines the radius. Setting the radius to a value greater than 0.0 causes the
   view to begin drawing rounded corners on its background.

   @note Calling this method on a builder that does not have a view class set will trigger a compilation error.

   @note Calling this method on a builder that already has a complete view configuration set will trigger
   a compilation error.
   */
  __attribute__((noinline)) auto &cornerRadius(CGFloat r)
  {
    constexpr auto cornerRadiusOverridesExistingViewConfiguration =
        PropBitmap::isSet(PropsBitmap, ComponentBuilderBasePropId::viewConfig);
    static_assert(!cornerRadiusOverridesExistingViewConfiguration,
                  "Setting 'cornerRadius' overrides existing view configuration");
    constexpr auto viewClassIsSet = PropBitmap::isSet(PropsBitmap, ComponentBuilderBasePropId::viewClass);
    static_assert(viewClassIsSet, "Cannot set 'cornerRadius' without setting 'viewClass' first");
    _attributes.insert({ CKComponentViewAttribute::LayerAttribute(@selector(setCornerRadius:)), r });
    return reinterpret_cast<Derived<PropsBitmap> &>(*this);
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
    constexpr auto onTapOverridesExistingViewConfiguration =
        PropBitmap::isSet(PropsBitmap, ComponentBuilderBasePropId::viewConfig);
    static_assert(!onTapOverridesExistingViewConfiguration, "Setting 'onTap' overrides existing view configuration");
    constexpr auto viewClassIsSet = PropBitmap::isSet(PropsBitmap, ComponentBuilderBasePropId::viewClass);
    static_assert(viewClassIsSet, "Cannot set 'onTap' without setting 'viewClass' first");
    _attributes.insert(CKComponentTapGestureAttribute(a));
    return reinterpret_cast<Derived<PropsBitmap> &>(*this);
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
  __attribute__((noinline)) auto &attribute(SEL attr, NS_RELEASES_ARGUMENT id value)
  {
    constexpr auto attributeOverridesExistingViewConfiguration =
        PropBitmap::isSet(PropsBitmap, ComponentBuilderBasePropId::viewConfig);
    static_assert(!attributeOverridesExistingViewConfiguration,
                  "Setting 'attribute' overrides existing view configuration");
    constexpr auto viewClassIsSet = PropBitmap::isSet(PropsBitmap, ComponentBuilderBasePropId::viewClass);
    static_assert(viewClassIsSet, "Cannot set 'attribute' without setting 'viewClass' first");
    _attributes.insert({attr, value});
    return reinterpret_cast<Derived<PropsBitmap> &>(*this);
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
    constexpr auto attributeOverridesExistingViewConfiguration =
        PropBitmap::isSet(PropsBitmap, ComponentBuilderBasePropId::viewConfig);
    static_assert(!attributeOverridesExistingViewConfiguration,
                  "Setting 'attribute' overrides existing view configuration");
    constexpr auto viewClassIsSet = PropBitmap::isSet(PropsBitmap, ComponentBuilderBasePropId::viewClass);
    static_assert(viewClassIsSet, "Cannot set 'attribute' without setting 'viewClass' first");
    _attributes.insert({attr, value});
    return reinterpret_cast<Derived<PropsBitmap> &>(*this);
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
    constexpr auto attributeOverridesExistingViewConfiguration =
        PropBitmap::isSet(PropsBitmap, ComponentBuilderBasePropId::viewConfig);
    static_assert(!attributeOverridesExistingViewConfiguration,
                  "Setting 'attribute' overrides existing view configuration");
    constexpr auto viewClassIsSet = PropBitmap::isSet(PropsBitmap, ComponentBuilderBasePropId::viewClass);
    static_assert(viewClassIsSet, "Cannot set 'attributeValue' without setting 'viewClass' first");
    _attributes.insert(v);
    return reinterpret_cast<Derived<PropsBitmap> &>(*this);
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
  __attribute__((noinline)) auto &onTouchUpInside(SEL action)
  {
    constexpr auto onTouchUpInsideOverridesExistingViewConfiguration =
        PropBitmap::isSet(PropsBitmap, ComponentBuilderBasePropId::viewConfig);
    static_assert(!onTouchUpInsideOverridesExistingViewConfiguration,
                  "Setting 'onTouchUpInside' overrides existing view configuration");
    constexpr auto viewClassIsSet = PropBitmap::isSet(PropsBitmap, ComponentBuilderBasePropId::viewClass);
    static_assert(viewClassIsSet, "Cannot set 'onTouchUpInside' without setting 'viewClass' first");
    _attributes.insert(CKComponentActionAttribute(action));
    return reinterpret_cast<Derived<PropsBitmap> &>(*this);
  }

  /**
   Specifies an action that should be sent when the component's view receives a 'touch up inside' event.

   @param action  An action to send.

   @note Setting this property on a view that is not a @c UIControl subclass will trigger a runtime error.

   @note Calling this method on a builder that does not have a view class set will trigger a compilation error.

   @note Calling this method on a builder that already has a complete view configuration set will trigger
   a compilation error.
   */
  __attribute__((noinline)) auto &onTouchUpInside(const CKAction<UIEvent *> &action)
  {
    constexpr auto onTouchUpInsideOverridesExistingViewConfiguration =
        PropBitmap::isSet(PropsBitmap, ComponentBuilderBasePropId::viewConfig);
    static_assert(!onTouchUpInsideOverridesExistingViewConfiguration,
                  "Setting 'onTouchUpInside' overrides existing view configuration");
    constexpr auto viewClassIsSet = PropBitmap::isSet(PropsBitmap, ComponentBuilderBasePropId::viewClass);
    static_assert(viewClassIsSet, "Cannot set 'onTouchUpInside' without setting 'viewClass' first");
    _attributes.insert(CKComponentActionAttribute(action));
    return reinterpret_cast<Derived<PropsBitmap> &>(*this);
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
  __attribute__((noinline)) auto &onControlEvents(UIControlEvents events, SEL action)
  {
    constexpr auto onControlEventsOverridesExistingViewConfiguration =
        PropBitmap::isSet(PropsBitmap, ComponentBuilderBasePropId::viewConfig);
    static_assert(!onControlEventsOverridesExistingViewConfiguration,
                  "Setting 'onControlEvents' overrides existing view configuration");
    constexpr auto viewClassIsSet = PropBitmap::isSet(PropsBitmap, ComponentBuilderBasePropId::viewClass);
    static_assert(viewClassIsSet, "Cannot set 'onControlEvents' without setting 'viewClass' first");
    _attributes.insert(CKComponentActionAttribute(action, events));
    return reinterpret_cast<Derived<PropsBitmap> &>(*this);
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
  __attribute__((noinline)) auto &onControlEvents(UIControlEvents events, const CKAction<UIEvent *> &action)
  {
    constexpr auto onControlEventsOverridesExistingViewConfiguration =
        PropBitmap::isSet(PropsBitmap, ComponentBuilderBasePropId::viewConfig);
    static_assert(!onControlEventsOverridesExistingViewConfiguration,
                  "Setting 'onControlEvents' overrides existing view configuration");
    constexpr auto viewClassIsSet = PropBitmap::isSet(PropsBitmap, ComponentBuilderBasePropId::viewClass);
    static_assert(viewClassIsSet, "Cannot set 'onControlEvents' without setting 'viewClass' first");
    _attributes.insert(CKComponentActionAttribute(action, events));
    return reinterpret_cast<Derived<PropsBitmap> &>(*this);
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
    constexpr auto attributesOverrideExistingViewConfiguration =
        PropBitmap::isSet(PropsBitmap, ComponentBuilderBasePropId::viewConfig);
    static_assert(!attributesOverrideExistingViewConfiguration,
                  "Setting 'attributes' overrides existing view configuration");
    constexpr auto viewClassIsSet = PropBitmap::isSet(PropsBitmap, ComponentBuilderBasePropId::viewClass);
    static_assert(viewClassIsSet, "Cannot set 'attributes' without setting 'viewClass' first");
    _attributes = std::move(a);
    return reinterpret_cast<Derived<PropsBitmap> &>(*this);
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
    constexpr auto accessibilityContextOverridesExistingViewConfiguration =
        PropBitmap::isSet(PropsBitmap, ComponentBuilderBasePropId::viewConfig);
    static_assert(!accessibilityContextOverridesExistingViewConfiguration,
                  "Setting 'accessibilityContext' overrides existing view configuration");
    constexpr auto viewClassIsSet = PropBitmap::isSet(PropsBitmap, ComponentBuilderBasePropId::viewClass);
    static_assert(viewClassIsSet, "Cannot set 'accessibilityContext' without setting 'viewClass' first");
    _accessibilityCtx = std::move(c);
    return reinterpret_cast<Derived<PropsBitmap> &>(*this);
  }

  /**
   Specifies if changes to the component size can be animated automatically by ComponentKit infrastructure.

   @param b  A Boolean value that determines if such animations are blocked.

   @note Calling this method on a builder that does not have a view class set will trigger a compilation error.

   @note Calling this method on a builder that already has a complete view configuration set will trigger
   a compilation error.
   */
  auto &blockImplicitAnimations(bool b)
  {
    constexpr auto blockImplicitAnimationsOverridesExistingViewConfiguration =
        PropBitmap::isSet(PropsBitmap, ComponentBuilderBasePropId::viewConfig);
    static_assert(!blockImplicitAnimationsOverridesExistingViewConfiguration,
                  "Setting 'blockImplicitAnimations' overrides existing view configuration");
    constexpr auto viewClassIsSet = PropBitmap::isSet(PropsBitmap, ComponentBuilderBasePropId::viewClass);
    static_assert(viewClassIsSet, "Cannot set 'blockImplicitAnimations' without setting 'viewClass' first");
    _blockImplicitAnimations = b;
    return reinterpret_cast<Derived<PropsBitmap> &>(*this);
  }

  /**
   The width of the component relative to its parent's size.
   */
  auto &width(CKRelativeDimension w)
  {
    _size.width = w;
    return reinterpret_cast<Derived<PropBitmap::set(PropsBitmap, ComponentBuilderBasePropId::size)> &>(*this);
  }

  /**
   The width of the component.
   */
  auto &width(CGFloat w)
  {
    _size.width = w;
    return reinterpret_cast<Derived<PropBitmap::set(PropsBitmap, ComponentBuilderBasePropId::size)> &>(*this);
  }

  /**
   The height of the component relative to its parent's size.
   */
  auto &height(CKRelativeDimension h)
  {
    _size.height = h;
    return reinterpret_cast<Derived<PropBitmap::set(PropsBitmap, ComponentBuilderBasePropId::size)> &>(*this);
  }

  /**
   The height of the component.
   */
  auto &height(CGFloat h)
  {
    _size.height = h;
    return reinterpret_cast<Derived<PropBitmap::set(PropsBitmap, ComponentBuilderBasePropId::size)> &>(*this);
  }

  /**
   The minumum allowable width of the component relative to its parent's size.
   */
  auto &minWidth(CKRelativeDimension w)
  {
    _size.minWidth = w;
    return reinterpret_cast<Derived<PropBitmap::set(PropsBitmap, ComponentBuilderBasePropId::size)> &>(*this);
  }

  /**
   The minumum allowable height of the component relative to its parent's size.
   */
  auto &minHeight(CKRelativeDimension h)
  {
    _size.minHeight = h;
    return reinterpret_cast<Derived<PropBitmap::set(PropsBitmap, ComponentBuilderBasePropId::size)> &>(*this);
  }

  /**
   The maximum allowable width of the component relative to its parent's size.
   */
  auto &maxWidth(CKRelativeDimension w)
  {
    _size.maxWidth = w;
    return reinterpret_cast<Derived<PropBitmap::set(PropsBitmap, ComponentBuilderBasePropId::size)> &>(*this);
  }

  /**
   The maximum allowable height of the component relative to its parent's size.
   */
  auto &maxHeight(CKRelativeDimension h)
  {
    _size.maxHeight = h;
    return reinterpret_cast<Derived<PropBitmap::set(PropsBitmap, ComponentBuilderBasePropId::size)> &>(*this);
  }

  /**
   Specifies a size constraint that should apply to this component.
   */
  __attribute__((noinline)) auto &size(CKComponentSize &&s)
  {
    _size = std::move(s);
    return reinterpret_cast<Derived<PropBitmap::set(PropsBitmap, ComponentBuilderBasePropId::size)> &>(*this);
  }

  /**
   Specifies a size constraint that should apply to this component.
   */
  __attribute__((noinline)) auto &size(const CKComponentSize &s)
  {
    _size = s;
    return reinterpret_cast<Derived<PropBitmap::set(PropsBitmap, ComponentBuilderBasePropId::size)> &>(*this);
  }

 protected:
  CKComponentViewClass _viewClass;
  CKViewComponentAttributeValueMap _attributes;
  CKComponentAccessibilityContext _accessibilityCtx;
  bool _blockImplicitAnimations;

  CKComponentViewConfiguration _viewConfig;
  CKComponentSize _size;
};

template <ComponentBuilderBaseBitmapType PropsBitmap>
class __attribute__((__may_alias__)) ComponentBuilder : public ComponentBuilderBase<ComponentBuilder, PropsBitmap> {
 public:
  __attribute__((noinline)) ComponentBuilder() = default;

  __attribute__((noinline)) ~ComponentBuilder() = default;

  /**
   Creates a new component instance with specified properties.

   @note  This method must @b not be called more than once on a given component builder instance.
   */
  __attribute__((noinline)) NS_RETURNS_RETAINED auto build() noexcept -> CKComponent *
  {
    switch (PropsBitmap) {
      case 0:
        return [CKComponent newWithView:{} size:{}];
      case PropBitmap::withIds(ComponentBuilderBasePropId::viewConfig):
        return [CKComponent newWithView:this->_viewConfig size:{}];
      case PropBitmap::withIds(ComponentBuilderBasePropId::viewClass):
        return [CKComponent newWithView:{std::move(this->_viewClass),
                                         std::move(this->_attributes),
                                         std::move(this->_accessibilityCtx),
                                         this->_blockImplicitAnimations}
                                   size:{}];
      case PropBitmap::withIds(ComponentBuilderBasePropId::size):
        return [CKComponent newWithView:{} size:this->_size];
      case PropBitmap::withIds(ComponentBuilderBasePropId::viewClass, ComponentBuilderBasePropId::size):
        return [CKComponent newWithView:{std::move(this->_viewClass),
                                         std::move(this->_attributes),
                                         std::move(this->_accessibilityCtx),
                                         this->_blockImplicitAnimations}
                                   size:this->_size];
      case PropBitmap::withIds(ComponentBuilderBasePropId::viewConfig, ComponentBuilderBasePropId::size):
        return [CKComponent newWithView:this->_viewConfig size:this->_size];
      default:
        CKCFailAssert(@"Invalid bitmap: %u", PropsBitmap);
        return nil;
    }
  }
};
}

/**
 Provides a fluent API for creating instances of @c CKComponent base class.

 @example A component that renders a red square:
 @code
 CK::ComponentBuilder()
   .viewClass([UIView class])
   .backgroundColor(UIColor.redColor)
   .width(100)
   .height(100)
   .build()
 */
using ComponentBuilder = BuilderDetails::ComponentBuilder<0>;
}
