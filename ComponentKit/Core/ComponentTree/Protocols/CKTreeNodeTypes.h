/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <Foundation/Foundation.h>
#import <ComponentKit/CKDefines.h>

#import <ComponentKit/CKEqualityHelpers.h>
#import <ComponentKit/ComponentUtilities.h>

/** Unique identifier for tree nodes. */
typedef int32_t CKTreeNodeIdentifier;

#if CK_NOT_SWIFT

#include <tuple>
#include <unordered_set>
#include <unordered_map>

/** A key between a tree ndoe to its parent */
typedef std::tuple<Class, NSUInteger, id<NSObject>, std::vector<id<NSObject>>> CKTreeNodeComponentKey;
/** unordered_set of all the "dirty" tree nodes' identifiers; "dirty" means node on a state update branch. */
typedef std::unordered_set<CKTreeNodeIdentifier> CKTreeNodeDirtyIds;

namespace CK {
  namespace TreeNode {
    auto areKeysEqual(const CKTreeNodeComponentKey &lhs, const CKTreeNodeComponentKey &rhs) -> bool;
    auto isKeyEmpty(const CKTreeNodeComponentKey &key) -> bool;

    struct comparator {
      bool operator() (const CKTreeNodeComponentKey &lhs, const CKTreeNodeComponentKey &rhs) const
      {
        return areKeysEqual(lhs, rhs);
      }
    };

    struct hasher {
      std::size_t operator() (const CKTreeNodeComponentKey &n) const
      {
        return [std::get<0>(n) hash] ^ std::get<1>(n) ^ [std::get<2>(n) hash] ^ std::get<3>(n).size();
      }
    };
  }
}

/** A map between CKTreeNodeComponentKey to counter; we use it to avoid collisions for identical keys */
using CKTreeNodeKeyToCounter = std::unordered_map<CKTreeNodeComponentKey, NSUInteger, CK::TreeNode::hasher, CK::TreeNode::comparator>;


#endif
