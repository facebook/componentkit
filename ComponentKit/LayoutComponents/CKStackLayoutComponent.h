/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <vector>

#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKContainerWrapper.h>

typedef NS_ENUM(NSUInteger, CKStackLayoutDirection) {
  CKStackLayoutDirectionVertical,
  CKStackLayoutDirectionHorizontal,
  CKStackLayoutDirectionVerticalReverse,
  CKStackLayoutDirectionHorizontalReverse,
};

/** If no children are flexible, how should this component justify its children in the available space? */
typedef NS_ENUM(NSUInteger, CKStackLayoutJustifyContent) {
  /**
   On overflow, children overflow out of this component's bounds on the right/bottom side.
   On underflow, children are left/top-aligned within this component's bounds.
   */
  CKStackLayoutJustifyContentStart,
  /**
   On overflow, children are centered and overflow on both sides.
   On underflow, children are centered within this component's bounds in the stacking direction.
   */
  CKStackLayoutJustifyContentCenter,
  /**
   On overflow, children overflow out of this component's bounds on the left/top side.
   On underflow, children are right/bottom-aligned within this component's bounds.
   */
  CKStackLayoutJustifyContentEnd,
  /**
   Items are positioned with space between the lines.
   */
  CKStackLayoutJustifyContentSpaceBetween,
  /**
   Items are positioned with space before, between, and after the line.
   */
  CKStackLayoutJustifyContentSpaceAround,
};

typedef NS_ENUM(NSUInteger, CKStackLayoutAlignItems) {
  /** Align children to start of cross axis */
  CKStackLayoutAlignItemsStart,
  /** Align children with end of cross axis */
  CKStackLayoutAlignItemsEnd,
  /** Center children on cross axis */
  CKStackLayoutAlignItemsCenter,
  /** Align children such that their baselines align */
  CKStackLayoutAlignItemsBaseline,
  /** Expand children to fill cross axis */
  CKStackLayoutAlignItemsStretch,
};

typedef NS_ENUM(NSUInteger, CKStackLayoutAlignContent) {
  /** Align lines to start of container */
  CKStackLayoutAlignContentStart,
  /** Align lines to end of container */
  CKStackLayoutAlignContentEnd,
  /** Align lines to center of container */
  CKStackLayoutAlignContentCenter,
  /** Evenly distribute lines; first line is at start and last line at end of container */
  CKStackLayoutAlignContentSpaceBetween,
  /** Evenly distribute lines with equal space between */
  CKStackLayoutAlignContentSpaceAround,
  /** Expand lines to fill container */
  CKStackLayoutAlignContentStretch,
};

/**
 Each child may override their parent stack's cross axis alignment.
 @see CKStackLayoutAlignItems
 */
typedef NS_ENUM(NSUInteger, CKStackLayoutAlignSelf) {
  /** Inherit alignment value from containing stack. */
  CKStackLayoutAlignSelfAuto,
  CKStackLayoutAlignSelfStart,
  CKStackLayoutAlignSelfEnd,
  CKStackLayoutAlignSelfCenter,
  CKStackLayoutAlignSelfBaseline,
  CKStackLayoutAlignSelfStretch,
};

typedef NS_ENUM(NSUInteger, CKStackLayoutWrap) {
  /** Children are not wrapped */
  CKStackLayoutWrapNoWrap,
  /** Children are wrapped if necessary */
  CKStackLayoutWrapWrap,
  /** Children are wrapped if necessary in reverse order of lines */
  CKStackLayoutWrapWrapReverse,
};

typedef NS_ENUM(NSUInteger, CKStackLayoutPositionType) {
  /** Specifies the type of position children are stacked in */
  CKStackLayoutPositionTypeRelative,
  /** With the absolute position, child is positioned relative to parent */
  CKStackLayoutPositionTypeAbsolute,
};

struct CKStackLayoutPosition {
  CKStackLayoutPositionType type;
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

/** Allows us to differentiate between an explicitly set auto-dimension and an undefined dimension */
class CKStackLayoutDimension {
public:
  constexpr CKStackLayoutDimension() noexcept : _relativeDimension(CKRelativeDimension()), _isDefined(false) {}

  /** Convenience initializer for points */
  CKStackLayoutDimension(CGFloat points) noexcept : CKStackLayoutDimension(CKRelativeDimension(points), true) {}

  /** Convenience initializer for a dimension object */
  CKStackLayoutDimension(CKRelativeDimension dimension) noexcept : CKStackLayoutDimension(dimension, true) {}

  CKRelativeDimension dimension() const noexcept {
    return _relativeDimension;
  }

