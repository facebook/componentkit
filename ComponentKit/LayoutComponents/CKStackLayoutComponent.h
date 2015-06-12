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

typedef NS_ENUM(NSUInteger, CKStackLayoutDirection) {
  CKStackLayoutDirectionVertical,
  CKStackLayoutDirectionHorizontal,
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
};

typedef NS_ENUM(NSUInteger, CKStackLayoutAlignItems) {
  /** Align children to start of cross axis */
  CKStackLayoutAlignItemsStart,
  /** Align children with end of cross axis */
  CKStackLayoutAlignItemsEnd,
  /** Center children on cross axis */
  CKStackLayoutAlignItemsCenter,
  /** Expand children to fill cross axis */
  CKStackLayoutAlignItemsStretch,
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
  CKStackLayoutAlignSelfStretch,
};

struct CKStackLayoutComponentStyle {
  /** Specifies the direction children are stacked in. */
  CKStackLayoutDirection direction;
  /** The amount of space between each child. */
  CGFloat spacing;
  /** How children are aligned if there are no flexible children. */
  CKStackLayoutJustifyContent justifyContent;
  /** Orientation of children along cross axis */
  CKStackLayoutAlignItems alignItems;
};

struct CKStackLayoutComponentChild {
  CKComponent *component;
  /** Additional space to place before the component in the stacking direction. */
  CGFloat spacingBefore;
  /** Additional space to place after the component in the stacking direction. */
  CGFloat spacingAfter;
  /** If the sum of childrens' stack dimensions is less than the minimum size, should this component grow? */
  BOOL flexGrow;
  /** If the sum of childrens' stack dimensions is greater than the maximum size, should this component shrink? */
  BOOL flexShrink;
  /** Specifies the initial size in the stack dimension for the child. */
  CKRelativeDimension flexBasis;
  /** Orientation of the child along cross axis, overriding alignItems */
  CKStackLayoutAlignSelf alignSelf;
};

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
                   children:(const std::vector<CKStackLayoutComponentChild> &)children;

@end
