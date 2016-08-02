/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKStaticLayoutComponent.h"

#import "ComponentUtilities.h"
#import "CKComponentSubclass.h"

@implementation CKStaticLayoutComponent
{
  std::vector<CKStaticLayoutComponentChild> _children;
}

+ (instancetype)newWithView:(const CKComponentViewConfiguration &)view
                       size:(const CKComponentSize &)size
                   children:(const std::vector<CKStaticLayoutComponentChild> &)children
{
  CKStaticLayoutComponent *c = [super newWithView:view size:size];
  if (c) {
    c->_children = children;
  }
  return c;
}

+ (instancetype)newWithChildren:(const std::vector<CKStaticLayoutComponentChild> &)children
{
  return [self newWithView:{} size:{} children:children];
}

- (CKComponentLayout)computeLayoutThatFits:(CKSizeRange)constrainedSize
{
  CGSize size = {
    isinf(constrainedSize.max.width) ? kCKComponentParentDimensionUndefined : constrainedSize.max.width,
    isinf(constrainedSize.max.height) ? kCKComponentParentDimensionUndefined : constrainedSize.max.height
  };

  auto layoutChildren = CK::map(_children, [&constrainedSize, &size](CKStaticLayoutComponentChild child) {

    CGSize autoMaxSize = {
      constrainedSize.max.width - child.position.x,
      constrainedSize.max.height - child.position.y
    };
    CKSizeRange childConstraint = child.size.resolveSizeRange(size, {{0,0}, autoMaxSize});
    return CKComponentLayoutChild({child.position, CKComputeComponentLayout(child.component, childConstraint, size)});
  });

  if (isnan(size.width)) {
    size.width = constrainedSize.min.width;
    for (auto &child : layoutChildren) {
      size.width = MAX(size.width, child.position.x + child.layout.size.width);
    }
  }

  if (isnan(size.height)) {
    size.height = constrainedSize.min.height;
    for (auto &child : layoutChildren) {
      size.height = MAX(size.height, child.position.y + child.layout.size.height);
    }
  }

  return {self, constrainedSize.clamp(size), layoutChildren};
}

@end