  bool isDefined() const noexcept {
    return _isDefined;
  }

private:
  CKStackLayoutDimension(CKRelativeDimension dimension, bool isDefined)
  : _relativeDimension(dimension), _isDefined(isDefined) {}
  bool _isDefined;
  CKRelativeDimension _relativeDimension;
};

struct CKStackLayoutSpacing {
  CKStackLayoutDimension top;
  CKStackLayoutDimension bottom;
  /** Left in left-to-right languages, right in right-to-left languages */
  CKStackLayoutDimension start;
  /** Right in left-to-right languages, left in right-to-left languages */
  CKStackLayoutDimension end;
};

class CKStackLayoutAspectRatio {
public:
  constexpr CKStackLayoutAspectRatio() noexcept : _aspectRatio(), _isDefined(false) {}

  /** Convenience initializer for an aspect ratio */
  CKStackLayoutAspectRatio(CGFloat aspectRatio) noexcept : CKStackLayoutAspectRatio(aspectRatio, true) {}

  CGFloat aspectRatio() const noexcept {
    return _aspectRatio;
  }

  bool isDefined() const noexcept {
    return _isDefined;
  }

private:
  CKStackLayoutAspectRatio(CGFloat aspectRatio, bool isDefined)
  : _aspectRatio(aspectRatio < 0 ? fabs(aspectRatio) : aspectRatio), _isDefined(isDefined) {}
  bool _isDefined;
  CGFloat _aspectRatio;
};

struct CKStackLayoutComponentStyle {
  /** Specifies the direction children are stacked in. */
  CKStackLayoutDirection direction;
  /** The amount of space between each child. Overriden by any margins on the child in the flex direction */
  CGFloat spacing;
  /** Margin applied to the container */
  CKStackLayoutSpacing margin;
  /** How children are aligned if there are no flexible children. */
  CKStackLayoutJustifyContent justifyContent;
  /** Orientation of children along cross axis */
  CKStackLayoutAlignItems alignItems;
  /** Alignment of container's lines in multi-line flex containers. Has no effect on single line containers. */
  CKStackLayoutAlignContent alignContent;
  /** Wrapping style of children in case there isn't enough space */
  CKStackLayoutWrap wrap;
  /** Padding applied to the container */
  CKStackLayoutSpacing padding;
};

struct CKStackLayoutComponentChild {
  CKComponent *component;
  /** Additional space to place before the component in the stacking direction. Overriden by any margins in the stacking direction. */
  CGFloat spacingBefore;
  /** Additional space to place after the component in the stacking direction. Overriden by any margins in the stacking direction. */
  CGFloat spacingAfter;
  /** Margin applied to the child. Setting margin in the stacking direction overrides any spacing set on the container or child. */
  CKStackLayoutSpacing margin;
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
  CKStackLayoutAlignSelf alignSelf;
  /** Position for the child */
  CKStackLayoutPosition position;
  /** Stack order of the child.
   Child with greater stack order will be in front of an child with a lower stack order.
   If children have the same zIndex, the one declared first will appear below
   */
  NSInteger zIndex;
  /** Padding applied to the child */
  CKStackLayoutSpacing padding;
  /** Aspect ratio controls the size of the undefined dimension of a node.
   Aspect ratio is encoded as a floating point value width/height. e.g. A value of 2 leads to a node
   with a width twice the size of its height while a value of 0.5 gives the opposite effect. **/
  CKStackLayoutAspectRatio aspectRatio;
  /** This property allows node to force rounding only up.
   Text should never be rounded down as this may cause it to be truncated. **/
  BOOL useTextRounding;
};

extern template class std::vector<CKStackLayoutComponentChild>;

/**
 A simple layout component that stacks a list of children vertically or horizontally.

 - All children are initially laid out with the an infinite available size in the stacking direction.
 - In the other direction, this component's constraint is passed.
 - The children's sizes are summed in the stacking direction.
   - If this sum is less than this component's minimum size in stacking direction, children with flexGrow are flexed.
   - If it is greater than this component's maximum size in the stacking direction, children with flexShrink are flexed.
   - If, even after flexing, the sum is still greater than this component's maximum size in the stacking direction,
     justifyContent determines how children are laid out.

 For example:
 - Suppose stacking direction is Vertical, min-width=100, max-width=300, min-height=200, max-height=500.
 - All children are laid out with min-width=100, max-width=300, min-height=0, max-height=INFINITY.
 - If the sum of the childrens' heights is less than 200, components with flexGrow are flexed larger.
 - If the sum of the childrens' heights is greater than 500, components with flexShrink are flexed smaller.
   Each component is shrunk by `((sum of heights) - 500)/(number of components)`.
 - If the sum of the childrens' heights is greater than 500 even after flexShrink-able components are flexed,
   justifyContent determines how children are laid out.
 */
@interface CKStackLayoutComponent : CKComponent

/**
 @param view A view configuration, or {} for no view.
 @param size A size, or {} for the default size.
 @param style Specifies how children are laid out.
 @param children A vector of children components.
 */
+ (instancetype)newWithView:(const CKComponentViewConfiguration &)view
                       size:(const CKComponentSize &)size
                      style:(const CKStackLayoutComponentStyle &)style
                   children:(CKContainerWrapper<std::vector<CKStackLayoutComponentChild>> &&)children;

@end
