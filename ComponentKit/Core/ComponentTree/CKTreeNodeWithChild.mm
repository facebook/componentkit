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

#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKComponentInternal.h>

#include <tuple>

@implementation CKTreeNodeWithChild
{
  CKTreeNode *_child;
}

- (std::vector<id<CKTreeNodeProtocol>>)children
{
  return {_child};
}

- (CKTreeNode *)childForComponentKey:(const CKComponentKey &)key
{
  CKAssert(std::get<0>(key) == [_child.component class], @"CKComponentKey(%@, %ld) contains incorrect class(%@) type.",
           std::get<0>(key),
           (unsigned long)std::get<1>(key),
           [_child.component class]);
  return _child;
}

- (CKComponentKey)createComponentKeyForChildWithClass:(id<CKComponentProtocol>)componentClass
{
  return std::make_tuple(componentClass, 0);
}

- (void)setChild:(CKTreeNode *)child forComponentKey:(const CKComponentKey &)componentKey
{
  CKAssert(_child == nil, @"_child shouldn't set more than once.");
  _child = child;
}

@end
