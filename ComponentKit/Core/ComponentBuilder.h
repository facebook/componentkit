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

#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKComponentGestureActions.h>
#import <ComponentKit/CKNonNull.h>
#import <ComponentKit/CKPropBitmap.h>
#import <ComponentKit/CKTransitions.h>
#import <ComponentKit/CKOptional.h>
#import <ComponentKit/CKComponentSpecContext.h>

namespace CK {
namespace BuilderDetails {

namespace BuilderBasePropId {
  constexpr static auto context = 1ULL << 0;
  constexpr static auto transitions = context << 1;
  constexpr static auto key = transitions << 1;
  constexpr static auto __max = key;
};

template <template <PropsBitmapType> class Derived, PropsBitmapType PropsBitmap>
class __attribute__((__may_alias__)) BuilderBase {
  CK::ComponentSpecContext _context;
  id _key;

  NS_RETURNS_RETAINED auto _buildComponentWithTransitionsIfNeeded() noexcept -> CKComponent *
  {
    const auto component = static_cast<Derived<PropsBitmap> &>(*this)._build();
    if (PropBitmap::isSet(PropsBitmap, BuilderBasePropId::transitions)) {
      return CKComponentWithTransitions(component, _transitions);
    } else {
      return component;
    }
  }

protected:
  BuilderBase() = default;
  BuilderBase(CK::ComponentSpecContext context) : _context(std::move(context)) { }

public:
  /**
   Creates a new component instance and optionally wrap it with an animation component.

   @note  This method must @b not be called more than once on a given component builder instance.
   */
  NS_RETURNS_RETAINED auto build() noexcept -> CKComponent *
  {
    const auto component = _buildComponentWithTransitionsIfNeeded();
    if (PropBitmap::isSet(PropsBitmap, BuilderBasePropId::key)) {
      _context.declareKey(_key, component);
    }
    return component;
  }

  /**
   Specifies the key for the component. This key is only meant to be used from specs.

   @note Calling this method on a builder that wasn't created with a context will trigger a compilation error.

   @param key The key to reference the component built.
   */
  auto &key(CK::RelaxedNonNull<id> key)
  {
    constexpr auto contextIsSet =
        PropBitmap::isSet(PropsBitmap, BuilderBasePropId::context);
    static_assert(contextIsSet, "Cannot set 'key' without specifying 'context'");

    _key = key;
    return reinterpret_cast<Derived<PropsBitmap> &>(*this);
  }

  /**
   Specifies the animation on initial mount.

   @param animationInitial The animation to trigger on initial mount.
   */
  auto &animationInitial(CK::Animation::Initial animationInitial)
  {
    _transitions.onInitialMount = std::move(animationInitial);
    return reinterpret_cast<Derived<PropsBitmap | BuilderBasePropId::transitions> &>(*this);
  }

  /**
   Specifies the animation on final unmount.

   @param animationFinal The animation to trigger on final unmount.
   */
  auto &animationFinal(CK::Animation::Final animationFinal)
  {
    _transitions.onFinalUnmount = std::move(animationFinal);
    return reinterpret_cast<Derived<PropsBitmap | BuilderBasePropId::transitions> &>(*this);
  }

private:
  CKTransitions _transitions;
};

namespace ViewConfigBuilderPropId {
  constexpr static auto viewClass = BuilderBasePropId::__max << 1;
  constexpr static auto viewConfig = viewClass << 1;
  constexpr static auto __max = viewConfig;
}

template <template <PropsBitmapType> class Derived, PropsBitmapType PropsBitmap>
class __attribute__((__may_alias__)) ViewConfigBuilderBase {
public:
  ViewConfigBuilderBase() = default;
  ~ViewConfigBuilderBase() = default;

  /**
   Specifies that the component should have a view of the given class. The class will be instantiated with UIView's
   designated initializer @c-initWithFrame:.
   */
  auto &viewClass(Class c)
  {
    constexpr auto viewClassOverridesExistingViewConfiguration =
        PropBitmap::isSet(PropsBitmap, ViewConfigBuilderPropId::viewConfig);
    static_assert(!viewClassOverridesExistingViewConfiguration,
                  "Setting 'viewClass' overrides existing view configuration");
    _viewClass = c;
    return reinterpret_cast<Derived<PropsBitmap | ViewConfigBuilderPropId::viewClass> &>(*this);
  }

