/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKStackLayoutComponent.h>

inline CGFloat stackDimension(const CKStackLayoutDirection direction, const CGSize size)
{
  return (direction == CKStackLayoutDirectionVertical) ? size.height : size.width;
}

inline CGFloat crossDimension(const CKStackLayoutDirection direction, const CGSize size)
{
  return (direction == CKStackLayoutDirectionVertical) ? size.width : size.height;
}

inline BOOL compareCrossDimension(const CKStackLayoutDirection direction, const CGSize a, const CGSize b)
{
  return crossDimension(direction, a) < crossDimension(direction, b);
}

inline CGPoint directionPoint(const CKStackLayoutDirection direction, const CGFloat stack, const CGFloat cross)
{
  return (direction == CKStackLayoutDirectionVertical) ? CGPointMake(cross, stack) : CGPointMake(stack, cross);
}

inline CGSize directionSize(const CKStackLayoutDirection direction, const CGFloat stack, const CGFloat cross)
{
  return (direction == CKStackLayoutDirectionVertical) ? CGSizeMake(cross, stack) : CGSizeMake(stack, cross);
}

inline CKSizeRange directionSizeRange(const CKStackLayoutDirection direction,
                                      const CGFloat stackMin,
                                      const CGFloat stackMax,
                                      const CGFloat crossMin,
                                      const CGFloat crossMax)
{
  return {directionSize(direction, stackMin, crossMin), directionSize(direction, stackMax, crossMax)};
}

inline CKStackLayoutAlignItems alignment(CKStackLayoutAlignSelf childAlignment, CKStackLayoutAlignItems stackAlignment)
{
  switch (childAlignment) {
    case CKStackLayoutAlignSelfCenter:
      return CKStackLayoutAlignItemsCenter;
    case CKStackLayoutAlignSelfEnd:
      return CKStackLayoutAlignItemsEnd;
    case CKStackLayoutAlignSelfStart:
      return CKStackLayoutAlignItemsStart;
    case CKStackLayoutAlignSelfStretch:
      return CKStackLayoutAlignItemsStretch;
    case CKStackLayoutAlignSelfAuto:
    default:
      return stackAlignment;
  }
}
