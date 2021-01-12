// (c) Facebook, Inc. and its affiliates. Confidential and proprietary.

#import "CKZStackComponent.h"

#import <numeric>

#import <ComponentKit/RCLayout.h>

@implementation CKZStackComponentChild
- (instancetype)initWithComponent:(CKComponent *_Nullable)component
{
  return [self initWithComponent:component gravity:CKZStackComponentGravityTopLeft];
}

- (instancetype)initWithComponent:(CKComponent *_Nullable)component gravity:(CKZStackComponentGravity)gravity
{
  if (self = [super init]) {
    _component = component;
    _gravity = gravity;
  }
  return self;
}
@end

@implementation CKZStackComponent {
  NSArray<CKZStackComponentChild *> *_children;
}

- (instancetype)initWithChildren:(NSArray<CKZStackComponentChild *> *)children
{
  if (self = [super initWithView:{} size:{}]) {
    _children = children;
  }
  return self;
}

- (unsigned int)numberOfChildren
{
  return static_cast<unsigned int>([_children count]);
}

- (id<RCIterable>)childAtIndex:(unsigned int)index
{
  return _children[index].component;
}

static auto positionForSizeAndGravity(CGSize size, CKZStackComponentGravity gravity, CGSize zStackSize) -> CGPoint {
  switch (gravity) {
    case CKZStackComponentGravityTopLeft:
      return CGPointZero;
    case CKZStackComponentGravityTopRight:
      return CGPoint{zStackSize.width - size.width, 0};
  }
}

- (RCLayout)computeLayoutThatFits:(CKSizeRange)constrainedSize
                 restrictedToSize:(const CKComponentSize &)s
             relativeToParentSize:(CGSize)parentSize
{
  auto const childLayouts = CK::map(_children, [&](CKZStackComponentChild *child) {
    return [child.component layoutThatFits:constrainedSize parentSize:parentSize];
  });
  auto const childSizes = CK::map(childLayouts, [&](const RCLayout &l) { return l.size; });
  auto const size = std::accumulate(childSizes.begin(), childSizes.end(), CGRectZero, [](const CGRect &r, const CGSize &s) {
    return CGRectUnion(r, CGRect{CGPointZero, s});
  }).size;

  auto layoutChildren = CK::mapWithIndex(childLayouts, [&](const RCLayout &l, NSUInteger idx) -> RCLayoutChild {
    return {positionForSizeAndGravity(l.size, _children[idx].gravity, size), l};
  });

  return {
    self,
    size,
    std::move(layoutChildren)
  };
}

@end

namespace CK {
auto ZStackComponentBuilder() -> ZStackComponentBuilderEmpty
{
  return {};
}

auto ZStackComponentBuilder(const CK::ComponentSpecContext &c) -> ZStackComponentBuilderContext
{
  return {c};
}
}
