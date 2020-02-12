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

#import <vector>

#import <ComponentKit/CKContainerWrapper.h>
#import <ComponentKit/CKLayoutComponent.h>
#import <ComponentKit/CKMacros.h>
#import <ComponentKit/CKOptional.h>

typedef NS_ENUM(NSInteger, CKFlexboxDirection) {
  CKFlexboxDirectionColumn,
  CKFlexboxDirectionRow,
  CKFlexboxDirectionColumnReverse,
  CKFlexboxDirectionRowReverse,
};

/** Layout direction is used to support RTL */
typedef NS_ENUM(NSInteger, CKLayoutDirection) {
  CKLayoutDirectionApplicationDirection,
  CKLayoutDirectionLTR,
  CKLayoutDirectionRTL,
};

/** If no children are flexible, how should this component justify its children in the available space? */
typedef NS_ENUM(NSInteger, CKFlexboxJustifyContent) {
  /**
   On overflow, children overflow out of this component's bounds on the right/bottom side.
   On underflow, children are left/top-aligned within this component's bounds.
   */
  CKFlexboxJustifyContentStart,
  /**
   On overflow, children are centered and overflow on both sides.
   On underflow, children are centered within this component's bounds in the stacking direction.
   */
  CKFlexboxJustifyContentCenter,
  /**
   On overflow, children overflow out of this component's bounds on the left/top side.
   On underflow, children are right/bottom-aligned within this component's bounds.
   */
  CKFlexboxJustifyContentEnd,
  /**
   Items are positioned with space between the lines.
   */
  CKFlexboxJustifyContentSpaceBetween,
  /**
   Items are positioned with space before, between, and after the lines.
   The space before and after the lines are half the size of the space between the lines.
   */
  CKFlexboxJustifyContentSpaceAround,
  /**
   Items are positioned with space before, between, and after the lines.
   The space before, between, and after the lines are all of equal size.
   */
  CKFlexboxJustifyContentSpaceEvenly,
};

typedef NS_ENUM(NSInteger, CKFlexboxAlignItems) {
  /** Expand children to fill cross axis */
  CKFlexboxAlignItemsStretch,
  /** Align children to start of cross axis */
  CKFlexboxAlignItemsStart,
  /** Align children with end of cross axis */
  CKFlexboxAlignItemsEnd,
  /** Center children on cross axis */
  CKFlexboxAlignItemsCenter,
  /** Align children such that their baselines align */
  CKFlexboxAlignItemsBaseline,
};

typedef NS_ENUM(NSInteger, CKFlexboxAlignContent) {
  /** Align lines to start of container */
  CKFlexboxAlignContentStart,
  /** Align lines to end of container */
  CKFlexboxAlignContentEnd,
  /** Align lines to center of container */
  CKFlexboxAlignContentCenter,
  /** Evenly distribute lines; first line is at start and last line at end of container */
  CKFlexboxAlignContentSpaceBetween,
  /** Evenly distribute lines with equal space between */
  CKFlexboxAlignContentSpaceAround,
  /** Expand lines to fill container */
  CKFlexboxAlignContentStretch,
};

/**
 Each child may override their parent stack's cross axis alignment.
 @see CKFlexboxAlignItems
 */
typedef NS_ENUM(NSInteger, CKFlexboxAlignSelf) {
  /** Inherit alignment value from containing stack. */
  CKFlexboxAlignSelfAuto,
  CKFlexboxAlignSelfStart,
  CKFlexboxAlignSelfEnd,
  CKFlexboxAlignSelfCenter,
  CKFlexboxAlignSelfBaseline,
  CKFlexboxAlignSelfStretch,
};

typedef NS_ENUM(NSInteger, CKFlexboxWrap) {
  /** Children are not wrapped */
  CKFlexboxWrapNoWrap,
  /** Children are wrapped if necessary */
  CKFlexboxWrapWrap,
  /** Children are wrapped if necessary in reverse order of lines */
  CKFlexboxWrapWrapReverse,
};

typedef NS_ENUM(NSInteger, CKFlexboxPositionType) {
  /** Specifies the type of position children are stacked in */
  CKFlexboxPositionTypeRelative,
  /** With the absolute position, child is positioned relative to parent */
  CKFlexboxPositionTypeAbsolute,
};

struct CKFlexboxPosition {
  CKFlexboxPositionType type;
  /** Defines offset from starting edge of parent to starting edge of child */
  CKRelativeDimension start;
  /** Defines offset from top edge of parent to top edge of child */
  CKRelativeDimension top;
  /** Defines offset from end edge of parent to end edge of child */
  CKRelativeDimension end;
  /** Defines offset from bottom edge of parent to bottom edge of child */
  CKRelativeDimension bottom;
  /** Defines offset from left edge of parent to left edge of child */
  CKRelativeDimension left;
  /** Defines offset from right edge of parent to right edge of child */
  CKRelativeDimension right;
};

