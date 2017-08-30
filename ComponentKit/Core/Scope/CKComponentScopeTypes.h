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

typedef std::unordered_map<CKComponentScopeHandleIdentifier, std::vector<id (^)(id)>> CKComponentStateUpdateMap;

@protocol CKScopedComponent;
@protocol CKScopedComponentController;

/**
 Enumerator blocks allow a consumer to enumerate over all of the components or controllers that matched a predicate.
 */
typedef void (^CKComponentScopeEnumerator)(id<CKScopedComponent>);
typedef void (^CKComponentControllerScopeEnumerator)(id<CKScopedComponentController>);

/**
 Scope predicates are a tool used by the framework to register components and controllers on initialization that have
 specific characteristics. These predicates allow rapid enumeration over matching components and controllers.
 */
#if !defined(NO_PROTOCOLS_IN_OBJCPP)
typedef BOOL (*CKComponentScopePredicate)(id<CKScopedComponent>);
typedef BOOL (*CKComponentControllerScopePredicate)(id<CKScopedComponentController>);
#else
typedef BOOL (*CKComponentScopePredicate)(id);
typedef BOOL (*CKComponentControllerScopePredicate)(id);
#endif

@protocol CKComponentScopeEnumeratorProvider <NSObject>

/**
 Allows rapid enumeration over the components or controllers that matched a predicate. The predicate should be provided
 in the initializer of the scope root in order to reduce the runtime costs of the enumeration.

 There is no guaranteed ordering of arguments that are provided to the enumerators.
 */
- (void)enumerateComponentsMatchingPredicate:(CKComponentScopePredicate)predicate
                                       block:(CKComponentScopeEnumerator)block;

- (void)enumerateComponentControllersMatchingPredicate:(CKComponentControllerScopePredicate)predicate
                                                 block:(CKComponentControllerScopeEnumerator)block;

@end
