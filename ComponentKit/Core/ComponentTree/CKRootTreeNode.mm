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

#import <ComponentKit/CKAssert.h>

#import "CKRenderHelpers.h"
#import "CKScopeTreeNode.h"

CKRootTreeNode::CKRootTreeNode(): _node([CKScopeTreeNode new]) {};

#if CK_ASSERTIONS_ENABLED
static auto _parentIdentifiers(const std::unordered_map<CKTreeNodeIdentifier,
                               id<CKTreeNodeProtocol>>& nodesToParentNodes,
                               id<CKTreeNodeProtocol> node) -> NSString * {
  const auto parents = [NSMutableArray new];

  while (node.component != nil) {
    [parents addObject:node.component.className];
    const auto it = nodesToParentNodes.find(node.nodeIdentifier);
    node = (it != nodesToParentNodes.cend()) ? it->second : nil;
  }

  return [[[parents reverseObjectEnumerator] allObjects] componentsJoinedByString:@"-"];
}

static auto _existingAndNewParentIdentifiers(
    const std::unordered_map<CKTreeNodeIdentifier,
    id<CKTreeNodeProtocol>>& nodesToParentNodes,
    id<CKTreeNodeProtocol> node,
    id<CKTreeNodeProtocol> parent) -> NSString * {
  return [NSString stringWithFormat:@"Previous Parents:%@\nNew Parents:%@",
          _parentIdentifiers(nodesToParentNodes, nodesToParentNodes.find(node.nodeIdentifier)->second),
          _parentIdentifiers(nodesToParentNodes, parent)];
}

#endif

void CKRootTreeNode::registerNode(id<CKTreeNodeProtocol> node, id<CKTreeNodeProtocol> parent) noexcept {
  CKCAssert(parent != nil, @"Cannot register a nil parent node");
  if (node) {
#if CK_ASSERTIONS_ENABLED
    const auto registeredParent = _nodesToParentNodes.find(node.nodeIdentifier);
    if (registeredParent != _nodesToParentNodes.cend()) {
      const auto parentComponentTreeDescription =
        _existingAndNewParentIdentifiers(_nodesToParentNodes, node, parent);
      if (registeredParent->second.nodeIdentifier == parent.nodeIdentifier) {
        // Suggests non optimal tree build/reuse logic.
        CKCFailAssertWithCategory(node.component.className,
                                  @"Duplicate parent registration.\n%@",
                                  parentComponentTreeDescription);
      } else {
        // Suggests same component instance is used in two subtrees or reuse error.
        CKCFailAssertWithCategory(node.component.className,
                                  @"Distinct parent registration (current: %ld - new: %ld).\n%@",
                                  (long)registeredParent->second.nodeIdentifier,
                                  (long)parent.nodeIdentifier,
                                  parentComponentTreeDescription);
      }
    }
#endif
    _nodesToParentNodes[node.nodeIdentifier] = parent;
  }
}

id<CKTreeNodeProtocol> CKRootTreeNode::parentForNodeIdentifier(CKTreeNodeIdentifier nodeIdentifier) const {
  CKCAssert(nodeIdentifier != 0, @"Cannot retrieve parent for an empty node");
  auto const it = _nodesToParentNodes.find(nodeIdentifier);
  if (it != _nodesToParentNodes.end()) {
    return it->second;
  }
  return nil;
}

bool CKRootTreeNode::isEmpty() const {
  return _node.childrenSize == 0;
}

CKScopeTreeNode *CKRootTreeNode::node() const {
  return _node;
}

const CKTreeNodeDirtyIds& CKRootTreeNode::dirtyNodeIdsForPropsUpdates() const {
  return _dirtyNodeIdsForPropsUpdates;
}

void CKRootTreeNode::markTopRenderComponentAsDirtyForPropsUpdates() noexcept {
  while (!_stack.empty()) {
    auto nodeIdentifier = _stack.top();
    _dirtyNodeIdsForPropsUpdates.insert(nodeIdentifier);
    _stack.pop();
  }
}

void CKRootTreeNode::willBuildComponentTree(id<CKTreeNodeProtocol>node) noexcept {
  _stack.push(node.nodeIdentifier);
}

void CKRootTreeNode::didBuildComponentTree() noexcept {
  if (!_stack.empty()) {
    _stack.pop();
  }
}
