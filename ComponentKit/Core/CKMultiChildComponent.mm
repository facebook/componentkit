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
#import "CKTreeNode.h"
#import "CKComponentInternal.h"

@implementation CKMultiChildComponent

+ (instancetype)newWithView:(const CKComponentViewConfiguration &)view
                       size:(const CKComponentSize &)size
{
  // As we are going to retrieve the state from the `CKBaseTreeNode`
  // We don't need to acuire the scope handle from 'CKThreadLocalComponentScope::currentScope'.
  return [super newWithViewWithoutAcquiringScopeHandle:view size:size];
}

- (std::vector<CKComponent *>)renderChildren:(id)state
{
  return {};
}

- (void)buildComponentTree:(CKTreeNode *)owner
             previousOwner:(CKTreeNode *)previousOwner
                 scopeRoot:(CKComponentScopeRoot *)scopeRoot
              stateUpdates:(const CKComponentStateUpdateMap &)stateUpdates
{
  auto const isOwnerComponent = [[self class] isOwnerComponent];
  const Class nodeClass = isOwnerComponent ? [CKTreeNode class] : [CKBaseTreeNode class];
  CKBaseTreeNode *const node = [[nodeClass alloc]
                                initWithComponent:self
                                owner:owner
                                previousOwner:previousOwner
                                scopeRoot:scopeRoot
                                stateUpdates:stateUpdates];
  
  CKTreeNode *const ownerForChild = (isOwnerComponent ? (CKTreeNode *)node : owner);
  CKTreeNode *const previousOwnerForChild = (isOwnerComponent ? (CKTreeNode *)[previousOwner childForComponentKey:[node componentKey]] : previousOwner);

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
