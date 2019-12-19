/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKRenderLayoutWithChildrenComponent.h"

#import <ComponentKit/CKAssert.h>

#import "CKBuildComponent.h"
#import "CKComponentInternal.h"
#import "CKRenderHelpers.h"
#import "CKTreeNodeProtocol.h"

@implementation CKRenderLayoutWithChildrenComponent
{
  std::vector<id<CKTreeNodeComponentProtocol>> _children;
}

- (std::vector<CKComponent *>)renderChildren:(id)state
{
  CKFailAssert(@"%@ MUST override the '%@' method.", [self class], NSStringFromSelector(_cmd));
  return {};
}

- (void)buildComponentTree:(id<CKTreeNodeWithChildrenProtocol>)parent
            previousParent:(id<CKTreeNodeWithChildrenProtocol>)previousParent
                    params:(const CKBuildComponentTreeParams &)params
      parentHasStateUpdate:(BOOL)parentHasStateUpdate
{
  CKRender::ComponentTree::RenderLayout::buildWithChildren(self, &_children ,parent, previousParent, params, parentHasStateUpdate);
}

#pragma mark - CKRenderComponentProtocol

+ (id)initialStateWithComponent:(id<CKRenderComponentProtocol>)component
{
  return [self initialState];
}

+ (id)initialState
{
  return CKTreeNodeEmptyState();
}

- (BOOL)shouldComponentUpdate:(id<CKRenderComponentProtocol>)component
{
  return YES;
}

- (void)didReuseComponent:(id<CKRenderComponentProtocol>)component {}

- (id)componentIdentifier
{
  return nil;
}

- (unsigned int)numberOfChildren
{
  return (unsigned int)_children.size();
}

- (id<CKMountable>)childAtIndex:(unsigned int)index
{
  if (_children.size() > index) {
    auto const mountable = static_cast<id<CKMountable>>(_children[index]);
    return mountable;
  }
  CKFailAssertWithCategory([self class], @"Index %u is out of bounds %lu", index, _children.size());
  return nil;
}

@end
