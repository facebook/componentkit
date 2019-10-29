/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKScopeTreeNode.h"

/**
 This object is a bridge between CKComponentScope and CKTreeNode.

 It represents a node for single child node in the component tree.
 */
@interface CKScopeTreeNodeWithChild : CKScopeTreeNode <CKTreeNodeWithChildProtocol>
{
  @package
  // When this feature is enabled, this class is not in use anymore as any node might have multiple children.
  BOOL _renderOnlyTreeNodes;
}
@property (nonatomic, strong) id<CKTreeNodeProtocol> child;
@end

