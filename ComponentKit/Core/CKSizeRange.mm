/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKSizeRange.h"

#import <functional>

#import <ComponentKit/CKDimension.h>
#import <ComponentKit/CKEqualityHashHelpers.h>
#import <ComponentKit/CKMacros.h>

CKSizeRange::CKSizeRange(const CGSize &_min, const CGSize &_max) : min(_min), max(_max)
{
  CKCAssertPositiveReal(@"Range min width", min.width);
  CKCAssertPositiveReal(@"Range min height", min.height);
  CKCAssertInfOrPositiveReal(@"Range max width", max.width);
  CKCAssertInfOrPositiveReal(@"Range max height", max.height);
  CKCAssert(min.width <= max.width,
            @"Range min width (%f) must not be larger than max width (%f).", min.width, max.width);
  CKCAssert(min.height <= max.height,
            @"Range min height (%f) must not be larger than max height (%f).", min.height, max.height);
}

CGSize CKSizeRange::clamp(const CGSize &size) const
{
  return {
    MAX(min.width, MIN(max.width, size.width)),
    MAX(min.height, MIN(max.height, size.height))
  };
}

struct _Range {
  CGFloat min;
  CGFloat max;

  /**
   Intersects another dimension range. If the other range does not overlap, this size range "wins" by returning a
   single point within its own range that is closest to the non-overlapping range.
   */
  _Range intersect(const _Range &other) const
  {
    CGFloat newMin = MAX(min, other.min);
    CGFloat newMax = MIN(max, other.max);
    if (!(newMin > newMax)) {
      return {newMin, newMax};
    } else {
      // No intersection. If we're before the other range, return our max; otherwise our min.
      if (min < other.min) {
        return {max, max};
      } else {
        return {min, min};
      }
    }
  }
};

CKSizeRange CKSizeRange::intersect(const CKSizeRange &other) const
{
  auto w = _Range({min.width, max.width}).intersect({other.min.width, other.max.width});
  auto h = _Range({min.height, max.height}).intersect({other.min.height, other.max.height});
  return {{w.min, h.min}, {w.max, h.max}};
}

bool CKSizeRange::operator==(const CKSizeRange &other) const
{
  return CGSizeEqualToSize(min, other.min) && CGSizeEqualToSize(max, other.max);
}

NSString *CKSizeRange::description() const
{
  return [NSString stringWithFormat:@"<CKSizeRange: min=%@, max=%@>", NSStringFromCGSize(min), NSStringFromCGSize(max)];
}

size_t CKSizeRange::hash() const
{
  std::hash<CGFloat> hasher;
  NSUInteger subhashes[] = {
    hasher(min.width),
    hasher(min.height),
    hasher(max.width),
    hasher(max.height)
  };
  return CKIntegerArrayHash(subhashes, CK_ARRAY_COUNT(subhashes));
}

size_t std::hash<CKSizeRange>::operator()(const CKSizeRange &s)
{
  return s.hash();
};
