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
#import "CKRenderTreeNodeWithChildren.h"
#import <ComponentKit/CKComponentInternal.h>

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

- (void)buildComponentTree:(id<CKTreeNodeWithChildrenProtocol>)owner
             previousOwner:(id<CKTreeNodeWithChildrenProtocol>)previousOwner
                 scopeRoot:(CKComponentScopeRoot *)scopeRoot
              stateUpdates:(const CKComponentStateUpdateMap &)stateUpdates
               forceParent:(BOOL)forceParent
{
  if (forceParent) {
    auto const node = [[CKTreeNodeWithChildren alloc]
                       initWithComponent:self
                       owner:owner
                       previousOwner:previousOwner
                       scopeRoot:scopeRoot
                       stateUpdates:stateUpdates];

    auto const previousOwnerForChild = (id<CKTreeNodeWithChildrenProtocol>)[previousOwner childForComponentKey:[node componentKey]];
    for (auto const &child : _children) {
      [child.component buildComponentTree:node previousOwner:previousOwnerForChild scopeRoot:scopeRoot stateUpdates:stateUpdates forceParent:forceParent];
    }
  } else {
    [super buildComponentTree:owner previousOwner:previousOwner scopeRoot:scopeRoot stateUpdates:stateUpdates forceParent:forceParent];
    for (auto const &child : _children) {
      [child.component buildComponentTree:owner previousOwner:previousOwner scopeRoot:scopeRoot stateUpdates:stateUpdates forceParent:forceParent];
    }
  }
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
