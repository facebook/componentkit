/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentScopeFrameInternal.h"

#import <algorithm>
#import <unordered_map>
#import <libkern/OSAtomic.h>

#import "CKAssert.h"
#import "CKComponentInternal.h"
#import "CKComponentScopeHandle.h"
#import "CKComponentScopeRoot.h"
#import "CKComponentSubclass.h"
#import "CKEqualityHashHelpers.h"
#import "CKMacros.h"
#import "CKThreadLocalComponentScope.h"

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

static BOOL _alwaysUseStateKeyCounter = NO;

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
  CKAssertNotNil(pair.frame, @"Must have frame");

  CKComponentScopeFrame *existingChildFrameOfEquivalentPreviousFrame;
  CKStateScopeKey stateScopeKey = {componentClass, identifier, keys};

  // If 'alwaysUseStateKeyCounter' is set to YES, we increment the stateKeyCounter by default to avoid scope collisions.
  if (_alwaysUseStateKeyCounter) {
    // We increment the `stateKeyCounter` in the parent frame map (`_stateKeyCounterMap`)
    // and use it as part of the state scope key; this way we can gurautee that each `CKStateScopeKey` is unique.
    auto const stateKeyCounter = ++(pair.frame->_stateKeyCounterMap[stateScopeKey]);
    stateScopeKey = {componentClass, identifier, keys, stateKeyCounter};
  }

  // Get the child from the previous equivalent scope frame.
  if (pair.equivalentPreviousFrame) {
    const auto &equivalentPreviousFrameChildren = pair.equivalentPreviousFrame->_children;
    const auto it = equivalentPreviousFrameChildren.find(stateScopeKey);
    existingChildFrameOfEquivalentPreviousFrame = (it == equivalentPreviousFrameChildren.end()) ? nil : it->second;
  }

  // If 'alwaysUseStateKeyCounter' is set to NO, we check for a scope collision.
  // If we have one, we use the `stateKeyCounter` to create a unique state key.
  if (!_alwaysUseStateKeyCounter) {
    const auto existingChild = pair.frame->_children.find(stateScopeKey);
    if (!pair.frame->_children.empty() && (existingChild != pair.frame->_children.end())) {
      // In case of a scope collision, we increment the `stateKeyCounter` in the parent frame map (`_stateKeyCounterMap`)
      // and use it as part of the state scope key; this way we can gurautee that each `CKStateScopeKey` is unique.
      auto const stateKeyCounter = ++(pair.frame->_stateKeyCounterMap[stateScopeKey]);
      stateScopeKey = {componentClass, identifier, keys, stateKeyCounter};

      if (pair.equivalentPreviousFrame) {
        const auto &equivalentPreviousFrameChildren = pair.equivalentPreviousFrame->_children;
        const auto it = equivalentPreviousFrameChildren.find(stateScopeKey);
        existingChildFrameOfEquivalentPreviousFrame = (it == equivalentPreviousFrameChildren.end()) ? nil : it->second;
      }
    }
  }

  CKComponentScopeHandle *newHandle =
  existingChildFrameOfEquivalentPreviousFrame
  ? [existingChildFrameOfEquivalentPreviousFrame.handle newHandleWithStateUpdates:stateUpdates
                                                               componentScopeRoot:newRoot
                                                                           parent:pair.frame.handle]
  : [[CKComponentScopeHandle alloc] initWithListener:newRoot.listener
                                      rootIdentifier:newRoot.globalIdentifier
                                      componentClass:componentClass
                                        initialState:(initialStateCreator ? initialStateCreator() : [componentClass initialState])
                                              parent:pair.frame.handle];

  CKComponentScopeFrame *newChild = [[CKComponentScopeFrame alloc] initWithHandle:newHandle];
  pair.frame->_children.insert({stateScopeKey, newChild});
  return {.frame = newChild, .equivalentPreviousFrame = existingChildFrameOfEquivalentPreviousFrame};
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

- (void)copyChildrenFrom:(CKComponentScopeFrame *)other
{
  if (other == nil) {
    return;
  }
  _children = other->_children;
}

- (std::vector<CKComponent *>)allAcquiredComponentsInDescendants
{
  std::vector<CKComponent *> result;
  for (const auto &pair : _children) {
    [pair.second collectAllAquiredComponentsInto:result];
  }
  return result;
}

// Recursively gather all children into a shared mutable vector
- (void)collectAllAquiredComponentsInto:(std::vector<CKComponent *> &)components
{
  components.push_back(self.handle.acquiredComponent);
  for (const auto &pair : _children) {
    [pair.second collectAllAquiredComponentsInto:components];
  }
}

+ (void)setAlwaysUseStateKeyCounter:(BOOL)alwaysUseStateKeyCounter
{
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _alwaysUseStateKeyCounter = alwaysUseStateKeyCounter;
  });
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
