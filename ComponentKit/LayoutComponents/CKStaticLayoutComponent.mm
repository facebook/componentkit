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

#include <algorithm>

#import <ComponentKit/CKComponentInternal.h>
#import <ComponentKit/CKMacros.h>
#import <ComponentKit/CKFunctionalHelpers.h>
#import <ComponentKit/CKSizeAssert.h>

#import "CKComponentSubclass.h"

@implementation CKStaticLayoutComponent
{
  std::vector<CKStaticLayoutComponentChild> _children;
}

+ (instancetype)newWithView:(const CKComponentViewConfiguration &)view
                       size:(const CKComponentSize &)size
                   children:(CKContainerWrapper<std::vector<CKStaticLayoutComponentChild>> &&)children
{
  CKStaticLayoutComponent *c = [super newWithView:view size:size];
  if (c) {
    c->_children = children.take();
  }
  return c;
}

+ (instancetype)newWithChildren:(CKContainerWrapper<std::vector<CKStaticLayoutComponentChild>> &&)children
{
  return [self newWithView:{} size:{} children:std::move(children)];
}

- (unsigned int)numberOfChildren
{
  return (unsigned int)_children.size();
}

- (id<CKMountable>)childAtIndex:(unsigned int)index
{
  if (index < _children.size()) {
    return _children[index].component;
  }
  CKFailAssertWithCategory([self class], @"Index %u is out of bounds %u", index, [self numberOfChildren]);
  return nil;
}

- (CKComponentLayout)computeLayoutThatFits:(CKSizeRange)constrainedSize
{
  CGSize size = {
    isinf(constrainedSize.max.width) ? kCKComponentParentDimensionUndefined : constrainedSize.max.width,
    isinf(constrainedSize.max.height) ? kCKComponentParentDimensionUndefined : constrainedSize.max.height
  };

  auto layoutChildren = CK::map(_children, [&constrainedSize, &size](CKStaticLayoutComponentChild child) {

    CGSize autoMaxSize = {
      std::max(constrainedSize.max.width - child.position.x, (CGFloat)0),
      std::max(constrainedSize.max.height - child.position.y, (CGFloat)0)
    };
    CKSizeRange childConstraint = child.size.resolveSizeRange(size, {{0,0}, autoMaxSize});
    CKAssertSizeRange(childConstraint);
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