/** Allows us to differentiate between an explicitly set border and an undefined border */
class CKFlexboxBorderDimension {
public:
  constexpr CKFlexboxBorderDimension() noexcept : _value(), _isDefined(false) {}

  /** Convenience initializer */
  CKFlexboxBorderDimension(CGFloat value) noexcept : CKFlexboxBorderDimension(value, true) {}

  CGFloat value() const noexcept {
    return _value;
  }

  bool isDefined() const noexcept {
    return _isDefined;
  }

private:
  CKFlexboxBorderDimension(CGFloat value, bool isDefined)
  : _value(value), _isDefined(isDefined) {}
  CGFloat _value;
  // Make sizeof(_isDefined) == sizeof(_value) to get smaller code via SLP vectorization.
  NSUInteger _isDefined;
};

struct CKFlexboxBorder {
  CKFlexboxBorderDimension top;
  CKFlexboxBorderDimension bottom;
  CKFlexboxBorderDimension start;
  CKFlexboxBorderDimension end;
};

/** Allows us to differentiate between an explicitly set auto-dimension and an undefined dimension */
class CKFlexboxDimension {
public:
  constexpr CKFlexboxDimension() noexcept : _relativeDimension(CKRelativeDimension()), _isDefined(false) {}

  /** Convenience initializer for points */
  CKFlexboxDimension(CGFloat points) noexcept : CKFlexboxDimension(CKRelativeDimension(points), true) {}

  /** Convenience initializer for a dimension object */
  CKFlexboxDimension(CKRelativeDimension dimension) noexcept : CKFlexboxDimension(dimension, true) {}

  CKRelativeDimension dimension() const noexcept {
    return _relativeDimension;
  }

  bool isDefined() const noexcept {
    return _isDefined;
  }

private:
  CKFlexboxDimension(CKRelativeDimension dimension, bool isDefined)
  : _relativeDimension(dimension), _isDefined(isDefined) {}
  CKRelativeDimension _relativeDimension;
  // Make sizeof(_isDefined) == sizeof(void *) to get smaller code via SLP vectorization.
  NSUInteger _isDefined;
};

struct CKFlexboxSpacing {
  CKFlexboxDimension top;
  CKFlexboxDimension bottom;
  /** Left in left-to-right languages, right in right-to-left languages */
  CKFlexboxDimension start;
  /** Right in left-to-right languages, left in right-to-left languages */
  CKFlexboxDimension end;
};

class CKFlexboxAspectRatio {
public:
  constexpr CKFlexboxAspectRatio() noexcept : _aspectRatio(), _isDefined(false) {}

  /** Convenience initializer for an aspect ratio */
  CKFlexboxAspectRatio(CGFloat aspectRatio) noexcept : CKFlexboxAspectRatio(aspectRatio, true) {}

  CGFloat aspectRatio() const noexcept {
    return _aspectRatio;
  }

  bool isDefined() const noexcept {
    return _isDefined;
  }

private:
  CKFlexboxAspectRatio(CGFloat aspectRatio, bool isDefined)
  : _aspectRatio(aspectRatio < 0 ? fabs(aspectRatio) : aspectRatio), _isDefined(isDefined) {}
  CGFloat _aspectRatio;
  // Make sizeof(_isDefined) == sizeof(_aspectRatio) to get smaller code via SLP vectorization.
  NSUInteger _isDefined;
};

struct CKFlexboxComponentStyle {
  /** Specifies the direction children are stacked in. */
  CKFlexboxDirection direction;
  /** The amount of space between each child. Overriden by any margins on the child in the flex direction */
  CGFloat spacing;
  /** How children are aligned if there are no flexible children. */
  CKFlexboxJustifyContent justifyContent;
  /** Orientation of children along cross axis */
  CKFlexboxAlignItems alignItems;
  /** Alignment of container's lines in multi-line flex containers. Has no effect on single line containers. */
  CKFlexboxAlignContent alignContent;
  /** Wrapping style of children in case there isn't enough space */
  CKFlexboxWrap wrap;
  /** Padding applied to the container */
  CKFlexboxSpacing padding;
  /**
    Border applied to the container. This only reserves space for the border - you are responsible for drawing the border.
    Border behaves nearly identically to padding and is only separate from padding to make it easier
    to implement border effects such as color.
   */
  CKFlexboxBorder border;
  /**
   Use to support RTL layouts.
   The default is to follow the application's layout direction, but you can force a LTR or RTL layout by changing this.
   */
  CKLayoutDirection layoutDirection = CKLayoutDirectionApplicationDirection;

