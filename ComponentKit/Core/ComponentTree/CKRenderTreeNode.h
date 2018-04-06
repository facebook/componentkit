/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKTreeNode.h"

/**
 This object represents a render component node in the component tree.
 It will be attached to render components only (id<CKRenderComponentProtocol>).

 For more information about an render components see: CKRenderComponentProtocol.h
 */
@interface CKRenderTreeNode: CKTreeNode

@end
