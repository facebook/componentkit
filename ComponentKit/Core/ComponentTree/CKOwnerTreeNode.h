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
#import "CKTreeNodeProtocol.h"

/**
 This object represents an owner node (has children) in the component tree.

 Each component that is an owner component will have a corresponding CKOwnerTreeNode.
 */

@interface CKOwnerTreeNode : CKRenderTreeNode <CKOwnerTreeNodeProtocol>

- (void)reset;

@end
