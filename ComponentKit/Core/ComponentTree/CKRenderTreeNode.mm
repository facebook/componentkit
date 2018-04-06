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

#import "CKRenderComponentProtocol.h"

@implementation CKRenderTreeNode

- (id)initialStateWithComponent:(id<CKRenderComponentProtocol>)component
{
  return [[component class] initialStateWithComponent:component];
}

@end
