/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentScopeFrame.h"

#import <algorithm>
#import <unordered_map>
#import <libkern/OSAtomic.h>

#import "CKAssert.h"
#import "CKComponentScopeHandle.h"
#import "CKComponentScopeRoot.h"
#import "CKComponentSubclass.h"
#import "CKEqualityHashHelpers.h"
#import "CKMacros.h"
#import "CKThreadLocalComponentScope.h"
#import "CKTreeNodeProtocol.h"

static bool keyVectorsEqual(const std::vector<id<NSObject>> &a, const std::vector<id<NSObject>> &b)
{
  if (a.size() != b.size()) {
    return false;
  }
  return std::equal(a.begin(), a.end(), b.begin(), [](id<NSObject> x, id<NSObject> y){
    return CKObjectIsEqual(x, y); // be pedantic and use a lambda here becuase BOOL != bool
  });
}

struct CKStateScopeKey {
  Class __unsafe_unretained componentClass;
  id identifier;
  std::vector<id<NSObject>> keys;
  NSUInteger stateKeyCounter; // In case of scope collistion, we will increment this counter and creare a uniqe one.

  bool operator==(const CKStateScopeKey &v) const {
    return (CKObjectIsEqual(this->componentClass, v.componentClass)
            && CKObjectIsEqual(this->identifier, v.identifier)
            && keyVectorsEqual(this->keys, v.keys)
            && this->stateKeyCounter == v.stateKeyCounter);
  }
};

namespace std {
  template <>
  struct hash<CKStateScopeKey> {
    size_t operator ()(CKStateScopeKey k) const {
      // Note we just use k.keys.size() for the hash of keys. Otherwise we'd have to enumerate over each item and
      // call [NSObject -hash] on it and incorporate every element into the overall hash somehow.
      NSUInteger subhashes[] = { [k.componentClass hash], [k.identifier hash], k.keys.size(), k.stateKeyCounter };
      return CKIntegerArrayHash(subhashes, CK_ARRAY_COUNT(subhashes));
    }
  };
}

@implementation CKComponentScopeFrame
{
  std::unordered_map<CKStateScopeKey, CKComponentScopeFrame *> _children;
  std::unordered_map<CKStateScopeKey, NSUInteger> _stateKeyCounterMap;
}

+ (CKComponentScopeFramePair)childPairForPair:(const CKComponentScopeFramePair &)pair
                                      newRoot:(CKComponentScopeRoot *)newRoot
                               componentClass:(Class<CKComponentProtocol>)componentClass
                                   identifier:(id)identifier
                                         keys:(const std::vector<id<NSObject>> &)keys
                          initialStateCreator:(id (^)())initialStateCreator
                                 stateUpdates:(const CKComponentStateUpdateMap &)stateUpdates
{
  CKComponentScopeFrame *frame = (CKComponentScopeFrame *)pair.frame;
  CKComponentScopeFrame *previousFrame = (CKComponentScopeFrame *)pair.previousFrame;

  CKAssertNotNil(frame, @"Must have frame");
  CKAssert(frame.class == [CKComponentScopeFrame class], @"frame should be CKComponentScopeFrame instead of %@", frame.class);
  CKAssert(previousFrame == nil || previousFrame.class == [CKComponentScopeFrame class], @"previousFrame should be CKComponentScopeFrame instead of %@", previousFrame.class);

  CKStateScopeKey stateScopeKey = {componentClass, identifier, keys};

  // We increment the `stateKeyCounter` in the parent frame map (`_stateKeyCounterMap`)
  // and use it as part of the state scope key; this way we can gurautee that each `CKStateScopeKey` is unique.
  auto const stateKeyCounter = ++(frame->_stateKeyCounterMap[stateScopeKey]);
  stateScopeKey = {componentClass, identifier, keys, stateKeyCounter};

  // Get the child from the previous equivalent scope frame.
  CKComponentScopeFrame *existingChildFrameOfPreviousFrame;
  if (previousFrame) {
    const auto &previousFrameChildren = previousFrame->_children;
    const auto it = previousFrameChildren.find(stateScopeKey);
    existingChildFrameOfPreviousFrame = (it == previousFrameChildren.end()) ? nil : it->second;
  }

  CKComponentScopeHandle *newHandle =
  existingChildFrameOfPreviousFrame
  ? [existingChildFrameOfPreviousFrame.handle newHandleWithStateUpdates:stateUpdates
                                                     componentScopeRoot:newRoot]
  : [[CKComponentScopeHandle alloc] initWithListener:newRoot.listener
                                      rootIdentifier:newRoot.globalIdentifier
                                      componentClass:componentClass
                                        initialState:(initialStateCreator ? initialStateCreator() : [componentClass initialState])];

  CKComponentScopeFrame *newChild = [[CKComponentScopeFrame alloc] initWithHandle:newHandle];
  frame->_children.insert({stateScopeKey, newChild});
  return {.frame = newChild, .previousFrame = existingChildFrameOfPreviousFrame};
}

