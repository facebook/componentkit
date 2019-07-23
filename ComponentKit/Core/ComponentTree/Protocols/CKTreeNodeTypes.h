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

#include <tuple>
#include <unordered_set>
#include <unordered_map>

#import <ComponentKit/CKEqualityHashHelpers.h>
#import <ComponentKit/ComponentUtilities.h>

/** Unique identifier for tree nodes. */
typedef int32_t CKTreeNodeIdentifier;
/** A key between a tree ndoe to its parent */
typedef std::tuple<Class, NSUInteger, id<NSObject>> CKTreeNodeComponentKey;
/** unordered_set of all the "dirty" tree nodes' identifiers; "dirty" means node on a state update branch. */
typedef std::unordered_set<CKTreeNodeIdentifier> CKTreeNodeDirtyIds;

struct CKTreeNodeComponentKeyComparator {
  bool operator() (const CKTreeNodeComponentKey &lhs, const CKTreeNodeComponentKey &rhs) const
  {
    return std::get<0>(lhs) == std::get<0>(rhs) &&
    std::get<1>(lhs) == std::get<1>(rhs) &&
    CKObjectIsEqual(std::get<2>(lhs), std::get<2>(rhs));
  }
};

struct CKTreeNodeComponentKeyHasher {
  std::size_t operator() (const CKTreeNodeComponentKey &n) const
  {
    return [std::get<0>(n) hash] ^ std::get<1>(n) ^ [std::get<2>(n) hash];
  }
};

/** A map between CKTreeNodeComponentKey to counter; we use it to avoid collisions for identical keys */
using CKTreeNodeKeyToCounter = std::unordered_map<CKTreeNodeComponentKey, NSUInteger, CKTreeNodeComponentKeyHasher, CKTreeNodeComponentKeyComparator>;

