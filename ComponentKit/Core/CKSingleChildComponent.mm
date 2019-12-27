/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKSingleChildComponent.h"

#import "CKComponentInternal.h"
#import "CKComponentSubclass.h"
#import "CKRenderHelpers.h"

@implementation CKSingleChildComponent

- (CKComponent *)child
{
  return _child;
}

- (UIView *)viewForAnimation
{
  // Delegate to the wrapped component's viewForAnimation if we don't have one.
  return [super viewForAnimation] ?: [_child viewForAnimation];
}

#pragma mark - CKMountable

- (unsigned int)numberOfChildren
{
  return _child ? 1 : 0;
}

- (id<CKMountable>)childAtIndex:(unsigned int)index
{
  if (index == 0) {
    return _child;
  }
  CKFailAssertWithCategory([self class], @"Index %u is out of bounds %u", index, [self numberOfChildren]);
  return nil;
}

- (void)buildComponentTree:(id<CKTreeNodeWithChildrenProtocol>)parent
            previousParent:(id<CKTreeNodeWithChildrenProtocol>)previousParent
                    params:(const CKBuildComponentTreeParams &)params
      parentHasStateUpdate:(BOOL)parentHasStateUpdate
{
  CKRender::ComponentTree::Iterable::build(self, parent, previousParent, params, parentHasStateUpdate);
}

@end
