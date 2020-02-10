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
#import <ComponentKit/CKFlexboxComponent.h>

namespace CK {

namespace BuilderDetails {

namespace FlexboxComponentPropId {
constexpr static auto hasActiveChild = ComponentBuilderBasePropId::__max << 1;
constexpr static auto __max = hasActiveChild;
}

template <PropsBitmapType PropsBitmap = 0>
class __attribute__((__may_alias__)) FlexboxComponentBuilder
    : public ComponentBuilderBase<FlexboxComponentBuilder, PropsBitmap> {
 public:
  FlexboxComponentBuilder() = default;

  ~FlexboxComponentBuilder() = default;

  /** Specifies the direction children are stacked in. */
  auto &direction(CKFlexboxDirection d)
  {
    _style.direction = d;
    return *this;
  }

  /** The amount of space between each child. Overriden by any margins on the child in the flex direction */
  auto &spacing(CGFloat s)
  {
    _style.spacing = s;
    return *this;
  }

  /** Margin applied to the child */
  auto &margin(const CKFlexboxSpacing &m)
  {
    constexpr auto isSettingPropertiesForChild = PropBitmap::isSet(PropsBitmap, FlexboxComponentPropId::hasActiveChild);
    static_assert(isSettingPropertiesForChild,
                  "Cannot set child property 'margin' before specifying a child component using .child()");
    _currentChild.margin = m;
    return *this;
  }

  /** Top margin applied to the child */
  auto &marginTop(CGFloat m)
  {
    constexpr auto isSettingPropertiesForChild = PropBitmap::isSet(PropsBitmap, FlexboxComponentPropId::hasActiveChild);
    static_assert(isSettingPropertiesForChild,
                  "Cannot set child property 'marginTop' before specifying a child component using .child()");
    _currentChild.margin.top = m;
    return *this;
  }

  /** Bottom margin applied to the child */
  auto &marginBottom(CGFloat m)
  {
    constexpr auto isSettingPropertiesForChild = PropBitmap::isSet(PropsBitmap, FlexboxComponentPropId::hasActiveChild);
    static_assert(isSettingPropertiesForChild,
                  "Cannot set child property 'marginBottom' before specifying a child component using .child()");
    _currentChild.margin.bottom = m;
    return *this;
  }

  /** Start margin applied to the child. Left in left-to-right languages, right in right-to-left languages */
  auto &marginStart(CGFloat m)
  {
    constexpr auto isSettingPropertiesForChild = PropBitmap::isSet(PropsBitmap, FlexboxComponentPropId::hasActiveChild);
    static_assert(isSettingPropertiesForChild,
    "Cannot set child property 'marginStart' before specifying a child component using .child()");
    _currentChild.margin.start = m;
    return *this;
  }

  /** Start margin applied to the child. Left in left-to-right languages, right in right-to-left languages */
  auto &marginStart(CKRelativeDimension m)
  {
    constexpr auto isSettingPropertiesForChild = PropBitmap::isSet(PropsBitmap, FlexboxComponentPropId::hasActiveChild);
    static_assert(isSettingPropertiesForChild,
                  "Cannot set child property 'marginStart' before specifying a child component using .child()");
    _currentChild.margin.start = m;
    return *this;
  }

  /** End margin applied to the child. Right in left-to-right languages, left in right-to-left languages */
  auto &marginEnd(CGFloat m)
  {
    constexpr auto isSettingPropertiesForChild = PropBitmap::isSet(PropsBitmap, FlexboxComponentPropId::hasActiveChild);
    static_assert(isSettingPropertiesForChild,
                  "Cannot set child property 'marginEnd' before specifying a child component using .child()");
    _currentChild.margin.end = m;
    return *this;
  }

  /** End margin applied to the child. Right in left-to-right languages, left in right-to-left languages */
  auto &marginEnd(CKRelativeDimension m)
  {
    constexpr auto isSettingPropertiesForChild = PropBitmap::isSet(PropsBitmap, FlexboxComponentPropId::hasActiveChild);
    static_assert(isSettingPropertiesForChild,
                  "Cannot set child property 'marginEnd' before specifying a child component using .child()");
    _currentChild.margin.end = m;
    return *this;
  }

  /** How children are aligned if there are no flexible children. */
  auto &justifyContent(CKFlexboxJustifyContent j)
  {
    _style.justifyContent = j;
    return *this;
  }

  /** Orientation of children along cross axis */
  auto &alignItems(CKFlexboxAlignItems a)
  {
    _style.alignItems = a;
    return *this;
  }

  /** Alignment of container's lines in multi-line flex containers. Has no effect on single line containers. */
  auto &alignContent(CKFlexboxAlignContent a)
  {
    _style.alignContent = a;
    return *this;
  }

  /** Wrapping style of children in case there isn't enough space */
  auto &wrap(CKFlexboxWrap w)
  {
    _style.wrap = w;
    return *this;
  }

  /** Padding applied to the container */
  auto &padding(const CKFlexboxSpacing &p)
  {
    if (PropBitmap::isSet(PropsBitmap, FlexboxComponentPropId::hasActiveChild)) {
      _currentChild.padding = p;
    } else {
      _style.padding = p;
    }
    return *this;
  }

  /** Top padding applied to the container */
  auto &paddingTop(CGFloat p)
  {
    if (PropBitmap::isSet(PropsBitmap, FlexboxComponentPropId::hasActiveChild)) {
      _currentChild.padding.top = p;
    } else {
      _style.padding.top = p;
    }
    return *this;
  }

  /** Top padding applied to the container */
  auto &paddingTop(CKRelativeDimension p)
  {
    if (PropBitmap::isSet(PropsBitmap, FlexboxComponentPropId::hasActiveChild)) {
      _currentChild.padding.top = p;
    } else {
      _style.padding.top = p;
    }
    return *this;
  }

  /** Bottom padding applied to the container */
  auto &paddingBottom(CGFloat p)
  {
    if (PropBitmap::isSet(PropsBitmap, FlexboxComponentPropId::hasActiveChild)) {
      _currentChild.padding.bottom = p;
    } else {
      _style.padding.bottom = p;
    }
    return *this;
  }

  /** Bottom padding applied to the container */
  auto &paddingBottom(CKRelativeDimension p)
  {
    if (PropBitmap::isSet(PropsBitmap, FlexboxComponentPropId::hasActiveChild)) {
      _currentChild.padding.bottom = p;
    } else {
      _style.padding.bottom = p;
    }
    return *this;
  }

  /** Start padding applied to the container. Left in left-to-right languages, right in right-to-left languages */
  auto &paddingStart(CGFloat p)
  {
    if (PropBitmap::isSet(PropsBitmap, FlexboxComponentPropId::hasActiveChild)) {
      _currentChild.padding.start = p;
    } else {
      _style.padding.start = p;
    }
    return *this;
  }

  /** Start padding applied to the container. Left in left-to-right languages, right in right-to-left languages */
  auto &paddingStart(CKRelativeDimension p)
  {
    if (PropBitmap::isSet(PropsBitmap, FlexboxComponentPropId::hasActiveChild)) {
      _currentChild.padding.start = p;
    } else {
      _style.padding.start = p;
    }
    return *this;
  }

  /** End padding applied to the container. Right in left-to-right languages, left in right-to-left languages */
  auto &paddingEnd(CGFloat p)
  {
    if (PropBitmap::isSet(PropsBitmap, FlexboxComponentPropId::hasActiveChild)) {
      _currentChild.padding.end = p;
    } else {
      _style.padding.end = p;
    }
    return *this;
  }

  /** End padding applied to the container. Right in left-to-right languages, left in right-to-left languages */
  auto &paddingEnd(CKRelativeDimension p)
  {
    if (PropBitmap::isSet(PropsBitmap, FlexboxComponentPropId::hasActiveChild)) {
      _currentChild.padding.end = p;
    } else {
      _style.padding.end = p;
    }
    return *this;
  }

  /**
   Border applied to the container. This only reserves space for the border - you are responsible for drawing the
   border. Border behaves nearly identically to padding and is only separate from padding to make it easier to implement
   border effects such as color.
  */
  auto &border(const CKFlexboxBorder &b)
  {
    _style.border = b;
    return *this;
  }

  /**
   Top border applied to the container. This only reserves space for the border - you are responsible for drawing the
   border. Border behaves nearly identically to padding and is only separate from padding to make it easier to implement
   border effects such as color.
   */
  auto &borderTop(CGFloat b)
  {
    _style.border.top = b;
    return *this;
  }

  /**
   Bottom border applied to the container. This only reserves space for the border - you are responsible for drawing the
   border. Border behaves nearly identically to padding and is only separate from padding to make it easier to implement
   border effects such as color.
   */
  auto &borderBottom(CGFloat b)
  {
    _style.border.bottom = b;
    return *this;
  }

  /**
   Start border applied to the container. Left in left-to-right languages, right in right-to-left languages.s This only
   reserves space for the border - you are responsible for drawing the border. Border behaves nearly identically to
   padding and is only separate from padding to make it easier to implement border effects such as color.
   */
  auto &borderStart(CGFloat b)
  {
    _style.border.start = b;
    return *this;
  }

  /**
   End border applied to the container. Right in left-to-right languages, left in right-to-left languages. This only
   reserves space for the border - you are responsible for drawing the border. Border behaves nearly identically to
   padding and is only separate from padding to make it easier to implement border effects such as color.
   */
  auto &borderEnd(CGFloat b)
  {
    _style.border.end = b;
    return *this;
  }

  /**
   Use to support RTL layouts.
   The default is to follow the application's layout direction, but you can force a LTR or RTL layout by changing this.
   */
  auto &layoutDirection(CKLayoutDirection d)
  {
    _style.layoutDirection = d;
    return *this;
  }

  /**
  If set to @c YES and the child component is back by yoga, will reuse the child's yoga node and avoid allocating new
  one. This will in turn make the yoga trees deeper.

  If set to @c NO, will allocate a yoga node for every single child even it is backed by yoga as well
  */
  auto &useDeepYogaTrees(bool d)
  {
    _style.useDeepYogaTrees = d;
    return *this;
  }
      
  /**
  If set to @c YES, flexbox will use the composite component child size to assign size
  properties on yoga node instead of the size of composite component itself.
  
  This is a temporary flag used for migration purposes.
  */
  auto &skipCompositeComponentSize(bool d)
  {
    _style.skipCompositeComponentSize = d;
    return *this;
  }

  /**
   Adds a child component with default layout options to this flexbox component.

   @param c component to add.
   */
  auto &child(NS_RELEASES_ARGUMENT CKComponent *c)
  {
    if (PropBitmap::isSet(PropsBitmap, FlexboxComponentPropId::hasActiveChild)) {
      _children.push_back(_currentChild);
    }

    _currentChild = {c};
    return reinterpret_cast<FlexboxComponentBuilder<PropsBitmap | FlexboxComponentPropId::hasActiveChild> &>(*this);
  }

  /**
   Adds a child to this flexbox component.

   @param c child to add.
   */
  auto &child(const CKFlexboxComponentChild &c)
  {
    if (PropBitmap::isSet(PropsBitmap, FlexboxComponentPropId::hasActiveChild)) {
      _children.push_back(_currentChild);
    }

    _currentChild = c;
    return reinterpret_cast<FlexboxComponentBuilder<PropsBitmap | FlexboxComponentPropId::hasActiveChild> &>(*this);
  }

  /** Orientation of the child along cross axis, overriding @c alignItems */
  auto &alignSelf(CKFlexboxAlignSelf a)
  {
    constexpr auto isSettingPropertiesForChild = PropBitmap::isSet(PropsBitmap, FlexboxComponentPropId::hasActiveChild);
    static_assert(isSettingPropertiesForChild,
                  "Cannot set child property 'alignSelf' before specifying a child component using .child()");
    _currentChild.alignSelf = a;
    return *this;
  }

  /**
  If the sum of childrens' stack dimensions is less than the minimum size, how much should this component grow?
  This value represents the "flex grow factor" and determines how much this component should grow in relation to any
  other flexible children.
  */
  auto &flexGrow(CGFloat fg)
  {
    constexpr auto isSettingPropertiesForChild = PropBitmap::isSet(PropsBitmap, FlexboxComponentPropId::hasActiveChild);
    static_assert(isSettingPropertiesForChild,
                  "Cannot set child property 'flexGrow' before specifying a child component using .child()");
    _currentChild.flexGrow = fg;
    return *this;
  }

  /**
  If the sum of childrens' stack dimensions is greater than the maximum size, how much should this component shrink?
  This value represents the "flex shrink factor" and determines how much this component should shink in relation to
  other flexible children.
  */
  auto &flexShrink(CGFloat fs)
  {
    constexpr auto isSettingPropertiesForChild = PropBitmap::isSet(PropsBitmap, FlexboxComponentPropId::hasActiveChild);
    static_assert(isSettingPropertiesForChild,
                  "Cannot set child property 'flexShrink' before specifying a child component using .child()");
    _currentChild.flexShrink = fs;
    return *this;
  }

  /**
  Additional space to place before the component in the stacking direction. Overriden by any margins in the stacking
  direction.
  */
  auto &spacingBefore(CGFloat s)
  {
    constexpr auto isSettingPropertiesForChild = PropBitmap::isSet(PropsBitmap, FlexboxComponentPropId::hasActiveChild);
    static_assert(isSettingPropertiesForChild,
                  "Cannot set child property 'spacingBefore' before specifying a child component using .child()");
    _currentChild.spacingBefore = s;
    return *this;
  }

  /**
  Additional space to place after the component in the stacking direction. Overriden by any margins in the stacking
  direction.
  */
  auto &spacingAfter(CGFloat s)
  {
    constexpr auto isSettingPropertiesForChild = PropBitmap::isSet(PropsBitmap, FlexboxComponentPropId::hasActiveChild);
    static_assert(isSettingPropertiesForChild,
                  "Cannot set child property 'spacingAfter' before specifying a child component using .child()");
    _currentChild.spacingAfter = s;
    return *this;
  }

  /** Specifies the initial size in the stack dimension for the child. */
  auto &flexBasis(CKRelativeDimension fb)
  {
    constexpr auto isSettingPropertiesForChild = PropBitmap::isSet(PropsBitmap, FlexboxComponentPropId::hasActiveChild);
    static_assert(isSettingPropertiesForChild,
                  "Cannot set child property 'flexBasis' before specifying a child component using .child()");
    _currentChild.flexBasis = fb;
    return *this;
  }

  /** Position for the child */
  auto &position(CKFlexboxPosition p)
  {
    constexpr auto isSettingPropertiesForChild = PropBitmap::isSet(PropsBitmap, FlexboxComponentPropId::hasActiveChild);
    static_assert(isSettingPropertiesForChild,
                  "Cannot set child property 'position' before specifying a child component using .child()");
    _currentChild.position = p;
    return *this;
  }

  /** Type of the child position */
  auto &positionType(CKFlexboxPositionType t)
  {
    constexpr auto isSettingPropertiesForChild = PropBitmap::isSet(PropsBitmap, FlexboxComponentPropId::hasActiveChild);
    static_assert(isSettingPropertiesForChild,
                  "Cannot set child property 'positionType' before specifying a child component using .child()");
    _currentChild.position.type = t;
    return *this;
  }

  /** Defines offset from left edge of parent to left edge of child */
  auto &positionLeft(CGFloat p)
  {
    constexpr auto isSettingPropertiesForChild = PropBitmap::isSet(PropsBitmap, FlexboxComponentPropId::hasActiveChild);
    static_assert(isSettingPropertiesForChild,
                  "Cannot set child property 'positionLeft' before specifying a child component using .child()");
    _currentChild.position.left = p;
    return *this;
  }

  /** Defines offset from left edge of parent to left edge of child */
  auto &positionLeft(CKRelativeDimension p)
  {
    constexpr auto isSettingPropertiesForChild = PropBitmap::isSet(PropsBitmap, FlexboxComponentPropId::hasActiveChild);
    static_assert(isSettingPropertiesForChild,
                  "Cannot set child property 'positionLeft' before specifying a child component using .child()");
    _currentChild.position.left = p;
    return *this;
  }

  /** Defines offset from end edge of parent to end edge of child */
  auto &positionEnd(CGFloat p)
  {
    constexpr auto isSettingPropertiesForChild = PropBitmap::isSet(PropsBitmap, FlexboxComponentPropId::hasActiveChild);
    static_assert(isSettingPropertiesForChild,
                  "Cannot set child property 'positionEnd' before specifying a child component using .child()");
    _currentChild.position.end = p;
    return *this;
  }

  /** Defines offset from end edge of parent to end edge of child */
  auto &positionEnd(CKRelativeDimension p)
  {
    constexpr auto isSettingPropertiesForChild = PropBitmap::isSet(PropsBitmap, FlexboxComponentPropId::hasActiveChild);
    static_assert(isSettingPropertiesForChild,
                  "Cannot set child property 'positionEnd' before specifying a child component using .child()");
    _currentChild.position.end = p;
    return *this;
  }

  /** Defines offset from starting edge of parent to starting edge of child */
  auto &positionStart(CGFloat p)
  {
    constexpr auto isSettingPropertiesForChild = PropBitmap::isSet(PropsBitmap, FlexboxComponentPropId::hasActiveChild);
    static_assert(isSettingPropertiesForChild,
                  "Cannot set child property 'positionStart' before specifying a child component using .child()");
    _currentChild.position.start = p;
    return *this;
  }

  /** Defines offset from starting edge of parent to starting edge of child */
  auto &positionStart(CKRelativeDimension p)
  {
    constexpr auto isSettingPropertiesForChild = PropBitmap::isSet(PropsBitmap, FlexboxComponentPropId::hasActiveChild);
    static_assert(isSettingPropertiesForChild,
                  "Cannot set child property 'positionStart' before specifying a child component using .child()");
    _currentChild.position.start = p;
    return *this;
  }

  /** Defines offset from top edge of parent to top edge of child */
  auto &positionTop(CGFloat p)
  {
    constexpr auto isSettingPropertiesForChild = PropBitmap::isSet(PropsBitmap, FlexboxComponentPropId::hasActiveChild);
    static_assert(isSettingPropertiesForChild,
                  "Cannot set child property 'positionTop' before specifying a child component using .child()");
    _currentChild.position.top = p;
    return *this;
  }

  /** Defines offset from top edge of parent to top edge of child */
  auto &positionTop(CKRelativeDimension p)
  {
    constexpr auto isSettingPropertiesForChild = PropBitmap::isSet(PropsBitmap, FlexboxComponentPropId::hasActiveChild);
    static_assert(isSettingPropertiesForChild,
                  "Cannot set child property 'positionTop' before specifying a child component using .child()");
    _currentChild.position.top = p;
    return *this;
  }

  /** Defines offset from bottom edge of parent to bottom edge of child */
  auto &positionBottom(CGFloat p)
  {
    constexpr auto isSettingPropertiesForChild = PropBitmap::isSet(PropsBitmap, FlexboxComponentPropId::hasActiveChild);
    static_assert(isSettingPropertiesForChild,
                  "Cannot set child property 'positionBottom' before specifying a child component using .child()");
    _currentChild.position.bottom = p;
    return *this;
  }

  /** Defines offset from bottom edge of parent to bottom edge of child */
  auto &positionBottom(CKRelativeDimension p)
  {
    constexpr auto isSettingPropertiesForChild = PropBitmap::isSet(PropsBitmap, FlexboxComponentPropId::hasActiveChild);
    static_assert(isSettingPropertiesForChild,
                  "Cannot set child property 'positionBottom' before specifying a child component using .child()");
    _currentChild.position.bottom = p;
    return *this;
  }

  /** Defines offset from right edge of parent to right edge of child */
  auto &positionRight(CGFloat p)
  {
    constexpr auto isSettingPropertiesForChild = PropBitmap::isSet(PropsBitmap, FlexboxComponentPropId::hasActiveChild);
    static_assert(isSettingPropertiesForChild,
                  "Cannot set child property 'positionRight' before specifying a child component using .child()");
    _currentChild.position.right = p;
    return *this;
  }

  /** Defines offset from right edge of parent to right edge of child */
  auto &positionRight(CKRelativeDimension p)
  {
    constexpr auto isSettingPropertiesForChild = PropBitmap::isSet(PropsBitmap, FlexboxComponentPropId::hasActiveChild);
    static_assert(isSettingPropertiesForChild,
                  "Cannot set child property 'positionRight' before specifying a child component using .child()");
    _currentChild.position.right = p;
    return *this;
  }

  /**
  Stack order of the child.
  Child with greater stack order will be in front of an child with a lower stack order.
  If children have the same @c zIndex, the one declared first will appear below.
  */
  auto &zIndex(NSInteger i)
  {
    constexpr auto isSettingPropertiesForChild = PropBitmap::isSet(PropsBitmap, FlexboxComponentPropId::hasActiveChild);
    static_assert(isSettingPropertiesForChild,
                  "Cannot set child property 'zIndex' before specifying a child component using .child()");
    _currentChild.zIndex = i;
    return *this;
  }

  /**
  Aspect ratio controls the size of the undefined dimension of a node.
  Aspect ratio is encoded as a floating point value width/height. e.g. A value of 2 leads to a node
  with a width twice the size of its height while a value of 0.5 gives the opposite effect.
  */
  auto &aspectRatio(CKFlexboxAspectRatio r)
  {
    constexpr auto isSettingPropertiesForChild = PropBitmap::isSet(PropsBitmap, FlexboxComponentPropId::hasActiveChild);
    static_assert(isSettingPropertiesForChild,
                  "Cannot set child property 'aspectRatio' before specifying a child component using .child()");
    _currentChild.aspectRatio = r;
    return *this;
  }

  /**
  Size constraints on the child. Percentages are resolved against parent size.
  If constraint is Auto, will resolve against size of children Component
  By default all values are Auto
  */
  auto &sizeConstraints(const CKComponentSize &s)
  {
    constexpr auto isSettingPropertiesForChild = PropBitmap::isSet(PropsBitmap, FlexboxComponentPropId::hasActiveChild);
    static_assert(isSettingPropertiesForChild,
                  "Cannot set child property 'sizeConstraints' before specifying a child component using .child()");
    _currentChild.sizeConstraints = s;
    return *this;
  }

  /**
  This property allows node to force rounding only up.
  Text should never be rounded down as this may cause it to be truncated.
  */
  auto &useTextRounding(bool r)
  {
    constexpr auto isSettingPropertiesForChild = PropBitmap::isSet(PropsBitmap, FlexboxComponentPropId::hasActiveChild);
    static_assert(isSettingPropertiesForChild,
                  "Cannot set child property 'useTextRounding' before specifying a child component using .child()");
    _currentChild.useTextRounding = r;
    return *this;
  }

  /**
  This property allows to override how the baseline of a component is calculated. The default baseline of component is
  the baseline of first child in Yoga. If this property is set to @c YES then height of a component will be used as
  baseline.
  */
  auto &useHeightAsBaseline(bool b)
  {
    constexpr auto isSettingPropertiesForChild = PropBitmap::isSet(PropsBitmap, FlexboxComponentPropId::hasActiveChild);
    static_assert(isSettingPropertiesForChild,
                  "Cannot set child property 'useHeightAsBaseline' before specifying a child component using .child()");
    _currentChild.useHeightAsBaseline = b;
    return *this;
  }

  /**
  Adds a complete collection of children to this flexbox component.

  @param c component to add.
  */
  template <typename Collection> auto &children(Collection &&c)
  {
    if (PropBitmap::isSet(PropsBitmap, FlexboxComponentPropId::hasActiveChild)) {
      _children.push_back(_currentChild);
    }

    auto newChildren = std::vector<CKFlexboxComponentChild>{std::forward<Collection>(c)};
    _children.insert(
      _children.end(), std::make_move_iterator(newChildren.begin()), std::make_move_iterator(newChildren.end()));
    return reinterpret_cast<
      FlexboxComponentBuilder<PropBitmap::clear(PropsBitmap, FlexboxComponentPropId::hasActiveChild)> &>(*this);
  }

  /**
  Adds a complete collection of children to this flexbox component.

  @param c component to add.
  */
  auto &children(CKContainerWrapper<std::vector<CKFlexboxComponentChild>> &&c)
  {
    if (PropBitmap::isSet(PropsBitmap, FlexboxComponentPropId::hasActiveChild)) {
      _children.push_back(_currentChild);
    }

    auto newChildren = c.take();
    _children.insert(
      _children.end(), std::make_move_iterator(newChildren.begin()), std::make_move_iterator(newChildren.end()));
    return reinterpret_cast<
      FlexboxComponentBuilder<PropBitmap::clear(PropsBitmap, FlexboxComponentPropId::hasActiveChild)> &>(*this);
  }

  /**
  Creates a new component instance with specified properties.

  @note  This method must @b not be called more than once on a given component builder instance.
  */
  NS_RETURNS_RETAINED auto build() noexcept -> CKFlexboxComponent *
  {
    if (PropBitmap::isSet(PropsBitmap, FlexboxComponentPropId::hasActiveChild)) {
      _children.push_back(_currentChild);
    }

    if (PropBitmap::isSet(PropsBitmap, ViewConfigBuilderPropId::viewConfig, ComponentBuilderBasePropId::size)) {
      return [CKFlexboxComponent newWithView:this->_viewConfig
                                        size:this->_size
                                       style:this->_style
                                    children:std::move(this->_children)];
    } else if (PropBitmap::isSet(PropsBitmap, ViewConfigBuilderPropId::viewClass, ComponentBuilderBasePropId::size)) {
      return [CKFlexboxComponent newWithView:{std::move(this->_viewClass),
                                              std::move(this->_attributes),
                                              std::move(this->_accessibilityCtx),
                                              this->_blockImplicitAnimations}
                                        size:this->_size
                                       style:this->_style
                                    children:std::move(this->_children)];
    } else if (PropBitmap::isSet(PropsBitmap, ViewConfigBuilderPropId::viewConfig)) {
      return [CKFlexboxComponent newWithView:this->_viewConfig
                                        size:{}
                                       style:this->_style
                                    children:std::move(this->_children)];
    } else if (PropBitmap::isSet(PropsBitmap, ViewConfigBuilderPropId::viewClass)) {
      return [CKFlexboxComponent newWithView:{std::move(this->_viewClass),
                                              std::move(this->_attributes),
                                              std::move(this->_accessibilityCtx),
                                              this->_blockImplicitAnimations}
                                        size:{}
                                       style:this->_style
                                    children:std::move(this->_children)];
    } else if (PropBitmap::isSet(PropsBitmap, ComponentBuilderBasePropId::size)) {
      return [CKFlexboxComponent newWithView:{}
                                        size:this->_size
                                       style:this->_style
                                    children:std::move(this->_children)];
    } else {
      return [CKFlexboxComponent newWithView:{} size:{} style:this->_style children:std::move(this->_children)];
    }
  }

 private:
  CKFlexboxComponentStyle _style;
  CKFlexboxComponentChild _currentChild;
  std::vector<CKFlexboxComponentChild> _children;
};

}

using FlexboxComponentBuilder = BuilderDetails::FlexboxComponentBuilder<>;
}

#endif
