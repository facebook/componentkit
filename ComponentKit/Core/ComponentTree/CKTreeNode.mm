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

#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKComponentInternal.h>

#include <tuple>

#import "CKMutex.h"

struct CKTreeNodeComparator {
  bool operator() (const CKComponentKey &lhs, const CKComponentKey &rhs) const
  {
    return std::get<0>(lhs) == std::get<0>(rhs) && std::get<1>(lhs) == std::get<1>(rhs);
  }
};

struct CKTreeNodeHasher {
  std::size_t operator() (const CKComponentKey &n) const
  {
    return [std::get<0>(n) hash] ^ std::get<1>(n);
  }
};

typedef std::unordered_map<CKComponentKey, CKBaseTreeNode *, CKTreeNodeHasher, CKTreeNodeComparator> CKScopeNodeMap;

@implementation CKTreeNode
{
  CKScopeNodeMap _children;
  std::unordered_map<Class, NSUInteger> _classTypeIdentifier;
}

- (std::vector<CKComponent *>)children
{
  return CK::map(_children, [](const auto &n) {
    return n.second.component;
  });
}

- (CKBaseTreeNode *)childForComponentKey:(const CKComponentKey &)key
{
  return _children[key];
}

- (CKComponentKey)createComponentKeyForChildWithClass:(id<CKComponentProtocol>)componentClass
{
  return std::make_tuple(componentClass, _classTypeIdentifier[componentClass]++);
}

- (void)setChild:(CKBaseTreeNode*)child forComponentKey:(const CKComponentKey &)componentKey
{
  _children[componentKey] = child;
}

@end
