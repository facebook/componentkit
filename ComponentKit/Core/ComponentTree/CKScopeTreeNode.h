/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKScopeTreeNodeProtocol.h>

#import "CKTreeNode.h"

@protocol CKTreeNodeProtocol;

/**
 This object is a bridge between CKComponentScope and CKTreeNode.

 It represents a node with children in the component tree.
 */
@interface CKScopeTreeNode : CKTreeNode <CKScopeTreeNodeProtocol>
{
  @package
  std::vector<std::tuple<CKScopeNodeKey, id<CKTreeNodeProtocol>>> _children;
}
@end
