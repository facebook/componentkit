/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKCenterLayoutComponent.h"

#import "CKInternalHelpers.h"
#import "CKComponentSubclass.h"
#import "ComponentUtilities.h"

@implementation CKCenterLayoutComponent
{
  CKCenterLayoutComponentCenteringOptions _centeringOptions;
  CKCenterLayoutComponentSizingOptions _sizingOptions;
  CKComponent *_child;
}

+ (instancetype)newWithCenteringOptions:(CKCenterLayoutComponentCenteringOptions)centeringOptions
                          sizingOptions:(CKCenterLayoutComponentSizingOptions)sizingOptions
                                  child:(CKComponent *)child
                                   size:(const CKComponentSize &)size
{
  CKCenterLayoutComponent *c = [super newWithView:{} size:size];
  if (c) {
    c->_centeringOptions = centeringOptions;
    c->_sizingOptions = sizingOptions;
    c->_child = child;
  }
  return c;
}

- (CKComponentLayout)computeLayoutThatFits:(CKSizeRange)constrainedSize
{
  // If we have a finite size in any direction, pass this so that the child can
  // resolve percentages agains it. Otherwise pass kCKComponentParentDimensionUndefined
  // as the size will depend on the content
  CGSize size = {
    isinf(constrainedSize.max.width) ? kCKComponentParentDimensionUndefined : constrainedSize.max.width,
    isinf(constrainedSize.max.height) ? kCKComponentParentDimensionUndefined : constrainedSize.max.height
  };

  // Layout the child
  const CGSize minChildSize = {
    (_centeringOptions & CKCenterLayoutComponentCenteringX) != 0 ? 0 : constrainedSize.min.width,
    (_centeringOptions & CKCenterLayoutComponentCenteringY) != 0 ? 0 : constrainedSize.min.height,
  };
  const CKComponentLayout childLayout = CKComputeComponentLayout(_child, {minChildSize, {constrainedSize.max}}, size);

  // If we have an undetermined height or width, use the child size to define the layout
  // size
  size = constrainedSize.clamp({
    isnan(size.width) ? childLayout.size.width : size.width,
    isnan(size.height) ? childLayout.size.height : size.height
  });

  // If minimum size options are set, attempt to shrink the size to the size of the child
  size = constrainedSize.clamp({
    MIN(size.width, (_sizingOptions & CKCenterLayoutComponentSizingOptionMinimumX) != 0 ? childLayout.size.width : size.width),
    MIN(size.height, (_sizingOptions & CKCenterLayoutComponentSizingOptionMinimumY) != 0 ? childLayout.size.height : size.height)
  });

  // Compute the centered postion for the child
  BOOL shouldCenterAlongX = (_centeringOptions & CKCenterLayoutComponentCenteringX);
  BOOL shouldCenterAlongY = (_centeringOptions & CKCenterLayoutComponentCenteringY);
  const CGPoint childPosition = {
    CKRoundPixelValue(shouldCenterAlongX ? (size.width - childLayout.size.width) * 0.5f : 0),
    CKRoundPixelValue(shouldCenterAlongY ? (size.height - childLayout.size.height) * 0.5f : 0)
  };

  return {self, size, {{childPosition, childLayout}}};
}

@end
