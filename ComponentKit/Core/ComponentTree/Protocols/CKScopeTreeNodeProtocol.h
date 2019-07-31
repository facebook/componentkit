/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKTreeNodeProtocol.h>
#import <ComponentKit/CKComponentScopeFrame.h>

struct CKScopeNodeKey {
  CKTreeNodeComponentKey nodeKey;
  std::vector<id<NSObject>> keys;

  bool operator==(const CKScopeNodeKey &v) const {
    return std::get<0>(this->nodeKey) == std::get<0>(v.nodeKey) &&
    std::get<1>(this->nodeKey) == std::get<1>(v.nodeKey) &&
    CKObjectIsEqual(std::get<2>(this->nodeKey), std::get<2>(v.nodeKey)) &&
    CKKeyVectorsEqual(this->keys, v.keys);
  }
};

namespace std {
  template <>
  struct hash<CKScopeNodeKey> {
    size_t operator ()(CKScopeNodeKey k) const {
      // Note we just use k.keys.size() for the hash of keys. Otherwise we'd have to enumerate over each item and
      // call [NSObject -hash] on it and incorporate every element into the overall hash somehow.
      auto const nodeKey = k.nodeKey;
      NSUInteger subhashes[] = { [std::get<0>(nodeKey) hash], std::get<1>(nodeKey), [std::get<2>(nodeKey) hash], k.keys.size() };
      return CKIntegerArrayHash(subhashes, CK_ARRAY_COUNT(subhashes));
    }
  };
}

/**
 This protocl is a bridge between CKComponentScope and CKTreeNode.

 It represents a node with children in the component tree.
 */
@protocol CKScopeTreeNodeProtocol <CKTreeNodeWithChildrenProtocol, CKComponentScopeFrameProtocol>

- (CKScopeNodeKey)createScopeNodeKeyForComponentClass:(Class<CKComponentProtocol>)componentClass
                                           identifier:(id)identifier
                                                 keys:(const std::vector<id<NSObject>> &)keys;
- (id<CKScopeTreeNodeProtocol>)childForScopeNodeKey:(const CKScopeNodeKey &)scopeNodeKey;
- (void)setChild:(id<CKScopeTreeNodeProtocol>)child forKey:(const CKScopeNodeKey &)key;

@end
