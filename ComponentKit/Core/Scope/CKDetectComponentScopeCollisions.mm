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
                                                          NSMapTable<CKComponent *, CKComponent *> *componentsToParentComponents)
{
  NSMutableArray<CKComponent *> *componentBacktrace = [NSMutableArray arrayWithObject:component];
  CKComponent *parentComponent = [componentsToParentComponents objectForKey:component];
  while (parentComponent) {
    [componentBacktrace addObject:parentComponent];
    parentComponent = [componentsToParentComponents objectForKey:parentComponent];
  }
  return componentBacktrace;
}
#pragma clang diagnostic pop

static CKComponent *completeComponentScopeCollisionPair(CKComponent *collidingComponent,
                                                        id<NSObject> collidingScope,
                                                        NSMapTable<CKComponent *, CKComponent *> *componentsToParentComponents)
{
  for (CKComponent *componentKey in componentsToParentComponents) {
    const id<NSObject> scopeFrameToken = [componentKey scopeFrameToken];
    if ([collidingScope isEqual:scopeFrameToken] && ![collidingComponent isEqual:componentKey]) {
      return componentKey;
    }
  }
  return nil;
}

static CKComponent *lowestCommonAncestor(CKComponent *component,
                                         id<NSObject> collisionScope,
                                         NSMapTable<CKComponent *, CKComponent *> *componentsToParentComponents)
{
  // First we need to find the node we're having a collision with.
  CKComponent *collidingComponent = completeComponentScopeCollisionPair(component, collisionScope, componentsToParentComponents);
  if (collidingComponent && component) {
    NSMutableSet<CKComponent *> *const previouslySeenParentsComponent = [NSMutableSet setWithObjects:component, collidingComponent, nil];
    // Walking up the both paths until we find the same parent
    while (collidingComponent || component) {
      component = [componentsToParentComponents objectForKey:component];
      if ([previouslySeenParentsComponent containsObject:component]) {
        return component;
      }
      if (component) {
        [previouslySeenParentsComponent addObject:component];
      }
      collidingComponent = [componentsToParentComponents objectForKey:collidingComponent];
      if ([previouslySeenParentsComponent containsObject:collidingComponent]) {
        return collidingComponent;
      }
      if (collidingComponent) {
        [previouslySeenParentsComponent addObject:collidingComponent];
      }
    }
  }
  return nil;
}

CKComponentCollision CKFindComponentScopeCollision(const CKComponentLayout &layout)
{
  std::queue<const CKComponentLayout> queue;
  NSMutableSet<id<NSObject>> *const previouslySeenScopeFrameTokens = [NSMutableSet new];
  NSMapTable<CKComponent *, CKComponent *> *const componentsToParentComponents = [NSMapTable strongToStrongObjectsMapTable];
  queue.push(layout);
  while (!queue.empty()) {
    const auto componentLayout = queue.front();
    queue.pop();
    CKComponent *const component = componentLayout.component;
    const id<NSObject> scopeFrameToken = [component scopeFrameToken];
    if (scopeFrameToken && [previouslySeenScopeFrameTokens containsObject:scopeFrameToken]) {
      return {
        .component = component,
        .lowestCommonAncestor = lowestCommonAncestor(component,scopeFrameToken,componentsToParentComponents),
        .backtraceDescription = CKComponentBacktraceDescription(generateComponentBacktrace(component, componentsToParentComponents)),
      };
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
  return {};
}

void CKDetectComponentScopeCollisions(const CKComponentLayout &layout) {
#if CK_ASSERTIONS_ENABLED
  const CKComponentCollision collision = CKFindComponentScopeCollision(layout);
  CKComponent *const lowestCommonAncestor = collision.lowestCommonAncestor ?: layout.component;
  if (collision.hasCollision()) {
    CKCFailAssert(@"Scope collision. Attempting to create duplicate scope for %@\nLowest common ancestor: <%@: %p>\nComponent backtrace:\n%@",
                  [collision.component class],
                  lowestCommonAncestor,
                  lowestCommonAncestor,
                  collision.backtraceDescription);
  }
#endif
}
