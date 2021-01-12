/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKSizingComponent.h"

#import <ComponentKit/CKComponentSubclass.h>

#import "CKComponentSize_SwiftBridge+Internal.h"

@implementation CKSizingComponent {
  CKComponent *_component;
  CKComponentSize _size;
}

- (instancetype)initWithSwiftSize:(CKComponentSize_SwiftBridge *)swiftSize
                        component:(CKComponent *)component
{
  const auto size = swiftSize != nil ? swiftSize.componentSize : CKComponentSize{};
  return [self initWithSize:size component:component];
}

- (instancetype _Nullable)initWithSize:(const CKComponentSize &)size
                             component:(CKComponent *)component
{
  if (self = [super initWithView:{} size:size]) {
    _component = component;
    _size = size;
  }
  return self;
}

- (unsigned int)numberOfChildren
{
  return RCIterable::numberOfChildren(_component);
}

- (id<CKMountable>)childAtIndex:(unsigned int)index
{
  return RCIterable::childAtIndex(self, index, _component);
}

- (RCLayout)computeLayoutThatFits:(CKSizeRange)constrainedSize
                 restrictedToSize:(const CKComponentSize &)size
             relativeToParentSize:(CGSize)parentSize
{
  const auto resolvedRange = constrainedSize.intersect(_size.resolve(parentSize));
  const CGSize computedSize = {
    isinf(resolvedRange.max.width) ? kCKComponentParentDimensionUndefined : resolvedRange.max.width,
    isinf(resolvedRange.max.height) ? kCKComponentParentDimensionUndefined : resolvedRange.max.height,
  };
  const auto childLayout = CKComputeComponentLayout(_component, resolvedRange, computedSize);
  return {self, resolvedRange.clamp(childLayout.size), {{CGPointZero, childLayout}}};
}

@end
