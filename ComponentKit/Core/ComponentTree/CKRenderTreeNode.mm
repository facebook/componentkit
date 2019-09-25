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
- (instancetype)initWithPreviousNode:(id<CKTreeNodeProtocol>)previousNode
                         scopeHandle:(CKComponentScopeHandle *)scopeHandle
{
  if (self = [super initWithPreviousNode:previousNode scopeHandle:scopeHandle]) {
    auto const threadLocalScope = CKThreadLocalComponentScope::currentScope();
    if (threadLocalScope != nullptr) {
      CKAssert(previousNode == nil || [previousNode conformsToProtocol:@protocol(CKScopeTreeNodeProtocol)], @"previousNode should conform to id<CKScopeTreeNodeProtocol>, but its class %@ does not.", previousNode.class);
      // Push the new pair into the thread local.
      threadLocalScope->stack.push({.frame = self, .previousFrame = (id<CKScopeTreeNodeProtocol>)previousNode});
    }
  }
  return self;
}

+ (void)didBuildComponentTreeWithNode:(id<CKTreeNodeProtocol>)node
{
  auto const threadLocalScope = CKThreadLocalComponentScope::currentScope();
  if (threadLocalScope == nullptr) {
    return;
  }

  CKAssert(!threadLocalScope->stack.empty() && threadLocalScope->stack.top().frame == (id<CKComponentScopeFrameProtocol>)node, @"top.frame (%@) is not equal to node (%@)", threadLocalScope->stack.top().frame, node);

  // Pop the top element of the stack.
  threadLocalScope->stack.pop();
}

- (void)didReuseNode:(CKRenderTreeNode *)node
{
  // Transfer the children vector from the reused node.
  _children = node->_children;

  [CKRenderTreeNode didBuildComponentTreeWithNode:self];
}

@end
