/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKDefines.h>

#if CK_NOT_SWIFT

#include <unordered_map>

#import <Foundation/Foundation.h>

struct StringHasher {
  size_t operator()(const NSString *const &obj) const {
    return [obj hash];
  }
};

struct StringEquality {
  bool operator()(const NSString *const &left, const NSString *const &right) const {
    return [left isEqual:right];
  }
};

typedef id(*CKUserInfoMergeFunc)(id, id);
using CKUserInfoMergeMap = std::unordered_map<NSString *, CKUserInfoMergeFunc, StringHasher, StringEquality>;

struct CKStateUpdateMetadata {
  // Info provided by the user that will be associated with the state update.
  NSDictionary<NSString *, id> *userInfo;

  // In the event that two updates for the same component are processed at once,
  // this map allows you to describe how the map should merge values for the same key.
  CKUserInfoMergeMap userInfoMergeMap;
};

#endif
