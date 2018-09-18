/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKTreeNodeWithChildren.h"

#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKComponentInternal.h>

#include <tuple>

#import "CKMutex.h"

struct CKTreeNodeComparator {
  bool operator() (const CKTreeNodeComponentKey &lhs, const CKTreeNodeComponentKey &rhs) const
  {
    return std::get<0>(lhs) == std::get<0>(rhs) && std::get<1>(lhs) == std::get<1>(rhs);
  }
};

struct CKTreeNodeHasher {
  std::size_t operator() (const CKTreeNodeComponentKey &n) const
  {
    return [std::get<0>(n) hash] ^ std::get<1>(n);
  }
};

typedef std::unordered_map<CKTreeNodeComponentKey, CKTreeNode *, CKTreeNodeHasher, CKTreeNodeComparator> CKScopeNodeMap;

@implementation CKTreeNodeWithChildren
{
  CKScopeNodeMap _children;
  std::unordered_map<Class, NSUInteger> _classTypeIdentifier;
}

- (std::vector<id<CKTreeNodeProtocol>>)children
{
  std::vector<id<CKTreeNodeProtocol>> children;
  for (auto const &child : _children) {
    children.push_back(child.second);
  }
  return children;
}

- (size_t)childrenSize
{
  return _children.size();
}

- (CKTreeNode *)childForComponentKey:(const CKTreeNodeComponentKey &)key
{
  return _children[key];
}

- (CKTreeNodeComponentKey)createComponentKeyForChildWithClass:(id<CKComponentProtocol>)componentClass
{
  return std::make_tuple(componentClass, _classTypeIdentifier[componentClass]++);
}

- (void)setChild:(CKTreeNode *)child forComponentKey:(const CKTreeNodeComponentKey &)componentKey
{
  _children[componentKey] = child;
}

@end
