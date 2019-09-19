/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKSingleChildComponent.h"

#import "CKComponentInternal.h"
#import "CKComponentSubclass.h"

@implementation CKSingleChildComponent

@synthesize child = _child;

#pragma mark - CKTreeNodeWithChildrenProtocol

- (std::vector<id<CKTreeNodeProtocol>>)children
{
  return {_child.component};
}

- (size_t)childrenSize
{
  return _child.component ? 1 : 0;
}

- (id<CKTreeNodeProtocol>)childForComponentKey:(const CKTreeNodeComponentKey &)key
{
  if (std::get<0>(key) == [_child class]) {
    return _child;
  }
  return nil;
}

- (CKTreeNodeComponentKey)createComponentKeyForChildWithClass:(id<CKComponentProtocol>)componentClass
                                                   identifier:(id<NSObject>)identifier
{
  return std::make_tuple(componentClass, 0, identifier);
}

- (void)setChild:(id<CKTreeNodeProtocol>)child forComponentKey:(const CKTreeNodeComponentKey &)componentKey {}


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
