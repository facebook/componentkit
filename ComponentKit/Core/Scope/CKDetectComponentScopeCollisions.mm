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

void CKDetectComponentScopeCollisions(const CKComponentLayout &layout)
{
#if DEBUG
  std::queue<const CKComponentLayout> queue;
  NSMutableSet<id<NSObject>> *previouslySeenScopeFrameTokens = [NSMutableSet new];
  queue.push(layout);
  while (!queue.empty()) {
    auto currentLayout = queue.front();
    queue.pop();
    id<NSObject> scopeFrameToken = [currentLayout.component scopeFrameToken];
    if (scopeFrameToken && [previouslySeenScopeFrameTokens containsObject:scopeFrameToken]) {
      CKCFailAssert(@"Scope collision. Attempting to create duplicate scope for component %@", [currentLayout.component class]);
    }
    if (scopeFrameToken) {
      [previouslySeenScopeFrameTokens addObject:scopeFrameToken];
    }
    if (currentLayout.children) {
      for (auto child : *currentLayout.children) {
        queue.push(child.layout);
      }
    }
  }
#endif
}
