/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKGroupComponent.h"

#import "CKBuildComponent.h"
#import "CKTreeNode.h"
#import "CKComponentInternal.h"

@implementation CKGroupComponent

+ (instancetype)newWithView:(const CKComponentViewConfiguration &)view
                       size:(const CKComponentSize &)size
{
  // As we are going to retrieve the state from the `CKBaseTreeNode`
  // We don't need to acuire the scope handle from 'CKThreadLocalComponentScope::currentScope'.
  return [super newWithViewWithoutScopeHandle:view size:size];
}

- (std::vector<CKComponent *>)renderGroup:(id)state
{
  return {};
}

- (void)buildComponentTree:(CKTreeNode *)owner
             previousOwner:(CKTreeNode *)previousOwner
                 scopeRoot:(CKComponentScopeRoot *)scopeRoot
              stateUpdates:(const CKComponentStateUpdateMap &)stateUpdates
{
  auto const ownerComponent = [self ownerComponent];
  Class nodeClass = ownerComponent ? [CKTreeNode class] : [CKBaseTreeNode class];
  CKBaseTreeNode*node = [[nodeClass alloc]
                         initWithComponent:self
                         owner:owner
                         previousOwner:previousOwner
                         scopeRoot:scopeRoot
                         stateUpdates:stateUpdates];
  
  CKTreeNode * ownerForChild = (ownerComponent ? (CKTreeNode *)node : owner);
  CKTreeNode * previousOwnerForChild = (ownerComponent ? (CKTreeNode *)[previousOwner childForComponentKey:[node componentKey]] : previousOwner);

  auto const componentKey = [node componentKey];
  auto const children = [self renderGroup:node.state];
  for (auto const child : children) {
    if (child) {
      [child buildComponentTree:ownerForChild
                  previousOwner:previousOwnerForChild
                      scopeRoot:scopeRoot
                   stateUpdates:stateUpdates];
    }
  }
}

#pragma mark - CKComponentTreeOwner

- (BOOL)ownerComponent
{
  return NO;
}

@end
