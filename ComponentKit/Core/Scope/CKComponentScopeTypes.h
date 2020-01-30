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

#import <Foundation/Foundation.h>

#import <unordered_map>
#import <vector>

typedef int32_t CKComponentScopeHandleIdentifier;
typedef int32_t CKComponentScopeRootIdentifier;

@class CKComponentScopeHandle;

typedef std::unordered_map<CKComponentScopeHandle *, std::vector<id (^)(id)>> CKComponentStateUpdateMap;

@protocol CKComponentProtocol;
@protocol CKComponentControllerProtocol;
@protocol CKMountable;

/**
 Enumerator blocks allow a consumer to enumerate over all of the components or controllers that matched a predicate.
 */
typedef void (^CKComponentScopeEnumerator)(id<CKComponentProtocol>);
typedef void (^CKComponentControllerScopeEnumerator)(id<CKComponentControllerProtocol>);

/**
 Scope predicates are a tool used by the framework to register components and controllers on initialization that have
 specific characteristics. These predicates allow rapid enumeration over matching components and controllers.
 */
using CKComponentPredicate = BOOL (*)(id<CKComponentProtocol>);
using CKComponentControllerPredicate = BOOL (*)(id<CKComponentControllerProtocol>);
using CKMountablePredicate = BOOL (*)(id<CKMountable>);

#endif
