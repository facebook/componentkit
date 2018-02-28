/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKMultiChildComponent.h"

#import "CKBuildComponent.h"
#import "CKOwnerTreeNode.h"
#import "CKComponentInternal.h"

@implementation CKMultiChildComponent

+ (instancetype)new
{
  return [super newRenderComponentWithView:{} size:{}];
}

+ (instancetype)newWithView:(const CKComponentViewConfiguration &)view
                       size:(const CKComponentSize &)size
{
  return [super newRenderComponentWithView:view size:size];
}

- (std::vector<CKComponent *>)renderChildren:(id)state
{
  return {};
}

- (void)buildComponentTree:(id<CKOwnerTreeNodeProtocol>)owner
             previousOwner:(id<CKOwnerTreeNodeProtocol>)previousOwner
                 scopeRoot:(CKComponentScopeRoot *)scopeRoot
              stateUpdates:(const CKComponentStateUpdateMap &)stateUpdates
{
  auto const isOwnerComponent = [[self class] isOwnerComponent];
  const Class nodeClass = isOwnerComponent ? [CKOwnerTreeNode class] : [CKTreeNode class];
  CKTreeNode *const node = [[nodeClass alloc]
                            initWithComponent:self
                            owner:owner
                            previousOwner:previousOwner
                            scopeRoot:scopeRoot
                            stateUpdates:stateUpdates];
  
  const id<CKOwnerTreeNodeProtocol> ownerForChild = (isOwnerComponent ? (id<CKOwnerTreeNodeProtocol>)node : owner);
  const id<CKOwnerTreeNodeProtocol> previousOwnerForChild = (isOwnerComponent ? (id<CKOwnerTreeNodeProtocol>)[previousOwner childForComponentKey:[node componentKey]] : previousOwner);

  auto const children = [self renderChildren:node.state];
  for (auto const child : children) {
    if (child) {
      [child buildComponentTree:ownerForChild
                  previousOwner:previousOwnerForChild
                      scopeRoot:scopeRoot
                   stateUpdates:stateUpdates];
    }
  }
}

#pragma mark - CKRenderComponent

+ (BOOL)isOwnerComponent
{
  return NO;
}

@end
