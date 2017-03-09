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

#import <unordered_map>

typedef int32_t CKComponentScopeHandleIdentifier;
typedef int32_t CKComponentScopeRootIdentifier;

typedef std::unordered_multimap<CKComponentScopeHandleIdentifier, id (^)(id)> CKComponentStateUpdateMap;
