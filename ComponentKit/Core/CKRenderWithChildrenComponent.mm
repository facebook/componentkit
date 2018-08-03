/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKRenderWithChildrenComponent.h"

#import "CKBuildComponent.h"
#import "CKRenderTreeNode.h"
#import "CKRenderTreeNodeWithChildren.h"
#import "CKComponentInternal.h"

@implementation CKRenderWithChildrenComponent

+ (instancetype)new
{
  return [super newRenderComponentWithView:{} size:{} isLayoutComponent:NO];
}

+ (instancetype)newWithView:(const CKComponentViewConfiguration &)view
                       size:(const CKComponentSize &)size
{
  return [super newRenderComponentWithView:view size:size isLayoutComponent:NO];
}

- (std::vector<CKComponent *>)renderChildren:(id)state
{
  return {};
}

- (void)buildComponentTree:(id<CKTreeNodeWithChildrenProtocol>)owner
             previousOwner:(id<CKTreeNodeWithChildrenProtocol>)previousOwner
                 scopeRoot:(CKComponentScopeRoot *)scopeRoot
              stateUpdates:(const CKComponentStateUpdateMap &)stateUpdates
                    config:(const CKBuildComponentConfig &)config
{
  auto const node = [[CKRenderTreeNodeWithChildren alloc]
                     initWithComponent:self
                     owner:owner
                     previousOwner:previousOwner
                     scopeRoot:scopeRoot
                     stateUpdates:stateUpdates];

  auto const children = [self renderChildren:node.state];
  auto const previousOwnerForChild = (id<CKTreeNodeWithChildrenProtocol>)[previousOwner childForComponentKey:[node componentKey]];
  for (auto const child : children) {
    if (child) {
      [child buildComponentTree:node previousOwner:previousOwnerForChild scopeRoot:scopeRoot stateUpdates:stateUpdates config:config];
    }
  }
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

@end
