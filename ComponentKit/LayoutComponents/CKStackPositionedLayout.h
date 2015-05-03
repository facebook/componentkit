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
#import <ComponentKit/CKDimension.h>
#import <ComponentKit/CKStackLayoutComponent.h>

class CKStackUnpositionedLayout;

/** Represents a set of laid out and positioned stack layout children. */
struct CKStackPositionedLayout {
  const std::vector<CKComponentLayoutChild> children;
  const CGFloat crossSize;

  /** Given an unpositioned layout, computes the positions each child should be placed at. */
  static CKStackPositionedLayout compute(const CKStackUnpositionedLayout &unpositionedLayout,
                                         const CKStackLayoutComponentStyle &style,
                                         const CKSizeRange &constrainedSize);
};
