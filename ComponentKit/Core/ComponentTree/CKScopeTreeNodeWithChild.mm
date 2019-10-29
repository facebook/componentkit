/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKScopeTreeNodeWithChild.h"

#import <ComponentKit/CKThreadLocalComponentScope.h>

@implementation CKScopeTreeNodeWithChild

- (size_t)childrenSize
{
  if (_renderOnlyTreeNodes) {
    return [super childrenSize];
  }
  return [super childrenSize] + (_child ? 1 : 0);
}

- (std::vector<id<CKTreeNodeProtocol>>)children
{
  if (_renderOnlyTreeNodes) {
    return [super children];
  }
  return {_child};
}

- (id<CKTreeNodeProtocol>)childForComponentKey:(const CKTreeNodeComponentKey &)key
{
  if (_renderOnlyTreeNodes) {
    return [super childForComponentKey:key];
  }
  if (std::get<0>(key) == [_child.component class]) {
    return _child;
  }
  return nil;
}

- (CKTreeNodeComponentKey)createComponentKeyForChildWithClass:(id<CKComponentProtocol>)componentClass
                                                   identifier:(id<NSObject>)identifier
{
  if (_renderOnlyTreeNodes) {
    return [super createComponentKeyForChildWithClass:componentClass identifier:identifier];
  }
  return std::make_tuple(componentClass, 0, identifier);
}

- (void)setChild:(id<CKTreeNodeProtocol>)child forComponentKey:(const CKTreeNodeComponentKey &)componentKey
{
  CKAssert(_child == nil || [_child class] == [child class], @"[_child class]: %@ is different than [child class]: %@", [_child class], [child class]);
  if (_renderOnlyTreeNodes) {
    [super setChild:child forComponentKey:componentKey];
  } else {
    _child = child;
  }
}

- (void)didReuseInScopeRoot:(CKComponentScopeRoot *)scopeRoot fromPreviousScopeRoot:(CKComponentScopeRoot *)previousScopeRoot
{
  [super didReuseInScopeRoot:scopeRoot fromPreviousScopeRoot:previousScopeRoot];
  [_child didReuseInScopeRoot:scopeRoot fromPreviousScopeRoot:previousScopeRoot];
}

@end
