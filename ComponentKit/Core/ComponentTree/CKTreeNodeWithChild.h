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

/**
 This object represents a node with a single child in the component tree.

 Each component with a single child will have CKTreeNodeWithChild.
 */

@interface CKTreeNodeWithChild : CKTreeNode <CKTreeNodeWithChildrenProtocol>

@property (nonatomic, strong) id<CKTreeNodeProtocol> child;

@end
