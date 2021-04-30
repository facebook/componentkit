/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKDetectDuplicateComponent.h"

#import <queue>

#import <ComponentKit/CKAssert.h>
#import <ComponentKit/CKMountable.h>
#import <ComponentKit/CKComponentDescriptionHelper.h>
#import <ComponentKit/CKComponentInternal.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-function"
static NSArray<id<CKMountable>> *generateComponentBacktrace(id<CKMountable> component,
                                                          NSMapTable<id<CKMountable>, id<CKMountable>> *componentsToParentComponents)
{
  NSMutableArray<id<CKMountable>> *componentBacktrace = [NSMutableArray arrayWithObject:component];
  auto parentComponent = [componentsToParentComponents objectForKey:component];
  while (parentComponent) {
    [componentBacktrace addObject:parentComponent];
    parentComponent = [componentsToParentComponents objectForKey:parentComponent];
  }
  return componentBacktrace;
}

CKDuplicateComponentInfo CKFindDuplicateComponent(const CKComponentLayout &layout)
{
  std::queue<const CKComponentLayout> queue;
  NSMutableSet<id<NSObject>> *const previouslySeenComponent = [NSMutableSet new];
  NSMapTable<id<CKMountable>, id<CKMountable>> *const componentsToParentComponents = [NSMapTable strongToStrongObjectsMapTable];
  queue.push(layout);
  while (!queue.empty()) {
    const auto componentLayout = queue.front();
    queue.pop();
    auto const component = componentLayout.component;
    if (component && [previouslySeenComponent containsObject:component]) {
      return {
        .component = component,
        .backtraceDescription = CKComponentBacktraceDescription(generateComponentBacktrace(component, componentsToParentComponents)),
      };
    }
    if (component) {
      [previouslySeenComponent addObject:component];
    }
    if (componentLayout.children) {
      for (auto childComponentLayout : *componentLayout.children) {
        queue.push(childComponentLayout.layout);
        [componentsToParentComponents setObject:componentLayout.component forKey:childComponentLayout.layout.component];
      }
    }
  }
  return {};
}

void CKDetectDuplicateComponent(const CKComponentLayout &layout) {
#if CK_ASSERTIONS_ENABLED
  auto const info = CKFindDuplicateComponent(layout);
  if (info.component) {
    CKCFailAssertWithCategory(CKComponentCompactDescription(info.component),
                              @"Duplicate component in the tree. Attempting to use %@ more than once in the component tree can lead to an incorrect and unexpected behavior\n"
                              @"Please make sure to create another instance of %@ if needed. \nComponent backtrace:\n%@",
                              [info.component class],
                              [info.component class],
                              info.backtraceDescription);
  }
#endif
}

#pragma clang diagnostic pop
