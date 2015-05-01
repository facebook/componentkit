/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKComponentLayout.h>
#import <ComponentKit/CKStackLayoutComponent.h>

struct CKStackUnpositionedItem {
  /** The original source child. */
  CKStackLayoutComponentChild child;
  /** The proposed layout. */
  CKComponentLayout layout;
};

/** Represents a set of stack layout children that have their final layout computed, but are not yet positioned. */
struct CKStackUnpositionedLayout {
  /** A set of proposed child layouts, not yet positioned. */
  const std::vector<CKStackUnpositionedItem> items;
  /** The total size of the children in the stack dimension, including all spacing. */
  const CGFloat stackDimensionSum;
  /** The amount by which stackDimensionSum violates constraints. If positive, less than min; negative, greater than max. */
  const CGFloat violation;

  /** Given a set of children, computes the unpositioned layouts for those children. */
  static CKStackUnpositionedLayout compute(const std::vector<CKStackLayoutComponentChild> &children,
                                           const CKStackLayoutComponentStyle &style,
                                           const CKSizeRange &sizeRange);
};
