/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKStackLayoutComponent.h"

#import <numeric>

#import <ComponentKit/CKMacros.h>

#import "ComponentUtilities.h"
#import "CKComponentSubclass.h"
#import "CKStackLayoutComponentUtilities.h"
#import "CKStackPositionedLayout.h"
#import "CKStackUnpositionedLayout.h"

@implementation CKStackLayoutComponent
{
  CKStackLayoutComponentStyle _style;
  std::vector<CKStackLayoutComponentChild> _children;
}

+ (instancetype)newWithView:(const CKComponentViewConfiguration &)view
                       size:(const CKComponentSize &)size
                      style:(const CKStackLayoutComponentStyle &)style
                   children:(const std::vector<CKStackLayoutComponentChild> &)children
{
  CKStackLayoutComponent *c = [super newWithView:view size:size];
  if (c) {
    c->_style = style;
    c->_children = children;
  }
  return c;
}

+ (instancetype)newWithView:(const CKComponentViewConfiguration &)view size:(const CKComponentSize &)size
{
  CK_NOT_DESIGNATED_INITIALIZER();
}

- (CKComponentLayout)computeLayoutThatFits:(CKSizeRange)constrainedSize
{
  const auto children = CK::filter(_children, [](const CKStackLayoutComponentChild &child){
    return child.component != nil;
  });

  const auto unpositionedLayout = CKStackUnpositionedLayout::compute(children, _style, constrainedSize);
  const auto positionedLayout = CKStackPositionedLayout::compute(unpositionedLayout, _style, constrainedSize);
  const CGSize finalSize = directionSize(_style.direction, unpositionedLayout.stackDimensionSum, positionedLayout.crossSize);
  return {self, constrainedSize.clamp(finalSize), positionedLayout.children};
}

@end
