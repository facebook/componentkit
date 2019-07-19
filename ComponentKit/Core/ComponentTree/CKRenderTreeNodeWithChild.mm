/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKRenderTreeNodeWithChild.h"
#import "CKRenderComponentProtocol.h"

@implementation CKRenderTreeNodeWithChild

- (instancetype)initWithComponent:(id<CKRenderComponentProtocol>)component
                           parent:(id<CKTreeNodeWithChildrenProtocol>)parent
                   previousParent:(id<CKTreeNodeWithChildrenProtocol>)previousParent
                        scopeRoot:(CKComponentScopeRoot *)scopeRoot
                     stateUpdates:(const CKComponentStateUpdateMap &)stateUpdates
{
  return [super initWithRenderComponent:component
                                 parent:parent
                         previousParent:previousParent
                              scopeRoot:scopeRoot
                           stateUpdates:stateUpdates];
}

@end