  /**
   Specifies a view class that cannot be instantiated with @c-initWithFrame:.

   @param f A pointer to a function that returns a new instance of a view.
   */
  auto &viewClass(CKComponentViewFactoryFunc f)
  {
    constexpr auto viewClassOverridesExistingViewConfiguration =
        PropBitmap::isSet(PropsBitmap, ViewConfigBuilderPropId::viewConfig);
    static_assert(!viewClassOverridesExistingViewConfiguration,
                  "Setting 'viewClass' overrides existing view configuration");
    _viewClass = f;
    return reinterpret_cast<Derived<PropsBitmap | ViewConfigBuilderPropId::viewClass> &>(*this);
  }

  /**
   Specifies an arbitrary view class.
   */
  auto &viewClass(CKComponentViewClass c)
  {
    constexpr auto viewClassOverridesExistingViewConfiguration =
        PropBitmap::isSet(PropsBitmap, ViewConfigBuilderPropId::viewConfig);
    static_assert(!viewClassOverridesExistingViewConfiguration,
                  "Setting 'viewClass' overrides existing view configuration");
    _viewClass = std::move(c);
    return reinterpret_cast<Derived<PropsBitmap | ViewConfigBuilderPropId::viewClass> &>(*this);
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
    constexpr auto backgroundColorOverridesExistingViewConfiguration =
        PropBitmap::isSet(PropsBitmap, ViewConfigBuilderPropId::viewConfig);
    static_assert(!backgroundColorOverridesExistingViewConfiguration,
                  "Setting 'backgroundColor' overrides existing view configuration");
    constexpr auto viewClassIsSet = PropBitmap::isSet(PropsBitmap, ViewConfigBuilderPropId::viewClass);
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
  auto &userInteractionEnabled(bool enabled)
  {
    constexpr auto userInteractionEnabledOverridesExistingViewConfiguration =
        PropBitmap::isSet(PropsBitmap, ViewConfigBuilderPropId::viewConfig);
    static_assert(!userInteractionEnabledOverridesExistingViewConfiguration,
                  "Setting 'userInteractionEnabled' overrides existing view configuration");
    constexpr auto viewClassIsSet = PropBitmap::isSet(PropsBitmap, ViewConfigBuilderPropId::viewClass);
    static_assert(viewClassIsSet, "Cannot set 'userInteractionEnabled' without setting 'viewClass' first");
    _attributes.insert({ @selector(setUserInteractionEnabled:), enabled });
    return reinterpret_cast<Derived<PropsBitmap> &>(*this);
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
    constexpr auto clipsToBoundsOverridesExistingViewConfiguration =
        PropBitmap::isSet(PropsBitmap, ViewConfigBuilderPropId::viewConfig);
    static_assert(!clipsToBoundsOverridesExistingViewConfiguration,
                  "Setting 'clipsToBounds' overrides existing view configuration");
    constexpr auto viewClassIsSet = PropBitmap::isSet(PropsBitmap, ViewConfigBuilderPropId::viewClass);
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
  auto &alpha(CGFloat a)
  {
    constexpr auto alphaOverridesExistingViewConfiguration =
        PropBitmap::isSet(PropsBitmap, ViewConfigBuilderPropId::viewConfig);
    static_assert(!alphaOverridesExistingViewConfiguration, "Setting 'alpha' overrides existing view configuration");
    constexpr auto viewClassIsSet = PropBitmap::isSet(PropsBitmap, ViewConfigBuilderPropId::viewClass);
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
  auto &borderWidth(CGFloat w)
  {
    constexpr auto borderWidthOverridesExistingViewConfiguration =
        PropBitmap::isSet(PropsBitmap, ViewConfigBuilderPropId::viewConfig);
    static_assert(!borderWidthOverridesExistingViewConfiguration,
                  "Setting 'borderWidth' overrides existing view configuration");
    constexpr auto viewClassIsSet = PropBitmap::isSet(PropsBitmap, ViewConfigBuilderPropId::viewClass);
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
  auto &borderColor(NS_RELEASES_ARGUMENT UIColor *c)
  {
    constexpr auto borderColorOverridesExistingViewConfiguration =
        PropBitmap::isSet(PropsBitmap, ViewConfigBuilderPropId::viewConfig);
    static_assert(!borderColorOverridesExistingViewConfiguration,
                  "Setting 'borderColor' overrides existing view configuration");
    constexpr auto viewClassIsSet = PropBitmap::isSet(PropsBitmap, ViewConfigBuilderPropId::viewClass);
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
  auto &cornerRadius(CGFloat r)
  {
    constexpr auto cornerRadiusOverridesExistingViewConfiguration =
        PropBitmap::isSet(PropsBitmap, ViewConfigBuilderPropId::viewConfig);
    static_assert(!cornerRadiusOverridesExistingViewConfiguration,
                  "Setting 'cornerRadius' overrides existing view configuration");
    constexpr auto viewClassIsSet = PropBitmap::isSet(PropsBitmap, ViewConfigBuilderPropId::viewClass);
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
        PropBitmap::isSet(PropsBitmap, ViewConfigBuilderPropId::viewConfig);
    static_assert(!onTapOverridesExistingViewConfiguration, "Setting 'onTap' overrides existing view configuration");
    constexpr auto viewClassIsSet = PropBitmap::isSet(PropsBitmap, ViewConfigBuilderPropId::viewClass);
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
  auto &attribute(SEL attr, NS_RELEASES_ARGUMENT id value)
  {
    constexpr auto attributeOverridesExistingViewConfiguration =
        PropBitmap::isSet(PropsBitmap, ViewConfigBuilderPropId::viewConfig);
    static_assert(!attributeOverridesExistingViewConfiguration,
                  "Setting 'attribute' overrides existing view configuration");
    constexpr auto viewClassIsSet = PropBitmap::isSet(PropsBitmap, ViewConfigBuilderPropId::viewClass);
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
        PropBitmap::isSet(PropsBitmap, ViewConfigBuilderPropId::viewConfig);
    static_assert(!attributeOverridesExistingViewConfiguration,
                  "Setting 'attribute' overrides existing view configuration");
    constexpr auto viewClassIsSet = PropBitmap::isSet(PropsBitmap, ViewConfigBuilderPropId::viewClass);
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
        PropBitmap::isSet(PropsBitmap, ViewConfigBuilderPropId::viewConfig);
    static_assert(!attributeOverridesExistingViewConfiguration,
                  "Setting 'attribute' overrides existing view configuration");
    constexpr auto viewClassIsSet = PropBitmap::isSet(PropsBitmap, ViewConfigBuilderPropId::viewClass);
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
  auto &onTouchUpInside(SEL action)
  {
    constexpr auto onTouchUpInsideOverridesExistingViewConfiguration =
        PropBitmap::isSet(PropsBitmap, ViewConfigBuilderPropId::viewConfig);
    static_assert(!onTouchUpInsideOverridesExistingViewConfiguration,
                  "Setting 'onTouchUpInside' overrides existing view configuration");
    constexpr auto viewClassIsSet = PropBitmap::isSet(PropsBitmap, ViewConfigBuilderPropId::viewClass);
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
  auto &onTouchUpInside(const CKAction<UIEvent *> &action)
  {
    constexpr auto onTouchUpInsideOverridesExistingViewConfiguration =
        PropBitmap::isSet(PropsBitmap, ViewConfigBuilderPropId::viewConfig);
    static_assert(!onTouchUpInsideOverridesExistingViewConfiguration,
                  "Setting 'onTouchUpInside' overrides existing view configuration");
    constexpr auto viewClassIsSet = PropBitmap::isSet(PropsBitmap, ViewConfigBuilderPropId::viewClass);
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
  auto &onControlEvents(UIControlEvents events, SEL action)
  {
    constexpr auto onControlEventsOverridesExistingViewConfiguration =
        PropBitmap::isSet(PropsBitmap, ViewConfigBuilderPropId::viewConfig);
    static_assert(!onControlEventsOverridesExistingViewConfiguration,
                  "Setting 'onControlEvents' overrides existing view configuration");
    constexpr auto viewClassIsSet = PropBitmap::isSet(PropsBitmap, ViewConfigBuilderPropId::viewClass);
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
  auto &onControlEvents(UIControlEvents events, const CKAction<UIEvent *> &action)
  {
    constexpr auto onControlEventsOverridesExistingViewConfiguration =
        PropBitmap::isSet(PropsBitmap, ViewConfigBuilderPropId::viewConfig);
    static_assert(!onControlEventsOverridesExistingViewConfiguration,
                  "Setting 'onControlEvents' overrides existing view configuration");
    constexpr auto viewClassIsSet = PropBitmap::isSet(PropsBitmap, ViewConfigBuilderPropId::viewClass);
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
        PropBitmap::isSet(PropsBitmap, ViewConfigBuilderPropId::viewConfig);
    static_assert(!attributesOverrideExistingViewConfiguration,
                  "Setting 'attributes' overrides existing view configuration");
    constexpr auto viewClassIsSet = PropBitmap::isSet(PropsBitmap, ViewConfigBuilderPropId::viewClass);
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
        PropBitmap::isSet(PropsBitmap, ViewConfigBuilderPropId::viewConfig);
    static_assert(!accessibilityContextOverridesExistingViewConfiguration,
                  "Setting 'accessibilityContext' overrides existing view configuration");
    constexpr auto viewClassIsSet = PropBitmap::isSet(PropsBitmap, ViewConfigBuilderPropId::viewClass);
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
        PropBitmap::isSet(PropsBitmap, ViewConfigBuilderPropId::viewConfig);
    static_assert(!blockImplicitAnimationsOverridesExistingViewConfiguration,
                  "Setting 'blockImplicitAnimations' overrides existing view configuration");
    constexpr auto viewClassIsSet = PropBitmap::isSet(PropsBitmap, ViewConfigBuilderPropId::viewClass);
    static_assert(viewClassIsSet, "Cannot set 'blockImplicitAnimations' without setting 'viewClass' first");
    _blockImplicitAnimations = b;
    return reinterpret_cast<Derived<PropsBitmap> &>(*this);
  }

protected:
  CKComponentViewClass _viewClass;
  CKViewComponentAttributeValueMap _attributes;
  CKComponentAccessibilityContext _accessibilityCtx;
  bool _blockImplicitAnimations;
};

template <PropsBitmapType PropsBitmap = 0>
class __attribute__((__may_alias__)) ViewConfigBuilder : public ViewConfigBuilderBase<ViewConfigBuilder, PropsBitmap> {
public:
  auto build() noexcept -> CKComponentViewConfiguration {
    return {
      std::move(this->_viewClass),
      std::move(this->_attributes),
      std::move(this->_accessibilityCtx),
      this->_blockImplicitAnimations
    };
  }
};

namespace ComponentBuilderBaseSizeOnlyPropId {
  constexpr static auto size = BuilderBasePropId::__max << 1;
  constexpr static auto __max = size;
}

template <template <PropsBitmapType> class Derived, PropsBitmapType PropsBitmap>
class __attribute__((__may_alias__)) ComponentBuilderBaseSizeOnly : public BuilderBase<Derived, PropsBitmap> {
public:
  ComponentBuilderBaseSizeOnly() = default;
  ~ComponentBuilderBaseSizeOnly() = default;

  /**
   The width of the component relative to its parent's size.
   */
  auto &width(CKRelativeDimension w)
  {
    _size.width = w;
    return reinterpret_cast<Derived<PropsBitmap | ComponentBuilderBaseSizeOnlyPropId::size> &>(*this);
  }

  /**
   The width of the component.
   */
  auto &width(CGFloat w)
  {
    _size.width = w;
    return reinterpret_cast<Derived<PropsBitmap | ComponentBuilderBaseSizeOnlyPropId::size> &>(*this);
  }

  /**
   The height of the component relative to its parent's size.
   */
  auto &height(CKRelativeDimension h)
  {
    _size.height = h;
    return reinterpret_cast<Derived<PropsBitmap | ComponentBuilderBaseSizeOnlyPropId::size> &>(*this);
  }

  /**
   The height of the component.
   */
  auto &height(CGFloat h)
  {
    _size.height = h;
    return reinterpret_cast<Derived<PropsBitmap | ComponentBuilderBaseSizeOnlyPropId::size> &>(*this);
  }

  /**
   The minumum allowable width of the component relative to its parent's size.
   */
  auto &minWidth(CKRelativeDimension w)
  {
    _size.minWidth = w;
    return reinterpret_cast<Derived<PropsBitmap | ComponentBuilderBaseSizeOnlyPropId::size> &>(*this);
  }

  /**
   The minumum allowable height of the component relative to its parent's size.
   */
  auto &minHeight(CKRelativeDimension h)
  {
    _size.minHeight = h;
    return reinterpret_cast<Derived<PropsBitmap | ComponentBuilderBaseSizeOnlyPropId::size> &>(*this);
  }

  /**
   The maximum allowable width of the component relative to its parent's size.
   */
  auto &maxWidth(CKRelativeDimension w)
  {
    _size.maxWidth = w;
    return reinterpret_cast<Derived<PropsBitmap | ComponentBuilderBaseSizeOnlyPropId::size> &>(*this);
  }

  /**
   The maximum allowable height of the component relative to its parent's size.
   */
  auto &maxHeight(CKRelativeDimension h)
  {
    _size.maxHeight = h;
    return reinterpret_cast<Derived<PropsBitmap | ComponentBuilderBaseSizeOnlyPropId::size> &>(*this);
  }

  /**
   Specifies a size constraint that should apply to this component.
   */
  auto &size(CKComponentSize &&s)
  {
    _size = std::move(s);
    return reinterpret_cast<Derived<PropsBitmap | ComponentBuilderBaseSizeOnlyPropId::size> &>(*this);
  }

  /**
   Specifies a size constraint that should apply to this component.
   */
  auto &size(const CKComponentSize &s)
  {
    _size = s;
    return reinterpret_cast<Derived<PropsBitmap | ComponentBuilderBaseSizeOnlyPropId::size> &>(*this);
  }

protected:
  CKComponentSize _size;
};

namespace ComponentBuilderBasePropId {
  constexpr static auto size = ViewConfigBuilderPropId::__max << 1;
  constexpr static auto __max = size;
}

template <template <PropsBitmapType> class Derived, PropsBitmapType PropsBitmap>
class __attribute__((__may_alias__)) ComponentBuilderBase : public ViewConfigBuilderBase<Derived, PropsBitmap>, public BuilderBase<Derived, PropsBitmap> {
 protected:
  ComponentBuilderBase() = default;

  ComponentBuilderBase(CK::ComponentSpecContext context)
    : BuilderBase<Derived, PropsBitmap>{context} { }

  ComponentBuilderBase(const ComponentBuilderBase &) = default;
  auto operator=(const ComponentBuilderBase &) -> ComponentBuilderBase& = default;

public:

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
    return reinterpret_cast<Derived<PropsBitmap | ViewConfigBuilderPropId::viewConfig> &>(*this);
  }

  /**
   The width of the component relative to its parent's size.
   */
  auto &width(CKRelativeDimension w)
  {
    _size.width = w;
    return reinterpret_cast<Derived<PropsBitmap | ComponentBuilderBasePropId::size> &>(*this);
  }

  /**
   The width of the component.
   */
  auto &width(CGFloat w)
  {
    _size.width = w;
    return reinterpret_cast<Derived<PropsBitmap | ComponentBuilderBasePropId::size> &>(*this);
  }

  /**
   The height of the component relative to its parent's size.
   */
  auto &height(CKRelativeDimension h)
  {
    _size.height = h;
    return reinterpret_cast<Derived<PropsBitmap | ComponentBuilderBasePropId::size> &>(*this);
  }

  /**
   The height of the component.
   */
  auto &height(CGFloat h)
  {
    _size.height = h;
    return reinterpret_cast<Derived<PropsBitmap | ComponentBuilderBasePropId::size> &>(*this);
  }

  /**
   The minumum allowable width of the component relative to its parent's size.
   */
  auto &minWidth(CKRelativeDimension w)
  {
    _size.minWidth = w;
    return reinterpret_cast<Derived<PropsBitmap | ComponentBuilderBasePropId::size> &>(*this);
  }

  /**
   The minumum allowable height of the component relative to its parent's size.
   */
  auto &minHeight(CKRelativeDimension h)
  {
    _size.minHeight = h;
    return reinterpret_cast<Derived<PropsBitmap | ComponentBuilderBasePropId::size> &>(*this);
  }

  /**
   The maximum allowable width of the component relative to its parent's size.
   */
  auto &maxWidth(CKRelativeDimension w)
  {
    _size.maxWidth = w;
    return reinterpret_cast<Derived<PropsBitmap | ComponentBuilderBasePropId::size> &>(*this);
  }

  /**
   The maximum allowable height of the component relative to its parent's size.
   */
  auto &maxHeight(CKRelativeDimension h)
  {
    _size.maxHeight = h;
    return reinterpret_cast<Derived<PropsBitmap | ComponentBuilderBasePropId::size> &>(*this);
  }

  /**
   Specifies a size constraint that should apply to this component.
   */
  auto &size(CKComponentSize &&s)
  {
    _size = std::move(s);
    return reinterpret_cast<Derived<PropsBitmap | ComponentBuilderBasePropId::size> &>(*this);
  }

  /**
   Specifies a size constraint that should apply to this component.
   */
  auto &size(const CKComponentSize &s)
  {
    _size = s;
    return reinterpret_cast<Derived<PropsBitmap | ComponentBuilderBasePropId::size> &>(*this);
  }

protected:
  CKComponentViewConfiguration _viewConfig;
  CKComponentSize _size;
};

template <PropsBitmapType = 0>
class ComponentBuilder;

}

using ComponentBuilderEmpty = BuilderDetails::ComponentBuilder<>;
using ComponentBuilderContext = BuilderDetails::ComponentBuilder<BuilderDetails::BuilderBasePropId::context>;

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
auto ComponentBuilder() -> ComponentBuilderEmpty;

/**
 Provides a fluent API for creating instances of @c CKComponent base class.

 @param c The spec context to use.

 @note This factory overload is to be used when a key is required to reference the built component in a spec from the
 `CK_ANIMATION` function.

 @example A component that renders a red square:
 @code
 CK::ComponentBuilder(context)
 .key(@"my_child")
 .viewClass([UIView class])
 .backgroundColor(UIColor.redColor)
 .width(100)
 .height(100)
 .build()
 */
auto ComponentBuilder(CK::ComponentSpecContext c) -> ComponentBuilderContext;

using ViewConfig = BuilderDetails::ViewConfigBuilder<>;

namespace BuilderDetails {

template <PropsBitmapType PropsBitmap>
class __attribute__((__may_alias__)) ComponentBuilder : public ComponentBuilderBase<ComponentBuilder, PropsBitmap> {
 public:
  ~ComponentBuilder() = default;

private:
  ComponentBuilder() = default;
  ComponentBuilder(CK::ComponentSpecContext context)
    : ComponentBuilderBase<ComponentBuilder, PropsBitmap>{context} { }

  friend auto CK::ComponentBuilder() -> ComponentBuilderEmpty;
  friend auto CK::ComponentBuilder(CK::ComponentSpecContext) -> ComponentBuilderContext;

  template <template <PropsBitmapType> class, PropsBitmapType>
  friend class BuilderBase;

  /**
   Creates a new component instance with specified properties.

   @note  This method must @b not be called more than once on a given component builder instance.
   */
  NS_RETURNS_RETAINED auto _build() noexcept -> CKComponent *
  {
    if (PropBitmap::isSet(PropsBitmap, ViewConfigBuilderPropId::viewConfig, ComponentBuilderBasePropId::size)) {
      return [CKComponent newWithView:this->_viewConfig size:this->_size];
    } else if (PropBitmap::isSet(PropsBitmap, ViewConfigBuilderPropId::viewClass, ComponentBuilderBasePropId::size)) {
      return [CKComponent newWithView:{std::move(this->_viewClass),
                                       std::move(this->_attributes),
                                       std::move(this->_accessibilityCtx),
                                       this->_blockImplicitAnimations}
                                 size:this->_size];
    } else if (PropBitmap::isSet(PropsBitmap, ViewConfigBuilderPropId::viewConfig)) {
      return [CKComponent newWithView:this->_viewConfig size:{}];
    } else if (PropBitmap::isSet(PropsBitmap, ViewConfigBuilderPropId::viewClass)) {
      return [CKComponent newWithView:{std::move(this->_viewClass),
                                       std::move(this->_attributes),
                                       std::move(this->_accessibilityCtx),
                                       this->_blockImplicitAnimations}
                                 size:{}];
    } else if (PropBitmap::isSet(PropsBitmap, ComponentBuilderBasePropId::size)) {
      return [CKComponent newWithView:{} size:this->_size];
    } else {
      return [CKComponent newWithView:{} size:{}];
    }
  }
};
}
}

#endif
