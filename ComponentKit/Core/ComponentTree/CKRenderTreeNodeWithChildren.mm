/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKRenderTreeNodeWithChildren.h"
#import "CKRenderComponentProtocol.h"

@implementation CKRenderTreeNodeWithChildren

- (id)initialStateWithComponent:(id<CKRenderComponentProtocol>)component
{
  return [[component class] initialStateWithComponent:component];
}

- (BOOL)componentRequiresScopeHandle:(Class<CKTreeNodeComponentProtocol>)componentClass
{
  return [componentClass requiresScopeHandle];
}

- (CKTreeNodeComponentKey)createComponentKeyForComponent:(id<CKRenderComponentProtocol>)component
                                                  parent:(id<CKTreeNodeWithChildrenProtocol>)parent
                                          componentClass:(Class<CKTreeNodeComponentProtocol>)componentClass
{
  return [parent createComponentKeyForChildWithClass:componentClass identifier:[component componentIdentifier]];
}

@end

