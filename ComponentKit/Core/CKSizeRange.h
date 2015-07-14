/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <UIKit/UIKit.h>

#include <functional>

/** Expresses an inclusive range of sizes. Used to provide a simple constraint to component layout. */
struct CKSizeRange {
  CGSize min;
  CGSize max;

  /** The default constructor creates an unconstrained range. */
  CKSizeRange() : CKSizeRange({0,0}, {INFINITY, INFINITY}) {}

  CKSizeRange(const CGSize &min, const CGSize &max);

  /** Clamps the provided CGSize between the [min, max] bounds of this SizeRange. */
  CGSize clamp(const CGSize &size) const;

  /**
   Intersects another size range. If the other size range does not overlap in either dimension, this size range
   "wins" by returning a single point within its own range that is closest to the non-overlapping range.
   */
  CKSizeRange intersect(const CKSizeRange &other) const;

  bool operator==(const CKSizeRange &other) const;
  NSString *description() const;
  size_t hash() const;
};

namespace std {
  template <> struct hash<CKSizeRange> {
    size_t operator ()(const CKSizeRange &);
  };
}