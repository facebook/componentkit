/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKScopeTreeNode.h"

#import <algorithm>
#import <unordered_map>

#import <ComponentKit/CKGlobalConfig.h>

#import "CKThreadLocalComponentScope.h"
#import "CKTreeNodeProtocol.h"

NSUInteger const kTreeNodeParentBaseKey = 0;
NSUInteger const kTreeNodeOwnerBaseKey = 1;

@implementation CKScopeTreeNode

#pragma mark - CKTreeNodeWithChildrenProtocol

- (std::vector<id<CKTreeNodeProtocol>>)children
{
  std::vector<id<CKTreeNodeProtocol>> children;
  for (auto const &child : _children) {
    auto childKey = std::get<0>(child);
    if (std::get<1>(childKey) % 2 == kTreeNodeParentBaseKey) {
      children.push_back(std::get<1>(child));
    }
  }
  return children;
}

- (size_t)childrenSize
{
  return _children.size();
}

- (id<CKTreeNodeProtocol>)childForComponentKey:(const CKTreeNodeComponentKey &)key
{
  for (auto const &child : _children) {
    auto childKey = std::get<0>(child);
    if (CK::TreeNode::areKeysEqual(childKey, key)) {
      return std::get<1>(child);
    }
  }
  return nil;
}

- (CKTreeNodeComponentKey)createComponentKeyForChildWithClass:(Class)componentClass
                                                   identifier:(id<NSObject>)identifier
{
  // Create **parent** based key counter.
  NSUInteger keyCounter = kTreeNodeParentBaseKey;
  for (auto const &child : _children) {
    auto childKey = std::get<0>(child);
    if (std::get<0>(childKey) == componentClass && CKObjectIsEqual(std::get<2>(childKey), identifier)) {
      keyCounter += 2;
    }
  }
  return std::make_tuple(componentClass, keyCounter, identifier, std::vector<id<NSObject>>{});
}

- (void)setChild:(id<CKTreeNodeProtocol>)child forComponentKey:(const CKTreeNodeComponentKey &)componentKey
{
  _children.push_back({componentKey, child});
}

- (void)didReuseInScopeRoot:(CKComponentScopeRoot *)scopeRoot
      fromPreviousScopeRoot:(CKComponentScopeRoot *)previousScopeRoot
        mergeTreeNodesLinks:(BOOL)mergeTreeNodesLinks
{
  // In case that CKComponentScope was created, but not acquired from the component (for example: early nil return) ,
  // the component was never linked to the scope handle/tree node, hence, we should stop the recursion here.
  if (self.component == nil) {
    return;
  }

  [super didReuseInScopeRoot:scopeRoot fromPreviousScopeRoot:previousScopeRoot mergeTreeNodesLinks:mergeTreeNodesLinks];

  if (mergeTreeNodesLinks) {
    for (auto const &child : _children) {
      [std::get<1>(child) didReuseInScopeRoot:scopeRoot fromPreviousScopeRoot:previousScopeRoot mergeTreeNodesLinks:mergeTreeNodesLinks];
    }
  } else  {
    for (auto const &child : _children) {
      auto childKey = std::get<0>(child);
      if (std::get<1>(childKey) % 2 == kTreeNodeParentBaseKey) {
        [std::get<1>(child) didReuseInScopeRoot:scopeRoot fromPreviousScopeRoot:previousScopeRoot mergeTreeNodesLinks:mergeTreeNodesLinks];
      }
    }
  }
}

#pragma mark - CKScopeTreeNodeProtocol

- (CKTreeNodeComponentKey)createKeyForComponentClass:(Class<CKComponentProtocol>)componentClass
                                          identifier:(id)identifier
                                                keys:(const std::vector<id<NSObject>> &)keys
{
  // Create **owner** based key counter.
  NSUInteger keyCounter = kTreeNodeOwnerBaseKey;
  for (auto const &child : _children) {
    auto childKey = std::get<0>(child);
    if (std::get<0>(childKey) == componentClass && CKObjectIsEqual(std::get<2>(childKey), identifier)) {
      keyCounter += 2;
    }
  }
  // Update the stateKey with the class key counter to make sure we don't have collisions.
  return std::make_tuple(componentClass, keyCounter, identifier, keys);
}

- (id<CKScopeTreeNodeProtocol>)childScopeForComponentKey:(const CKTreeNodeComponentKey &)key
{
  return (id<CKScopeTreeNodeProtocol>)[self childForComponentKey:key];
}

- (void)setChildScope:(id<CKScopeTreeNodeProtocol>)child forComponentKey:(const CKTreeNodeComponentKey &)componentKey
{
  _children.push_back({componentKey, child});
}

#pragma mark - CKComponentScopeFrameProtocol

