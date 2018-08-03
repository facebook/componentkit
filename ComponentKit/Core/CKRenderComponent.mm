/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */


#import "CKRenderComponent.h"

#import "CKBuildComponent.h"
#import "CKComponentInternal.h"
#import "CKComponentSubclass.h"
#import "CKRenderTreeNode.h"
#import "CKRenderTreeNodeWithChild.h"
#import "CKRenderTreeNodeWithChildren.h"

@implementation CKRenderComponent
{
  CKComponent *_childComponent;
}

+ (instancetype)new
{
  return [super newRenderComponentWithView:{} size:{} isLayoutComponent:NO];
}

+ (instancetype)newWithView:(const CKComponentViewConfiguration &)view
                       size:(const CKComponentSize &)size
{
  return [super newRenderComponentWithView:view size:size isLayoutComponent:NO];
}

- (CKComponent *)render:(id)state
{
  return nil;
}

- (void)buildComponentTree:(id<CKTreeNodeWithChildrenProtocol>)owner
             previousOwner:(id<CKTreeNodeWithChildrenProtocol>)previousOwner
                 scopeRoot:(CKComponentScopeRoot *)scopeRoot
              stateUpdates:(const CKComponentStateUpdateMap &)stateUpdates
                    config:(const CKBuildComponentConfig &)config
{
  auto const node = [[CKRenderTreeNodeWithChild alloc]
                     initWithComponent:self
                     owner:owner
                     previousOwner:previousOwner
                     scopeRoot:scopeRoot
                     stateUpdates:stateUpdates];

  auto const child = [self render:node.state];
  if (child) {
    _childComponent = child;
    [child buildComponentTree:node
                previousOwner:(id<CKTreeNodeWithChildrenProtocol>)[previousOwner childForComponentKey:[node componentKey]]
                    scopeRoot:scopeRoot
                 stateUpdates:stateUpdates
                       config:config];
  }
}

- (CKComponentLayout)computeLayoutThatFits:(CKSizeRange)constrainedSize
                          restrictedToSize:(const CKComponentSize &)size
                      relativeToParentSize:(CGSize)parentSize
{
  CKAssert(size == CKComponentSize(),
           @"CKRenderComponent only passes size {} to the super class initializer, but received size %@ "
           "(component=%@)", size.description(), _childComponent);

  auto const l = [_childComponent layoutThatFits:constrainedSize parentSize:parentSize];
  return {self, l.size, {{{0,0}, l}}};
}

#pragma mark - CKRenderComponentProtocol

+ (BOOL)isOwnerComponent
{
  return YES;
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
