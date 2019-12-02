/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKRootTreeNode.h"

#import "CKRenderHelpers.h"
#import "CKScopeTreeNode.h"

CKRootTreeNode::CKRootTreeNode(): _node([CKScopeTreeNode new]) {};

void CKRootTreeNode::registerNode(id<CKTreeNodeProtocol> node, id<CKTreeNodeProtocol> parent) {
  CKCAssert(parent != nil, @"Cannot register a nil parent node");
  if (node) {
    _nodesToParentNodes[node.nodeIdentifier] = parent;
  }
}

id<CKTreeNodeProtocol> CKRootTreeNode::parentForNodeIdentifier(CKTreeNodeIdentifier nodeIdentifier) {
  CKCAssert(nodeIdentifier != 0, @"Cannot retrieve parent for an empty node");
  auto const it = _nodesToParentNodes.find(nodeIdentifier);
  if (it != _nodesToParentNodes.end()) {
    return it->second;
  }
  return nil;
}

bool CKRootTreeNode::isEmpty() {
  return _node.childrenSize == 0;
}

id<CKScopeTreeNodeProtocol> CKRootTreeNode::node() {
  return _node;
}

const CKTreeNodeDirtyIds& CKRootTreeNode::dirtyNodeIdsForPropsUpdates() const {
  return _dirtyNodeIdsForPropsUpdates;
}

void CKRootTreeNode::markTopRenderComponentAsDirtyForPropsUpdates() {
  while (!_stack.empty()) {
    auto nodeIdentifier = _stack.top();
    _dirtyNodeIdsForPropsUpdates.insert(nodeIdentifier);
    _stack.pop();
  }
}

void CKRootTreeNode::willBuildComponentTree(id<CKTreeNodeProtocol>node) {
  _stack.push(node.nodeIdentifier);
}

void CKRootTreeNode::didBuildComponentTree(id<CKTreeNodeProtocol>node) {
  if (!_stack.empty()) {
    _stack.pop();
  }
}
