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

#import "CKThreadLocalComponentScope.h"
#import "CKGlobalConfig.h"

static NSUInteger const kParentBaseKey = 0;
static NSUInteger const kOwnerBaseKey = 1;
static BOOL useVector = NO;

@implementation CKScopeTreeNode
{
  CKTreeNodeKeyToCounter _keyToCounterMap;
}

+ (void)initialize
{
  if (self == [CKScopeTreeNode class]) {
    useVector = CKReadGlobalConfig().unifyComponentTreeConfig.useVector;
  }
}

#pragma mark - CKTreeNodeWithChildrenProtocol

- (std::vector<id<CKTreeNodeProtocol>>)children
{
  std::vector<id<CKTreeNodeProtocol>> children;
  if (useVector) {
    for (auto const &child : _childrenVector) {
      auto childStateKey = std::get<0>(child);
      if (std::get<1>(childStateKey.nodeKey) % 2 == kParentBaseKey) {
        children.push_back(std::get<1>(child));
      }
    }
  } else {
    for (auto const &child : _children) {
      if (std::get<1>(child.first.nodeKey) % 2 == kParentBaseKey) {
        children.push_back(child.second);
      }
    }
  }
  return children;
}

- (size_t)childrenSize
{
  if (useVector) {
    return _childrenVector.size();
  } else {
    return _children.size();
  }
}

- (CKTreeNode *)childForComponentKey:(const CKTreeNodeComponentKey &)key
{
  CKScopeNodeKey stateKey = {key};
  if (useVector) {
    for (auto const &child : _childrenVector) {
      auto childStateKey = std::get<0>(child);
      if (childStateKey == stateKey) {
        return std::get<1>(child);
      }
    }
    return nil;
  }

  auto const it = _children.find(stateKey);
  if (it != _children.end()) {
    return it->second;
  }
  return nil;
}

- (CKTreeNodeComponentKey)createComponentKeyForChildWithClass:(id<CKComponentProtocol>)componentClass
                                                   identifier:(id<NSObject>)identifier
{
  // Create **parent** based key counter.
  NSUInteger keyCounter = kParentBaseKey;
  if (useVector) {
    for (auto const &child : _childrenVector) {
      auto childNodeKey = std::get<0>(child).nodeKey;
      if (std::get<0>(childNodeKey) == componentClass && CKObjectIsEqual(std::get<2>(childNodeKey), identifier)) {
        keyCounter += 2;
      }
    }
  } else {
    keyCounter = parentKeyCounter(componentClass, identifier, _keyToCounterMap);
  }
  return std::make_tuple(componentClass, keyCounter, identifier);
}

- (void)setChild:(CKTreeNode *)child forComponentKey:(const CKTreeNodeComponentKey &)componentKey
{
  if (useVector) {
    _childrenVector.push_back({{componentKey}, child});
  } else {
    _children[{componentKey}] = child;
  }
}