  /**
   If set to YES and the child component is back by yoga, will reuse the child's yoga node and avoid allocating new one. This will in turn
   make the yoga trees deeper.

   If set to NO, will allocate a yoga node for every single child even it is backed by yoga as well
   */
  BOOL useDeepYogaTrees = NO;
  
  /**
   If set to YES, flexbox will use the composite component child size to assign size
   properties on yoga node instead of the size of composite component itself.
   
   This is a temporary flag used for migration purposes.
   */
  CK::Optional<BOOL> skipCompositeComponentSize;
};

struct CKFlexboxComponentChild {
  CKComponent *component;
  /** Additional space to place before the component in the stacking direction. Overriden by any margins in the stacking direction. */
  CGFloat spacingBefore;
  /** Additional space to place after the component in the stacking direction. Overriden by any margins in the stacking direction. */
  CGFloat spacingAfter;
  /** Margin applied to the child. Setting margin in the stacking direction overrides any spacing set on the container or child.
   Margin is applied outside the child - margin doesn't increase your child size.
   If you want to add space inside the child, use Padding property
   */
  CKFlexboxSpacing margin;
  /** Padding applied to the child.
   IMPORTANT! This padding is applicable only for current Flexbox and will not apply to the child internal layout. You need to apply it there separately if you need.
   Padding is applied inside the child - padding increases your child size.
   If you want to add space outside the child, use Margin property.
   */
  CKFlexboxSpacing padding;
  /**
   If the sum of childrens' stack dimensions is less than the minimum size, how much should this component grow?
   This value represents the "flex grow factor" and determines how much this component should grow in relation to any
   other flexible children.
   */
  CGFloat flexGrow;
  /**
   If the sum of childrens' stack dimensions is greater than the maximum size, how much should this component shrink?
   This value represents the "flex shrink factor" and determines how much this component should shink in relation to
   other flexible children.
   */
  CGFloat flexShrink;
  /** Specifies the initial size in the stack dimension for the child. */
  CKRelativeDimension flexBasis;
  /** Orientation of the child along cross axis, overriding alignItems */
  CKFlexboxAlignSelf alignSelf;
  /** Position for the child */
  CKFlexboxPosition position;
  /** Stack order of the child.
   Child with greater stack order will be in front of an child with a lower stack order.
   If children have the same zIndex, the one declared first will appear below
   */
  NSInteger zIndex;
  /** Aspect ratio controls the size of the undefined dimension of a node.
   Aspect ratio is encoded as a floating point value width/height. e.g. A value of 2 leads to a node
   with a width twice the size of its height while a value of 0.5 gives the opposite effect. **/
  CKFlexboxAspectRatio aspectRatio;
  /**
   Size constraints on the child. Percentages are resolved against parent size.
   If constraint is Auto, will resolve against size of children Component
   By default all values are Auto
   **/
  CKComponentSize sizeConstraints;
  /**
   This property allows node to force rounding only up.
   Text should never be rounded down as this may cause it to be truncated.
   */
  BOOL useTextRounding;
  /**
   This property allows to override how the baseline of a component is calculated. The default baseline of component is the baseline
   of first child in Yoga. If this property is set to YES then height of a component will be used as baseline.
   */
  BOOL useHeightAsBaseline;
};

extern template class std::vector<CKFlexboxComponentChild>;

/** Keys used to access properties on the CKComponentLayout extra dictionary. */
extern const struct CKStackComponentLayoutExtraKeys {
  /// NSNumber containing a BOOL which specifies whether a violation of constraints has occurred during layout. The absence of this key indicates that no violation of constraints occurred.
  NSString * const hadOverflow;
} CKStackComponentLayoutExtraKeys;

/**
 @uidocs https://fburl.com/CKFlexboxComponent:ca56

 A layout component that create a list of children vertically or horizontally according to Flexbox.

 This component layout is powered by Yoga layout engine (https://github.com/facebook/yoga).
 You can find more details about Yoga properties and implementation here (https://yogalayout.com/docs/)
 Yoga playground (https://yogalayout.com/playground) allows you to experiment with different
 layout configurations and can generate CKFlexboxComponent code for you

 */
@interface CKFlexboxComponent : CKLayoutComponent

/**
 @param view A view configuration, or {} for no view.
 @param size A size, or {} for the default size.
 @param style Specifies how children are laid out.
 @param children A vector of children components.
 */
+ (instancetype)newWithView:(const CKComponentViewConfiguration &)view
                       size:(const CKComponentSize &)size
                      style:(const CKFlexboxComponentStyle &)style
                   children:(CKContainerWrapper<std::vector<CKFlexboxComponentChild>> &&)children;

+ (instancetype)newWithView:(const CKComponentViewConfiguration &)view
                       size:(const CKComponentSize &)size CK_NOT_DESIGNATED_INITIALIZER_ATTRIBUTE;

@end

#import <ComponentKit/FlexboxComponentBuilder.h>

#endif
