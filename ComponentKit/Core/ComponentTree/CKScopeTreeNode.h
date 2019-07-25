/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKTreeNode.h>
#import <ComponentKit/CKTreeNodeProtocol.h>
#import <ComponentKit/CKComponentScopeFrame.h>

/**
 This object is a bridge between CKComponentScope and CKTreeNode.

 It represents a node with children in the component tree.
 Each non-render component with CKComponentScope will have this node.
 */
@interface CKScopeTreeNode : CKTreeNode <CKTreeNodeWithChildrenProtocol, CKComponentScopeFrameProtocol>

@end
