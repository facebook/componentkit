/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <Foundation/Foundation.h>

#import <ComponentKit/CKTreeNodeProtocol.h>
#import <ComponentKit/CKTreeNodeTypes.h>

class CKRootTreeNode {
public:
  CKRootTreeNode();
  
  void registerNode(id<CKTreeNodeProtocol> node, id<CKTreeNodeProtocol> parent);
  /** Query the parent node of existing node*/
  id<CKTreeNodeProtocol> parentForNodeIdentifier(CKTreeNodeIdentifier nodeIdentifier);

  /** Returns whether the node has children or not */
  bool isEmpty();

  /** access the internal node */
  id<CKTreeNodeWithChildrenProtocol> node();

private:
  /** the root node of the component tree */
  id<CKTreeNodeWithChildrenProtocol> _node;
  /** A map between a tree node identifier to its parent node. */
  std::unordered_map<CKTreeNodeIdentifier, id<CKTreeNodeProtocol>> _nodesToParentNodes;
};
