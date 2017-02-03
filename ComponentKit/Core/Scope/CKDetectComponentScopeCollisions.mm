/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKDetectComponentScopeCollisions.h"

#import <queue>

#import "CKAssert.h"
#import "CKComponentBacktraceDescription.h"
#import "CKComponentInternal.h"


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-function"
static NSArray<CKComponent *> *generateComponentBacktrace(CKComponent *component,
                                                          NSMapTable<CKComponent *, CKComponent*> *componentsToParentComponents)
{
  NSMutableArray<CKComponent *> *componentBacktrace = [NSMutableArray arrayWithObject:component];
  CKComponent *parentComponent = [componentsToParentComponents objectForKey:component];
  while (parentComponent) {
    [componentBacktrace addObject:parentComponent];
    parentComponent = [componentsToParentComponents objectForKey:parentComponent];
  }
  return componentBacktrace;
}
//#pragma clang diagnostic pop

static CKComponent * findCollisionComponent(CKComponent *component,
                                            id<NSObject> collisionScope,
                                            NSMapTable<CKComponent *, CKComponent*> *componentsToParentComponents)
{
  for(CKComponent* componentKey in componentsToParentComponents){
    const id<NSObject> scopeFrameToken = [componentKey scopeFrameToken];
    // The colission node has the same scopeToken but it's not this node.
    if([collisionScope isEqual:scopeFrameToken] && ![component isEqual:componentKey]){
      return componentKey;
    }
  }
  return nil;
}

NSUInteger heightOfComponent(CKComponent *component,
                             NSMapTable<CKComponent *, CKComponent*> *componentsToParentComponents)
{
  NSUInteger heightOnTree = 0;
  CKComponent *parentComponent = [componentsToParentComponents objectForKey:component];
  while (parentComponent) {
    parentComponent = [componentsToParentComponents objectForKey:parentComponent];
    heightOnTree += 1;
  }
  return heightOnTree;
}

static CKComponent* lowestCommonAncestor(CKComponent *component,
                                         id<NSObject> collisionScope,
                                         NSMapTable<CKComponent *, CKComponent*> *componentsToParentComponents)
{
  // First we need to find the node we're having a collision with.
  CKComponent *component2 = findCollisionComponent(component, collisionScope, componentsToParentComponents);
  
  // Then we find the How deep each node is
  NSUInteger heightNode1 = heightOfComponent(component, componentsToParentComponents);
  NSUInteger heightNode2 = heightOfComponent(component2, componentsToParentComponents);
  
  if (heightNode1 > heightNode2) {
    std::swap(heightNode1, heightNode2);
    std::swap(component, component2);
  }
  
  // Just making sure both paths start from the same deep level
  while (heightNode1 < heightNode2) {
    if (!component2)
      return nil;
    component2 = [componentsToParentComponents objectForKey:component2];
    heightNode2 -= 1;
  }
  
  // Just comparing the paths until we find the lowest common ancestor
  while (component && component2) {
    if (component == component2)
      return component;
    component = [componentsToParentComponents objectForKey:component];
    component2 = [componentsToParentComponents objectForKey:component2];
  }
  
  return nil;
}

CKComponentCollision CKReturnComponentScopeCollision(const CKComponentLayout &layout)
{
  std::queue<const CKComponentLayout> queue;
  NSMutableSet<id<NSObject>> *const previouslySeenScopeFrameTokens = [NSMutableSet new];
  NSMapTable<CKComponent *, CKComponent*> *const componentsToParentComponents = [NSMapTable strongToStrongObjectsMapTable];
  queue.push(layout);
  while (!queue.empty()) {
    const auto componentLayout = queue.front();
    queue.pop();
    CKComponent *const component = componentLayout.component;
    const id<NSObject> scopeFrameToken = [component scopeFrameToken];
    if (scopeFrameToken && [previouslySeenScopeFrameTokens containsObject:scopeFrameToken]) {
       return {component,
         lowestCommonAncestor(component,scopeFrameToken,componentsToParentComponents),
         CKComponentBacktraceDescription(generateComponentBacktrace(component, componentsToParentComponents))};
    }
    if (scopeFrameToken) {
      [previouslySeenScopeFrameTokens addObject:scopeFrameToken];
    }
    if (componentLayout.children) {
      for (const auto childComponentLayout : *componentLayout.children) {
        queue.push(childComponentLayout.layout);
        [componentsToParentComponents setObject:componentLayout.component forKey:childComponentLayout.layout.component];
      }
    }
  }
  return CKComponentCollision();
}

void CKDetectComponentScopeCollisions(const CKComponentLayout &layout) {
#if CK_ASSERTIONS_ENABLED
  CKComponentCollision collision = CKReturnComponentScopeCollision(layout);
  if (collision.hasCollision()) {
    CKCFailAssert(@"Scope collision. Attempting to create duplicate scope for component: %@ with lca: %@\n%@",
                  [collision.component class],
                  collision.lowestCommonAncestor ? [collision.lowestCommonAncestor class] : [layout.component class],
                  collision.backtraceString);
  }
#endif
}
