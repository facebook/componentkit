/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKRatioLayoutComponent.h"

#import <algorithm>

#import <ComponentKit/CKAssert.h>
#import <ComponentKit/CKComponentSubclass.h>
#import <ComponentKit/CKComponentPerfScope.h>
#import <ComponentKit/CKInternalHelpers.h>
#import <ComponentKit/CKSizeAssert.h>

@implementation CKRatioLayoutComponent
{
  CGFloat _ratio;
  CKComponent *_component;
}

+ (instancetype)newWithRatio:(CGFloat)ratio
                        size:(const CKComponentSize &)size
                   component:(CKComponent *)component
{
  CKAssert(ratio > 0, @"Ratio should be strictly positive, but received %f", ratio);
  if (ratio <= 0 || component == nil) {
    return nil;
  }
  CKComponentPerfScope perfScope(self);
  CKRatioLayoutComponent *c = [self newWithView:{} size:size];
  if (c) {
    c->_ratio = ratio;
    c->_component = component;
  }
  return c;
}

- (CKComponentLayout)computeLayoutThatFits:(CKSizeRange)constrainedSize
{
  std::vector<CGSize> sizeOptions;
  if (!isinf(constrainedSize.max.width)) {
    sizeOptions.push_back(constrainedSize.clamp({
      constrainedSize.max.width,
      CKFloorPixelValue(_ratio * constrainedSize.max.width)
    }));
  }
  if (!isinf(constrainedSize.max.height)) {
    sizeOptions.push_back(constrainedSize.clamp({
      CKFloorPixelValue(constrainedSize.max.height / _ratio),
      constrainedSize.max.height
    }));
  }

  // Choose the size closest to the desired ratio.
  const auto &bestSize = std::max_element(sizeOptions.begin(), sizeOptions.end(), [&](const CGSize &a, const CGSize &b){
    return std::abs((a.height / a.width) - _ratio) > std::abs((b.height / b.width) - _ratio);
  });

  // If there is no max size in *either* dimension, we can't apply the ratio, so just pass our size range through.
  const CKSizeRange childRange = (bestSize == sizeOptions.end())
  ? constrainedSize : constrainedSize.intersect(CKSizeRange(*bestSize, *bestSize));
  CKAssertSizeRange(childRange);
  const CGSize parentSize = (bestSize == sizeOptions.end()) ? kCKComponentParentSizeUndefined : *bestSize;
  const CKComponentLayout childLayout = CKComputeComponentLayout(_component, childRange, parentSize);
  return {self, childLayout.size, {{{0,0}, childLayout}}};
}

#pragma mark - CKMountable

- (unsigned int)numberOfChildren
{
  return CKIterable::numberOfChildren(_component);
}

- (id<CKMountable>)childAtIndex:(unsigned int)index
{
  return CKIterable::childAtIndex(self, index, _component);
}

@end