- (void)didReuseInScopeRoot:(CKComponentScopeRoot *)scopeRoot fromPreviousScopeRoot:(CKComponentScopeRoot *)previousScopeRoot
{
  // In case that CKComponentScope was created, but not acquired from the component (for example: early nil return) ,
  // the component was never linked to the scope handle/tree node, hence, we should stop the recursion here.
  if (self.handle.acquiredComponent == nil) {
    return;
  }

  [super didReuseInScopeRoot:scopeRoot fromPreviousScopeRoot:previousScopeRoot];
  if (useVector) {
    for (auto const &child : _childrenVector) {
      auto childStateKey = std::get<0>(child);
      if (std::get<1>(childStateKey.nodeKey) % 2 == kParentBaseKey) {
        [std::get<1>(child) didReuseInScopeRoot:scopeRoot fromPreviousScopeRoot:previousScopeRoot];
      }
    }
  } else {
    for (auto const &child : _children) {
      if (std::get<1>(child.first.nodeKey) % 2 == kParentBaseKey) {
        [child.second didReuseInScopeRoot:scopeRoot fromPreviousScopeRoot:previousScopeRoot];
      }
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
  if (useVector) {
    for (auto const &child : _childrenVector) {
      auto childNodeKey = std::get<0>(child).nodeKey;
      if (std::get<0>(childNodeKey) == componentClass && CKObjectIsEqual(std::get<2>(childNodeKey), identifier)) {
        keyCounter += 2;
      }
    }
  } else {
    keyCounter = ownerKeyCounter(componentClass, identifier, _keyToCounterMap);
  }
  // Update the stateKey with the class key counter to make sure we don't have collisions.
  return {std::make_tuple(componentClass, keyCounter, identifier), keys};
}

- (id<CKScopeTreeNodeProtocol>)childForScopeNodeKey:(const CKScopeNodeKey &)scopeNodeKey
{
  if (useVector) {
    for (auto const &child : _childrenVector) {
      auto childStateKey = std::get<0>(child);
      if (childStateKey == scopeNodeKey) {
        return (id<CKScopeTreeNodeProtocol>)std::get<1>(child);
      }
    }
    return nil;
  }
  // Get the child from the previous equivalent node.
  const auto it = _children.find(scopeNodeKey);
  return (it == _children.end()) ? nil : (id<CKScopeTreeNodeProtocol>)it->second;
}

- (void)setChild:(id<CKScopeTreeNodeProtocol>)child forKey:(const CKScopeNodeKey &)key
{
  if (useVector) {
    _childrenVector.push_back({key,child});
  } else {
    _children[key] = child;
  }
}

#pragma mark - CKComponentScopeFrameProtocol

+ (CKComponentScopeFramePair)childPairForPair:(const CKComponentScopeFramePair &)pair
                                      newRoot:(CKComponentScopeRoot *)newRoot
                               componentClass:(Class<CKComponentProtocol>)componentClass
                                   identifier:(id)identifier
                                         keys:(const std::vector<id<NSObject>> &)keys
                          initialStateCreator:(id (^)(void))initialStateCreator
                                 stateUpdates:(const CKComponentStateUpdateMap &)stateUpdates
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
  ? [childFrameOfPreviousFrame.handle newHandleWithStateUpdates:stateUpdates componentScopeRoot:newRoot]
  : [[CKComponentScopeHandle alloc] initWithListener:newRoot.listener
                                      rootIdentifier:newRoot.globalIdentifier
                                      componentClass:componentClass
                                        initialState:(initialStateCreator ? initialStateCreator() : [componentClass initialState])];

  // Create new node.
  CKScopeTreeNode *newChild = [[CKScopeTreeNode alloc]
                               initWithPreviousNode:childFrameOfPreviousFrame
                               handle:newHandle];

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
  CKAssert(!threadLocalScope->stack.empty() && threadLocalScope->stack.top().frame.handle == nil, @"frame.handle is not equal to nil");
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

static NSUInteger parentKeyCounter(id<CKComponentProtocol> componentClass,
                                  id<NSObject> identifier,
                                  CKTreeNodeKeyToCounter &keyToCounterMap) {
  
  // Create key to retrive the counter of the CKScopeNodeKey (in case of identical key, we increment it to avoid collisions).
  CKTreeNodeComponentKey componentKey = std::make_tuple(componentClass, kParentBaseKey, identifier);
  // We use even numbers to represent **parent** based keys (0,2,4,..).
  return (keyToCounterMap[componentKey]++) * 2;
}

static NSUInteger ownerKeyCounter(id<CKComponentProtocol> componentClass,
                                  id<NSObject> identifier,
                                  CKTreeNodeKeyToCounter &keyToCounterMap) {
  // Create key to retrive the counter of the CKScopeNodeKey (in case of identical key, we incrment it to avoid collisions).
  CKTreeNodeComponentKey componentKey = std::make_tuple(componentClass, kOwnerBaseKey, identifier);
  // We use odd numbers to represent **owner** based keys (1,3,5,..).
  return (keyToCounterMap[componentKey]++) * 2 + 1;
}

#if DEBUG
// Iterate threw the nodes according to the **parent** based key
- (NSArray<NSString *> *)debugDescriptionNodes
{
  NSMutableArray<NSString *> *debugDescriptionNodes = [NSMutableArray arrayWithArray:[super debugDescriptionNodes]];
  for (auto const &child : _children) {
    if (std::get<1>(child.first.nodeKey) % 2 == kParentBaseKey) {
      for (NSString *s in [child.second debugDescriptionNodes]) {
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
    if (std::get<1>(child.first.nodeKey) % 2 == kOwnerBaseKey) {
      auto const description = [NSString stringWithFormat:@"- %@%@%@",
                                NSStringFromClass(std::get<0>(child.first.nodeKey)),
                                (std::get<2>(child.first.nodeKey)
                                 ? [NSString stringWithFormat:@":%@", std::get<2>(child.first.nodeKey)]
                                 : @""),
                                child.first.keys.empty() ? @"" : formatKeys(child.first.keys)];
      [childrenDebugDescriptions addObject:description];
      for (NSString *s in [(id<CKComponentScopeFrameProtocol>)child.second debugDescriptionComponents]) {
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
