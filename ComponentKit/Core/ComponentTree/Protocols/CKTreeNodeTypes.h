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

/** Unique identifier for tree nodes. */
typedef int32_t CKTreeNodeIdentifier;
/** A key between a tree ndoe to its parent */
typedef std::tuple<Class, NSUInteger> CKTreeNodeComponentKey;
/** unordered_set of all the "dirty" tree nodes' identifiers; "dirty" means node on a state update branch. */
typedef std::unordered_set<CKTreeNodeIdentifier> CKTreeNodeDirtyIds;
