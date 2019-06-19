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

- (std::vector<id<CKTreeNodeProtocol>>)children
{
  return {_child};
}

- (size_t)childrenSize
{
  return _child ? 1 : 0;
}

- (CKTreeNode *)childForComponentKey:(const CKTreeNodeComponentKey &)key
{
  if (std::get<0>(key) == [_child.component class]) {
    return _child;
  }
  return nil;
}

- (CKTreeNodeComponentKey)createComponentKeyForChildWithClass:(id<CKComponentProtocol>)componentClass
                                                   identifier:(id<NSObject>)identifier
{
  return std::make_tuple(componentClass, 0, identifier);
}

- (void)setChild:(CKTreeNode *)child forComponentKey:(const CKTreeNodeComponentKey &)componentKey
{
  CKAssert(_child == nil || [_child class] == [child class], @"[_child class]: %@ is different than [child class]: %@", [_child class], [child class]);
  _child = child;
}

- (void)didReuseInScopeRoot:(CKComponentScopeRoot *)scopeRoot fromPreviousScopeRoot:(CKComponentScopeRoot *)previousScopeRoot
{
  [super didReuseInScopeRoot:scopeRoot fromPreviousScopeRoot:previousScopeRoot];
  [_child didReuseInScopeRoot:scopeRoot fromPreviousScopeRoot:previousScopeRoot];
}

#if DEBUG
- (NSArray<NSString *> *)debugDescriptionNodes
{
  NSMutableArray<NSString *> *debugDescriptionNodes = [NSMutableArray arrayWithArray:[super debugDescriptionNodes]];
  for (NSString *s in [_child debugDescriptionNodes]) {
    [debugDescriptionNodes addObject:[@"  " stringByAppendingString:s]];
  }
  return debugDescriptionNodes;
}
#endif

@end
