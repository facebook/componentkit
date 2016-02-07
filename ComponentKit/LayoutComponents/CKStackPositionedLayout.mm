/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKStackPositionedLayout.h"

#import "CKInternalHelpers.h"
#import "ComponentUtilities.h"
#import "CKStackLayoutComponentUtilities.h"
#import "CKStackUnpositionedLayout.h"

static CGFloat crossOffset(const CKStackLayoutComponentStyle &style,
                           const CKStackUnpositionedItem &l,
                           const CGFloat crossSize)
{
  switch (alignment(l.child.alignSelf, style.alignItems)) {
    case CKStackLayoutAlignItemsEnd:
      return crossSize - crossDimension(style.direction, l.layout.size);
    case CKStackLayoutAlignItemsCenter:
      return CKFloorPixelValue((crossSize - crossDimension(style.direction, l.layout.size)) / 2);
    case CKStackLayoutAlignItemsStart:
    case CKStackLayoutAlignItemsStretch:
      return 0;
  }
}

static CKStackPositionedLayout stackedLayout(const CKStackLayoutComponentStyle &style,
                                             const CGFloat offset,
                                             const CKStackUnpositionedLayout &unpositionedLayout,
                                             const CKSizeRange &constrainedSize)
{
  // The cross dimension is the max of the childrens' cross dimensions (clamped to our constraint below).
  const auto it = std::max_element(unpositionedLayout.items.begin(), unpositionedLayout.items.end(),
                                   [&](const CKStackUnpositionedItem &a, const CKStackUnpositionedItem &b){
                                     return compareCrossDimension(style.direction, a.layout.size, b.layout.size);
                                   });
  const auto largestChildCrossSize = it == unpositionedLayout.items.end() ? 0 : crossDimension(style.direction, it->layout.size);
  const auto minCrossSize = crossDimension(style.direction, constrainedSize.min);
  const auto maxCrossSize = crossDimension(style.direction, constrainedSize.max);
  const auto maxStackSize = stackDimension(style.direction, constrainedSize.max);

  CGFloat crossSize = MIN(MAX(minCrossSize, largestChildCrossSize), maxCrossSize);

  CGFloat maxCrossItemSize = 0;
  CGFloat crossPosition = 0;
  CGPoint p = directionPoint(style.direction, offset, 0);
  BOOL first = YES;
  auto stackedChildren = CK::map(unpositionedLayout.items, [&](const CKStackUnpositionedItem &l) -> CKComponentLayoutChild {
    if(!first && style.flexWrap == CKStackLayoutWrapFlexWrap) {
      CGFloat stackSize = (style.direction == CKStackLayoutDirectionVertical) ? p.y : p.x;
      if (stackSize + l.child.spacingBefore + style.spacing + stackDimension(style.direction, l.layout.size) + l.child.spacingAfter > maxStackSize) {
        // Add maximum item size for new line cross position
        crossPosition = crossPosition + maxCrossItemSize;
        // Reset maximum cross size for new line
        maxCrossItemSize = 0;
        // Reset point to start of the line
        p = directionPoint(style.direction, offset, crossPosition);
        // Indicate the first item of line
        first = YES;
      }
      if(crossDimension(style.direction, l.layout.size) > maxCrossItemSize) {
        // Calculating maximum cross size for current line
        maxCrossItemSize = crossDimension(style.direction, l.layout.size);
      }
    }
    p = p + directionPoint(style.direction, l.child.spacingBefore, 0);
    if (!first) {
      p = p + directionPoint(style.direction, style.spacing, 0);
    }
    first = NO;
    CKComponentLayoutChild c = {
      // apply the cross alignment for this item
      p + directionPoint(style.direction, 0, crossOffset(style, l, crossSize)),
      l.layout,
    };
    p = p + directionPoint(style.direction, stackDimension(style.direction, l.layout.size) + l.child.spacingAfter, 0);
   
    return c;
  });
    
  if (style.flexWrap == CKStackLayoutWrapFlexWrap){
    // Calculating max cross size for all lines. Taking last cross position and adding max cross item size for last line
    crossSize = (maxCrossItemSize + crossPosition);
  }
  
  return {stackedChildren, crossSize};
}

CKStackPositionedLayout CKStackPositionedLayout::compute(const CKStackUnpositionedLayout &unpositionedLayout,
                                                         const CKStackLayoutComponentStyle &style,
                                                         const CKSizeRange &constrainedSize)
{
  switch (style.justifyContent) {
    case CKStackLayoutJustifyContentStart:
      return stackedLayout(style, 0, unpositionedLayout, constrainedSize);
    case CKStackLayoutJustifyContentCenter:
      return stackedLayout(style, floorf(unpositionedLayout.violation / 2), unpositionedLayout, constrainedSize);
    case CKStackLayoutJustifyContentEnd:
      return stackedLayout(style, unpositionedLayout.violation, unpositionedLayout, constrainedSize);
  }
}
