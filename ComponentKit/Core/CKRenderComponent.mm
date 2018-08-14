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

- (void)buildComponentTree:(id<CKTreeNodeWithChildrenProtocol>)parent
            previousParent:(id<CKTreeNodeWithChildrenProtocol>)previousParent
                    params:(const CKBuildComponentTreeParams &)params
                    config:(const CKBuildComponentConfig &)config
            hasDirtyParent:(BOOL)hasDirtyParent
{
  auto const node = [[CKRenderTreeNodeWithChild alloc]
                     initWithComponent:self
                     parent:parent
                     previousParent:previousParent
                     scopeRoot:params.scopeRoot
                     stateUpdates:params.stateUpdates];

  // Faster state optimization.
  if (config.enableFasterStateUpdates && !hasDirtyParent && previousParent && params.buildTrigger == BuildTrigger::StateUpdate) {
    auto const dirtyNodeId = params.treeNodeDirtyIds.find(node.nodeIdentifier);
    // Check if the tree node is not dirty (not in a branch of a state update).
    if (dirtyNodeId == params.treeNodeDirtyIds.end()) {
      auto const componentKey = node.componentKey;
      auto const previousChild = [previousParent childForComponentKey:componentKey];
      // Link the previous child to the new parent.
      [parent setChild:previousChild forComponentKey:componentKey];
      // Link the previous child component to the the new component.
      _childComponent = [(CKRenderTreeNodeWithChild *)previousChild child].component;
      return;
    }
    else { // Otherwise, update the `hasDirtyParent` param for its children.
      hasDirtyParent = YES;
    }
  }

  auto const child = [self render:node.state];
  if (child) {
    _childComponent = child;
    [child buildComponentTree:node
               previousParent:(id<CKTreeNodeWithChildrenProtocol>)[previousParent childForComponentKey:[node componentKey]]
                       params:params
                       config:config
               hasDirtyParent:hasDirtyParent];
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

+ (id)initialStateWithComponent:(id<CKRenderComponentProtocol>)component
{
  return [self initialState];
}

+ (id)initialState
{
  return [CKTreeNodeEmptyState emptyState];
}

@end
