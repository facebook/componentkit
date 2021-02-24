/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKRenderTreeNode.h"

#import <ComponentKit/CKThreadLocalComponentScope.h>

@implementation CKRenderTreeNode

// Base initializer
- (instancetype)initWithPreviousNode:(CKTreeNode *)previousNode
                         scopeHandle:(CKComponentScopeHandle *)scopeHandle
{
  if (self = [super initWithPreviousNode:previousNode scopeHandle:scopeHandle]) {
    auto const threadLocalScope = CKThreadLocalComponentScope::currentScope();
    if (threadLocalScope != nullptr) {
      // Push the new pair into the thread local.
      threadLocalScope->push({.node = self, .previousNode = previousNode});
    }
  }
  return self;
}

+ (void)didBuildComponentTree:(CKTreeNode *)node
{
  auto const threadLocalScope = CKThreadLocalComponentScope::currentScope();
  if (threadLocalScope == nullptr) {
    return;
  }

  RCAssert(!threadLocalScope->stack.empty() && threadLocalScope->stack.top().node == node, @"top.node (%@) is not equal to node (%@)", threadLocalScope->stack.top().node, node);

  // Pop the top element of the stack.
  threadLocalScope->pop();
}

@end
