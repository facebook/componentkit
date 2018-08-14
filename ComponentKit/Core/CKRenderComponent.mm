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

  // Faster state/props optimizations require previous parent.
  if (previousParent) {
    if (params.buildTrigger == BuildTrigger::StateUpdate) {
      // During state update, we have two possible optimizations:
      // 1. Faster state update
      // 2. Faster props update (when the parent is dirty, we handle state update as props update).
      if (config.enableFasterStateUpdates || config.enableFasterPropsUpdates) {
        // Check if the tree node is not dirty (not in a branch of a state update).
        auto const dirtyNodeId = params.treeNodeDirtyIds.find(node.nodeIdentifier);
        if (dirtyNodeId == params.treeNodeDirtyIds.end()) {
          // If the component is not dirty and it doesn't have a dirty parent - we can reuse it.
          if (!hasDirtyParent) {
            if (config.enableFasterStateUpdates) {
              // Faster state update optimizations.
              reusePreviousComponent(self, node, parent, previousParent);
              return;
            }
          } // If the component is not dirty, but its parent is dirty - we handle it as props update.
          else if (config.enableFasterPropsUpdates &&
                   reusePreviousComponentIfComponentsAreEqual(self, node, parent, previousParent)) {
            return;
          }
        }
        else { // If the component is dirty, we mark it with `hasDirtyParent` param for its children.
          hasDirtyParent = YES;
        }
      }
    }
    else if (params.buildTrigger == BuildTrigger::PropsUpdate) {
      // Faster props update optimizations.
      if (config.enableFasterPropsUpdates &&
          reusePreviousComponentIfComponentsAreEqual(self, node, parent, previousParent)) {
        return;
      }
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

// Reuse the previous component generation and its component tree.
static void reusePreviousComponent(CKRenderComponent *component,
                                   CKRenderTreeNodeWithChild *node,
                                   id<CKTreeNodeWithChildrenProtocol> parent,
                                   id<CKTreeNodeWithChildrenProtocol> previousParent) {
  auto const componentKey = node.componentKey;
  auto const previousChild = [previousParent childForComponentKey:componentKey];
  // Link the previous child to the new parent.
  [parent setChild:previousChild forComponentKey:componentKey];
  // Link the previous child component to the the new component.
  component->_childComponent = [(CKRenderTreeNodeWithChild *)previousChild child].component;
}

// Check if isEqualToComponent returns `YES`; if it does, reuse the previous component generation and its component tree.
static BOOL reusePreviousComponentIfComponentsAreEqual(CKRenderComponent *component,
                                                       CKRenderTreeNodeWithChild *node,
                                                       id<CKTreeNodeWithChildrenProtocol> parent,
                                                       id<CKTreeNodeWithChildrenProtocol> previousParent) {
  auto const componentKey = node.componentKey;
  auto const previousChild = [previousParent childForComponentKey:componentKey];
  if ([component isEqualToComponent:(id<CKRenderComponentProtocol>)previousChild.component]) {
    // Link the previous child to the new parent.
    [parent setChild:previousChild forComponentKey:componentKey];
    // Link the previous child component to the the new component.
    component->_childComponent = [(CKRenderTreeNodeWithChild *)previousChild child].component;
    return YES;
  }
  return NO;
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

- (BOOL)isEqualToComponent:(id<CKRenderComponentProtocol>)component
{
  return NO;
}

@end
