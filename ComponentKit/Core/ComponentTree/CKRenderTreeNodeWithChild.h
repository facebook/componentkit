/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKTreeNodeWithChild.h"
#import "CKTreeNodeProtocol.h"

/**
 This object represents a node with a single child in the component tree.

 Each CKRenderComponent will have a corresponding CKRenderTreeNodeWithChild (when we use parent based component key).
 */

@interface CKRenderTreeNodeWithChild : CKTreeNodeWithChild

@end
