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

#import <unordered_set>

#import <ComponentKit/CKComponentScopeTypes.h>

@protocol CKComponentStateListener;
@protocol CKAnalyticsListener;

@class CKComponentScopeRoot;

/**
 Initializes a CKComponentScopeRoot with the normal, infrastructure-provided predicates necessary for the framework
 to work. You should use this function to create scope roots unless you really know what you're doing.
 */
CKComponentScopeRoot *CKComponentScopeRootWithDefaultPredicates(id<CKComponentStateListener> listener,
                                                                id<CKAnalyticsListener> analyticsListener);

/**
 Initializes a CKComponentScopeRoot with your provided predicates in addition to the normal, infrastructure-provided
 predicates necessary for the framework to work.
 @param componentPredicates A vector of C functions that are executed on each component constructed within the scope
                            root. By passing in the predicates on initialization, we are able to cache which components
                            match the predicate for rapid enumeration later.
 @param componentControllerPredicates Same as componentPredicates above, but for component controllers.
 */
CKComponentScopeRoot *CKComponentScopeRootWithPredicates(id<CKComponentStateListener> listener,
                                                         id<CKAnalyticsListener> analyticsListener,
                                                         const std::unordered_set<CKComponentPredicate> &componentPredicates,
                                                         const std::unordered_set<CKComponentControllerPredicate> &componentControllerPredicates);

#endif
