/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKRenderLayoutComponent.h"

#import "CKComponentInternal.h"
#import "CKRenderHelpers.h"
#import "CKTreeNode.h"

@implementation CKRenderLayoutComponent

- (CKComponent *)render:(id)state
{
  CKFailAssert(@"%@ MUST override '%@'.", [self class], NSStringFromSelector(_cmd));
  return nil;
}

- (void)buildComponentTree:(id<CKTreeNodeWithChildrenProtocol>)parent
            previousParent:(id<CKTreeNodeWithChildrenProtocol>)previousParent
                    params:(const CKBuildComponentTreeParams &)params
      parentHasStateUpdate:(BOOL)parentHasStateUpdate
{
  CKRender::buildComponentTreeWithChild(self, nullptr, parent, previousParent, params, parentHasStateUpdate, YES);
}

#pragma mark - CKRenderComponentProtocol

+ (id)initialStateWithComponent:(id<CKRenderComponentProtocol>)component
{
  return [self initialState];
}

+ (id)initialState
{
  return [CKTreeNodeEmptyState emptyState];
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

@end
