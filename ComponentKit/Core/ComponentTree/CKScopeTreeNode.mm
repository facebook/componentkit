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

#import "CKGlobalConfig.h"
#import "CKThreadLocalComponentScope.h"
#import "CKTreeNodeProtocol.h"

static NSUInteger const kParentBaseKey = 0;
static NSUInteger const kOwnerBaseKey = 1;

@implementation CKScopeTreeNode

#pragma mark - CKTreeNodeWithChildrenProtocol

- (std::vector<id<CKTreeNodeProtocol>>)children
{
  std::vector<id<CKTreeNodeProtocol>> children;
  for (auto const &child : _children) {
    auto childStateKey = std::get<0>(child);
    if (std::get<1>(childStateKey.nodeKey) % 2 == kParentBaseKey) {
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
  CKScopeNodeKey stateKey = {key};
  for (auto const &child : _children) {
    auto childStateKey = std::get<0>(child);
    if (childStateKey == stateKey) {
      return std::get<1>(child);
    }
  }
  return nil;
}

- (CKTreeNodeComponentKey)createComponentKeyForChildWithClass:(id<CKComponentProtocol>)componentClass
                                                   identifier:(id<NSObject>)identifier
{
  // Create **parent** based key counter.
  NSUInteger keyCounter = kParentBaseKey;
  for (auto const &child : _children) {
    auto childNodeKey = std::get<0>(child).nodeKey;
    if (std::get<0>(childNodeKey) == componentClass && CKObjectIsEqual(std::get<2>(childNodeKey), identifier)) {
      keyCounter += 2;
    }
  }
  return std::make_tuple(componentClass, keyCounter, identifier);
}

- (void)setChild:(id<CKTreeNodeProtocol>)child forComponentKey:(const CKTreeNodeComponentKey &)componentKey
{
  _children.push_back({{componentKey}, child});
}

- (void)didReuseInScopeRoot:(CKComponentScopeRoot *)scopeRoot fromPreviousScopeRoot:(CKComponentScopeRoot *)previousScopeRoot
{
  // In case that CKComponentScope was created, but not acquired from the component (for example: early nil return) ,
  // the component was never linked to the scope handle/tree node, hence, we should stop the recursion here.
  if (self.component == nil) {
    return;
  }

  [super didReuseInScopeRoot:scopeRoot fromPreviousScopeRoot:previousScopeRoot];
  for (auto const &child : _children) {
    auto childStateKey = std::get<0>(child);
    if (std::get<1>(childStateKey.nodeKey) % 2 == kParentBaseKey) {
      [std::get<1>(child) didReuseInScopeRoot:scopeRoot fromPreviousScopeRoot:previousScopeRoot];
    }
  }
}

#pragma mark - CKScopeTreeNodeProtocol

- (CKScopeNodeKey)createScopeNodeKeyForComponentClass:(Class<CKComponentProtocol>)componentClass
                                           identifier:(id)identifier
                                                 keys:(const std::vector<id<NSObject>> &)keys
{
  // Create **owner** based key counter.
  NSUInteger keyCounter = kOwnerBaseKey;
  for (auto const &child : _children) {
    auto childNodeKey = std::get<0>(child).nodeKey;
    if (std::get<0>(childNodeKey) == componentClass && CKObjectIsEqual(std::get<2>(childNodeKey), identifier)) {
      keyCounter += 2;
    }
  }
  // Update the stateKey with the class key counter to make sure we don't have collisions.
  return {std::make_tuple(componentClass, keyCounter, identifier), keys};
}

- (id<CKScopeTreeNodeProtocol>)childForScopeNodeKey:(const CKScopeNodeKey &)scopeNodeKey
{
  for (auto const &child : _children) {
    auto childStateKey = std::get<0>(child);
    if (childStateKey == scopeNodeKey) {
      return (id<CKScopeTreeNodeProtocol>)std::get<1>(child);
    }
  }
  return nil;
}

- (void)setChild:(id<CKScopeTreeNodeProtocol>)child forKey:(const CKScopeNodeKey &)key
{
  _children.push_back({key,child});
}

#pragma mark - CKComponentScopeFrameProtocol

+ (CKComponentScopeFramePair)childPairForPair:(const CKComponentScopeFramePair &)pair
                                      newRoot:(CKComponentScopeRoot *)newRoot
                               componentClass:(Class<CKComponentProtocol>)componentClass
                                   identifier:(id)identifier
                                         keys:(const std::vector<id<NSObject>> &)keys
                          initialStateCreator:(id (^)(void))initialStateCreator
                                 stateUpdates:(const CKComponentStateUpdateMap &)stateUpdates
                     unifyComponentTreeConfig:(const CKUnifyComponentTreeConfig &)unifyComponentTreeConfig
{
  id<CKScopeTreeNodeProtocol> frame = (id<CKScopeTreeNodeProtocol>)pair.frame;
  id<CKScopeTreeNodeProtocol> previousFrame = (id<CKScopeTreeNodeProtocol>)pair.previousFrame;

  CKAssertNotNil(frame, @"Must have frame");
  CKAssert([frame conformsToProtocol:@protocol(CKScopeTreeNodeProtocol)], @"frame should conform to id<CKScopeTreeNodeProtocol> instead of %@", frame.class);
  CKAssert(previousFrame == nil || [previousFrame conformsToProtocol:@protocol(CKScopeTreeNodeProtocol)], @"previousFrame should conform to id<CKScopeTreeNodeProtocol> instead of %@", previousFrame.class);

  // Generate key inside the new parent
  CKScopeNodeKey stateKey = [frame createScopeNodeKeyForComponentClass:componentClass identifier:identifier keys:keys];
  // Get the child from the previous equivalent frame.
  CKScopeTreeNode *childFrameOfPreviousFrame = [previousFrame childForScopeNodeKey:stateKey];

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

  if (unifyComponentTreeConfig.linkScopeTreeNodeToHandle) {
    // Link the tree node to the scope handle.
    [newHandle setTreeNode:newChild];
  }

  // Insert the new node to its parent map.
  [frame setChild:newChild forKey:stateKey];
  return {.frame = newChild, .previousFrame = childFrameOfPreviousFrame};
}

+ (void)willBuildComponentTreeWithTreeNode:(id<CKTreeNodeProtocol>)node
{
  auto const threadLocalScope = CKThreadLocalComponentScope::currentScope();
  if (threadLocalScope == nullptr) {
    return;
  }

  // Create a unique key based on the tree node identifier and the component class.
  CKScopeNodeKey stateKey = {std::make_tuple([node.component class], 0, @(node.nodeIdentifier))};

  // Get the frame from the previous generation if it exists.
  CKComponentScopeFramePair &pair = threadLocalScope->stack.top();

  CKScopeTreeNode *frame = (CKScopeTreeNode *)pair.frame;
  CKScopeTreeNode *previousFrame = (CKScopeTreeNode *)pair.previousFrame;

  CKAssert([frame conformsToProtocol:@protocol(CKScopeTreeNodeProtocol)], @"frame should conform to id<CKScopeTreeNodeProtocol> instead of %@", frame.class);
  CKAssert(previousFrame == nil || [previousFrame conformsToProtocol:@protocol(CKScopeTreeNodeProtocol)], @"previousFrame should conform to id<CKScopeTreeNodeProtocol> instead of %@", previousFrame.class);

  CKScopeTreeNode *childFrameOfPreviousFrame = [previousFrame childForScopeNodeKey:stateKey];
  // Create a scope frame for the render component children.
  CKScopeTreeNode *newFrame = [[CKScopeTreeNode alloc] init];
  // Push the new scope frame to the parent frame's children.
  [frame setChild:newFrame forKey:stateKey];
  // Push the new pair into the thread local.
  threadLocalScope->stack.push({.frame = newFrame, .previousFrame = childFrameOfPreviousFrame});
}

+ (void)didBuildComponentTreeWithNode:(id<CKTreeNodeProtocol>)node
{
  auto const threadLocalScope = CKThreadLocalComponentScope::currentScope();
  if (threadLocalScope == nullptr) {
    return;
  }

  // The scope handle should be nil here, as we create a scope node for the render component to own its scope frame children.
  CKAssert(!threadLocalScope->stack.empty() && threadLocalScope->stack.top().frame.scopeHandle == nil, @"frame.scopeHandle is not equal to nil");
  // Pop the top element of the stack.
  threadLocalScope->stack.pop();
}

+ (void)didReuseRenderWithTreeNode:(id<CKTreeNodeProtocol>)node
{
  auto const threadLocalScope = CKThreadLocalComponentScope::currentScope();
  if (threadLocalScope == nullptr) {
    return;
  }

  // Create a unique key based on the tree node identifier and the component class.
  CKScopeNodeKey stateKey = {std::make_tuple([node.component class], 0, @(node.nodeIdentifier))};

  // Get the frame from the previous generation if it exists.
  CKComponentScopeFramePair &pair = threadLocalScope->stack.top();

  CKScopeTreeNode *frame = (CKScopeTreeNode *)pair.frame;
  CKScopeTreeNode *previousFrame = (CKScopeTreeNode *)pair.previousFrame;

  CKAssert([frame conformsToProtocol:@protocol(CKScopeTreeNodeProtocol)], @"frame should conform to id<CKScopeTreeNodeProtocol> instead of %@", frame.class);
  CKAssert(previousFrame == nil || [previousFrame conformsToProtocol:@protocol(CKScopeTreeNodeProtocol)], @"previousFrame should conform to id<CKScopeTreeNodeProtocol> instead of %@", previousFrame.class);

  // Transfer the previous frame into the parent from the new generation.
  CKScopeTreeNode *childFrameOfPreviousFrame = [previousFrame childForScopeNodeKey:stateKey];
  if (childFrameOfPreviousFrame) {
    [frame setChild:childFrameOfPreviousFrame forKey:stateKey];
  }
}

#pragma mark - Helpers

#if DEBUG
// Iterate threw the nodes according to the **parent** based key
- (NSArray<NSString *> *)debugDescriptionNodes
{
  NSMutableArray<NSString *> *debugDescriptionNodes = [NSMutableArray arrayWithArray:[super debugDescriptionNodes]];
  for (auto const &child : _children) {
    auto const scopeNodeKey = std::get<0>(child);
    auto const childNode = std::get<1>(child);
    if (std::get<1>(scopeNodeKey.nodeKey) % 2 == kParentBaseKey) {
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
    auto const scopeNodeKey = std::get<0>(child);
    auto const childNode = std::get<1>(child);
    if (std::get<1>(scopeNodeKey.nodeKey) % 2 == kOwnerBaseKey) {
      auto const description = [NSString stringWithFormat:@"- %@%@%@",
                                NSStringFromClass(std::get<0>(scopeNodeKey.nodeKey)),
                                (std::get<2>(scopeNodeKey.nodeKey)
                                 ? [NSString stringWithFormat:@":%@", std::get<2>(scopeNodeKey.nodeKey)]
                                 : @""),
                                scopeNodeKey.keys.empty() ? @"" : formatKeys(scopeNodeKey.keys)];
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
