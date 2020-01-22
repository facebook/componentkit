/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKLayoutComponent.h"

#import "CKComponentInternal.h"
#import "CKComponentSubclass.h"
#import "CKRenderHelpers.h"

@implementation CKLayoutComponent

- (void)buildComponentTree:(id<CKTreeNodeWithChildrenProtocol>)parent
            previousParent:(id<CKTreeNodeWithChildrenProtocol> _Nullable)previousParent
                    params:(const CKBuildComponentTreeParams &)params
      parentHasStateUpdate:(BOOL)parentHasStateUpdate
{
  CKRender::ComponentTree::Iterable::build(self, parent, previousParent, params, parentHasStateUpdate);
}

#pragma mark - CKMountable

- (unsigned int)numberOfChildren
{
  CKFailAssert(@"%@ MUST override the '%@' method.", [self class], NSStringFromSelector(_cmd));
  return 0;
}

- (id<CKMountable>)childAtIndex:(unsigned int)index
{
  CKFailAssert(@"%@ MUST override the '%@' method.", [self class], NSStringFromSelector(_cmd));
  return nil;
}

- (CKComponentLayout)computeLayoutThatFits:(CKSizeRange)constrainedSize
{
  CKFailAssert(@"%@ MUST override the '%@' method.", [self class], NSStringFromSelector(_cmd));
  return [super computeLayoutThatFits:constrainedSize];
}

@end