+ (CKComponentScopeFramePair)childPairForPair:(const CKComponentScopeFramePair &)pair
                                      newRoot:(CKComponentScopeRoot *)newRoot
                               componentClass:(Class<CKComponentProtocol>)componentClass
                                   identifier:(id)identifier
                                         keys:(const std::vector<id<NSObject>> &)keys
                          initialStateCreator:(id (^)(void))initialStateCreator
                                 stateUpdates:(const CKComponentStateUpdateMap &)stateUpdates
                          mergeTreeNodesLinks:(BOOL)mergeTreeNodesLinks
{
  id<CKScopeTreeNodeProtocol> frame = (id<CKScopeTreeNodeProtocol>)pair.frame;
  id<CKScopeTreeNodeProtocol> previousFrame = (id<CKScopeTreeNodeProtocol>)pair.previousFrame;

  CKAssertNotNil(frame, @"Must have frame");
  CKAssert([frame conformsToProtocol:@protocol(CKScopeTreeNodeProtocol)], @"frame should conform to id<CKScopeTreeNodeProtocol> instead of %@", frame.class);
  CKAssert(previousFrame == nil || [previousFrame conformsToProtocol:@protocol(CKScopeTreeNodeProtocol)], @"previousFrame should conform to id<CKScopeTreeNodeProtocol> instead of %@", previousFrame.class);

  // Generate key inside the new parent
  CKTreeNodeComponentKey componentKey = [frame createKeyForComponentClass:componentClass identifier:identifier keys:keys];
  // Get the child from the previous equivalent frame.
  CKScopeTreeNode *childFrameOfPreviousFrame = [previousFrame childScopeForComponentKey:componentKey];

  // Create new handle.
  CKComponentScopeHandle *newHandle = childFrameOfPreviousFrame
  ? [childFrameOfPreviousFrame.scopeHandle newHandleWithStateUpdates:stateUpdates componentScopeRoot:newRoot]
  : [[CKComponentScopeHandle alloc] initWithListener:newRoot.listener
                                      rootIdentifier:newRoot.globalIdentifier
                                      componentClass:componentClass
                                        initialState:(initialStateCreator ? initialStateCreator() : [componentClass initialState])];

  // Create new node.
  CKScopeTreeNode *newChild = [[CKScopeTreeNode alloc]
                               initWithPreviousNode:childFrameOfPreviousFrame
                               scopeHandle:newHandle];

  // Link the tree node to the scope handle.
  [newHandle setTreeNode:newChild];

  // Insert the new node to its parent map.
  [frame setChildScope:newChild forComponentKey:componentKey];

  // Update the component key on the new child.
  if (mergeTreeNodesLinks) {
    newChild->_componentKey = componentKey;
  }

  return {.frame = newChild, .previousFrame = childFrameOfPreviousFrame};
}

#pragma mark - Helpers

#if DEBUG
// Iterate threw the nodes according to the **parent** based key
- (NSArray<NSString *> *)debugDescriptionNodes
{
  NSMutableArray<NSString *> *debugDescriptionNodes = [NSMutableArray arrayWithArray:[super debugDescriptionNodes]];
  for (auto const &child : _children) {
    auto const key = std::get<0>(child);
    auto const childNode = std::get<1>(child);
    if (std::get<1>(key) % 2 == kTreeNodeParentBaseKey) {
      for (NSString *s in [childNode debugDescriptionNodes]) {
        [debugDescriptionNodes addObject:[@"  " stringByAppendingString:s]];
      }
    }
  }
  return debugDescriptionNodes;
}

// Iterate threw the nodes according to the **owner** based key
- (NSArray<NSString *> *)debugDescriptionComponents
{
  NSMutableArray<NSString *> *childrenDebugDescriptions = [NSMutableArray new];
  for (auto const &child : _children) {
    auto const key = std::get<0>(child);
    auto const childNode = std::get<1>(child);
    if (std::get<1>(key) % 2 == kTreeNodeOwnerBaseKey) {
      auto const description = [NSString stringWithFormat:@"- %@%@%@",
                                NSStringFromClass(std::get<0>(key)),
                                (std::get<2>(key)
                                 ? [NSString stringWithFormat:@":%@", std::get<2>(key)]
                                 : @""),
                                std::get<3>(key).empty() ? @"" : formatKeys(std::get<3>(key))];
      [childrenDebugDescriptions addObject:description];
      for (NSString *s in [(id<CKComponentScopeFrameProtocol>)childNode debugDescriptionComponents]) {
        [childrenDebugDescriptions addObject:[@"  " stringByAppendingString:s]];
      }
    }
  }
  return childrenDebugDescriptions;
}

static NSString *formatKeys(const std::vector<id<NSObject>> &keys)
{
  NSMutableArray<NSString *> *a = [NSMutableArray new];
  for (auto key : keys) {
    [a addObject:[key description] ?: @"(null)"];
  }
  return [a componentsJoinedByString:@", "];
}

#endif
@end
