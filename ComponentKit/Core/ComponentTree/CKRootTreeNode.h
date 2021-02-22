/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKDefines.h>

#if CK_NOT_SWIFT

#import <Foundation/Foundation.h>

#import <ComponentKit/CKTreeNode.h>
#import <ComponentKit/CKTreeNodeTypes.h>
#import <ComponentKit/CKTreeNode.h>

#import <stack>

class CKRootTreeNode {
public:
  CKRootTreeNode();

  void registerNode(CKTreeNode *node, CKTreeNode *parent) noexcept;
  /** Query the parent node of existing node*/
  CKTreeNode *parentForNodeIdentifier(CKTreeNodeIdentifier nodeIdentifier) const;

  /** Returns whether the node has children or not */
  bool isEmpty() const;

  /** access the internal node */
  CKTreeNode *node() const;

  /** Mark the top render component in the stack as dirty */
  void markTopRenderComponentAsDirtyForPropsUpdates() noexcept;

  /** Return the dirty node ids, of the nodes that cannot participate in props updates optimizations. */
  const CKTreeNodeDirtyIds& dirtyNodeIdsForPropsUpdates() const;

  /** Called before a render component generates its children */
  void willBuildComponentTree(CKTreeNode *node) noexcept;

  /** Called after a render component generates its children */
  void didBuildComponentTree() noexcept;

private:
  /** the root node of the component tree */
  CKTreeNode *_node;
  /** A map between a tree node identifier to its parent node. */
  std::unordered_map<CKTreeNodeIdentifier, CKTreeNode *> _nodesToParentNodes;
  /**
   A set of the dirty node ids, which will be used in the NEXT component generation during props updates.
   Dirty node id, in the context of props update means that a component cannot be reused with `shouldComponentUpdate: method.
   */
  CKTreeNodeDirtyIds _dirtyNodeIdsForPropsUpdates;
  /** A stack of all the existing render components' nodes that are being created in a given point */
  std::stack<CKTreeNodeIdentifier> _stack;
};

#endif
