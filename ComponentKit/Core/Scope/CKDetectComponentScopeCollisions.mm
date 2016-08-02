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

static NSString *componentBacktraceDescription(NSArray<CKComponent *> *componentBacktrace)
{
  NSMutableString *const description = [NSMutableString string];
  [componentBacktrace enumerateObjectsWithOptions:NSEnumerationReverse
                                       usingBlock:^(CKComponent * _Nonnull component, NSUInteger index, BOOL * _Nonnull stop) {
                                         const NSInteger depth = componentBacktrace.count - index - 1;
                                         if (depth != 0) {
                                           [description appendString:@"\n"];
                                         }
                                         [description appendString:[@"" stringByPaddingToLength:depth withString:@" " startingAtIndex:0]];
                                         [description appendString:NSStringFromClass([component class])];
                                         [description appendString:@": "];
                                         [description appendString:[component description]];
                                       }];
  return description;
}
#pragma clang diagnostic pop

void CKDetectComponentScopeCollisions(const CKComponentLayout &layout)
{
#if CK_ASSERTIONS_ENABLED
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
      CKCFailAssert(@"Scope collision. Attempting to create duplicate scope for component: %@\n%@",
                    [component class],
                    componentBacktraceDescription(generateComponentBacktrace(component, componentsToParentComponents)));
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
#endif
}
