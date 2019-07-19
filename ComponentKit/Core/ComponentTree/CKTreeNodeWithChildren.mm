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
#import <ComponentKit/CKEqualityHashHelpers.h>

#include <tuple>

#import "CKMutex.h"

typedef std::tuple<Class, id<NSObject>> CKTreeNodeClassType;

struct CKClassTypeComparator {
  bool operator() (const CKTreeNodeClassType &lhs, const CKTreeNodeClassType &rhs) const
  {
    return std::get<0>(lhs) == std::get<0>(rhs) && CKObjectIsEqual(std::get<1>(lhs), std::get<1>(rhs));
  }
};

struct CKClassTypeHasher {
  std::size_t operator() (const CKTreeNodeClassType &n) const
  {
    return [std::get<0>(n) hash] ^ [std::get<1>(n) hash];
  }
};

typedef std::unordered_map<CKTreeNodeComponentKey, CKTreeNode *, CKTreeNodeComponentKeyHasher, CKTreeNodeComponentKeyComparator> CKNodeMap;
typedef std::unordered_map<CKTreeNodeClassType, NSUInteger, CKClassTypeHasher, CKClassTypeComparator> CKClassTypeMap;

@implementation CKTreeNodeWithChildren
{
  CKNodeMap _children;
  CKClassTypeMap _classTypeMap;
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
  auto const it = _children.find(key);
  if (it != _children.end()) {
    return it->second;
  }
  return nil;
}

- (CKTreeNodeComponentKey)createComponentKeyForChildWithClass:(id<CKComponentProtocol>)componentClass
                                                   identifier:(id<NSObject>)identifier
{
  auto const classKey = std::make_tuple(componentClass, identifier);
  return std::make_tuple(componentClass, _classTypeMap[classKey]++, identifier);
}

- (void)setChild:(CKTreeNode *)child forComponentKey:(const CKTreeNodeComponentKey &)componentKey
{
  _children[componentKey] = child;
}

- (void)didReuseInScopeRoot:(CKComponentScopeRoot *)scopeRoot fromPreviousScopeRoot:(CKComponentScopeRoot *)previousScopeRoot
{
  [super didReuseInScopeRoot:scopeRoot fromPreviousScopeRoot:previousScopeRoot];
  for (auto const &child : _children) {
    [child.second didReuseInScopeRoot:scopeRoot fromPreviousScopeRoot:previousScopeRoot];
  }
}

#if DEBUG
- (NSArray<NSString *> *)debugDescriptionNodes
{
  NSMutableArray<NSString *> *debugDescriptionNodes = [NSMutableArray arrayWithArray:[super debugDescriptionNodes]];
  for (auto const &child : _children) {
    for (NSString *s in [child.second debugDescriptionNodes]) {
      [debugDescriptionNodes addObject:[@"  " stringByAppendingString:s]];
    }
  }
  return debugDescriptionNodes;
}
#endif

@end
