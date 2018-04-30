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
               forceParent:(BOOL)forceParent
{
  // If forceParent is set to YES, we need to use `CKRenderTreeNodeWithChildren`; each component is a parent component and CKRenderWitjChildrenComponent has multiple children.
  if (forceParent) {
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
        [child buildComponentTree:node previousOwner:previousOwnerForChild scopeRoot:scopeRoot stateUpdates:stateUpdates forceParent:forceParent];
      }
    }
  } else {
    // Otherwise, we choose the type according to the `isOwnerComponent` method.
    auto const isOwnerComponent = [[self class] isOwnerComponent];
    const Class nodeClass = isOwnerComponent ? [CKRenderTreeNodeWithChildren class] : [CKRenderTreeNode class];
    CKTreeNode *const node = [[nodeClass alloc]
                              initWithComponent:self
                              owner:owner
                              previousOwner:previousOwner
                              scopeRoot:scopeRoot
                              stateUpdates:stateUpdates];

    const id<CKTreeNodeWithChildrenProtocol> ownerForChild = (isOwnerComponent ? (id<CKTreeNodeWithChildrenProtocol>)node : owner);
    const id<CKTreeNodeWithChildrenProtocol> previousOwnerForChild = (isOwnerComponent ? (id<CKTreeNodeWithChildrenProtocol>)[previousOwner childForComponentKey:[node componentKey]] : previousOwner);

    auto const children = [self renderChildren:node.state];
    for (auto const child : children) {
      if (child) {
        [child buildComponentTree:ownerForChild previousOwner:previousOwnerForChild scopeRoot:scopeRoot stateUpdates:stateUpdates forceParent:forceParent];
      }
    }
  }
}

#pragma mark - CKRenderComponentProtocol

+ (BOOL)isOwnerComponent
{
  return NO;
}

+ (id)initialStateWithComponent:(id<CKRenderComponentProtocol>)component
{
  return [self initialState];
}

+ (id)initialState
{
  return [CKTreeNodeEmptyState emptyState];
}

@end