+ (void)willBuildComponentTreeWithTreeNode:(id<CKTreeNodeProtocol>)node
{
  auto const threadLocalScope = CKThreadLocalComponentScope::currentScope();
  if (threadLocalScope == nullptr) {
    return;
  }
  
  // Create a unique key based on the tree node identifier and the component class.
  CKStateScopeKey stateScopeKey = {[node.component class], @(node.nodeIdentifier)};

  CKComponentScopeFramePair &pair = threadLocalScope->stack.top();
  CKComponentScopeFrame *frame = (CKComponentScopeFrame *)pair.frame;
  CKComponentScopeFrame *previousFrame = (CKComponentScopeFrame *)pair.previousFrame;
  CKAssert(frame.class == [CKComponentScopeFrame class], @"frame should be CKComponentScopeFrame instead of %@", frame.class);
  CKAssert(previousFrame == nil || previousFrame.class == [CKComponentScopeFrame class], @"previousFrame should be CKComponentScopeFrame instead of %@", previousFrame.class);

  // Get the frame from the previous generation if it exists.
  CKComponentScopeFrame *existingChildFrameOfPreviousFrame;
  if (previousFrame) {
    const auto &previousFrameChildren = previousFrame->_children;
    const auto it = previousFrameChildren.find(stateScopeKey);
    existingChildFrameOfPreviousFrame = (it == previousFrameChildren.end()) ? nil : it->second;
  }

  // Create a scope frame for the render component children.
  CKComponentScopeFrame *newFrame = [[CKComponentScopeFrame alloc] initWithHandle:node.handle];
  // Push the new scope frame to the parent frame's children.
  frame->_children.insert({stateScopeKey, newFrame});
  // Push the new pair into the thread local.
  threadLocalScope->stack.push({.frame = newFrame, .previousFrame = existingChildFrameOfPreviousFrame});
}

+ (void)didBuildComponentTreeWithNode:(id<CKTreeNodeProtocol>)node
{
  auto const threadLocalScope = CKThreadLocalComponentScope::currentScope();
  if (threadLocalScope == nullptr) {
    return;
  }

  CKAssert(!threadLocalScope->stack.empty() && threadLocalScope->stack.top().frame.handle == node.handle, @"frame.handle is not equal to node.handle");
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
  CKStateScopeKey stateScopeKey = {[node.component class], @(node.nodeIdentifier)};

  CKComponentScopeFramePair &pair = threadLocalScope->stack.top();
  CKComponentScopeFrame *frame = (CKComponentScopeFrame *)pair.frame;
  CKComponentScopeFrame *previousFrame = (CKComponentScopeFrame *)pair.previousFrame;
  CKAssert(frame.class == [CKComponentScopeFrame class], @"frame should be CKComponentScopeFrame instead of %@", frame.class);
  CKAssert(previousFrame == nil || previousFrame.class == [CKComponentScopeFrame class], @"previousFrame should be CKComponentScopeFrame instead of %@", previousFrame.class);

  // Get the frame from the previous generation if it exists.
  CKComponentScopeFrame *existingChildFrameOfPreviousFrame;
  if (previousFrame) {
    const auto &previousFrameChildren = previousFrame->_children;
    const auto it = previousFrameChildren.find(stateScopeKey);
    existingChildFrameOfPreviousFrame = (it == previousFrameChildren.end()) ? nil : it->second;
  }
  
  // Transfer the previous frame into the parent from the new generation.
  if (existingChildFrameOfPreviousFrame) {
    frame->_children.insert({stateScopeKey, existingChildFrameOfPreviousFrame});
  }
}

- (instancetype)initWithHandle:(CKComponentScopeHandle *)handle
{
  if (self = [super init]) {
    _handle = handle;
  }
  return self;
}

- (size_t)childrenSize
{
  return _children.size();
}

#if DEBUG
- (NSArray<NSString *> *)debugDescriptionComponents
{
  NSMutableArray<NSString *> *childrenDebugDescriptions = [NSMutableArray new];
  for (auto child : _children) {
    [childrenDebugDescriptions addObject:
     [NSString stringWithFormat:@"- %@%@%@",
      NSStringFromClass(child.first.componentClass),
      child.first.identifier ? [NSString stringWithFormat:@":%@", child.first.identifier] : @"",
      child.first.keys.empty() ? @"" : formatKeys(child.first.keys)]];
    for (NSString *s in [child.second debugDescriptionComponents]) {
      [childrenDebugDescriptions addObject:[@"  " stringByAppendingString:s]];
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
