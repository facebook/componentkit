/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKTransactionalComponentDataSourceConfiguration.h>

#import <ComponentKit/CKComponentScopeTypes.h>

#import <unordered_set>

@interface CKTransactionalComponentDataSourceConfiguration ()

/**
 @param componentProvider See @protocol(CKComponentProvider)
 @param context Passed to methods exposed by @protocol(CKComponentProvider).
 @param sizeRange Used for the root layout.
 @param alwaysSendComponentUpdate If set to YES, CKTransactionalComponentDataSource with this config will send component update events
                                  to component controllers even when they aren't in viewport
 @param workThreadOverride The optional thread used by the data source to perform its work instead of the internal
                           dispatch queue; if provided this thread must be executing.
 @param componentPredicates A vector of C functions that are executed on each component constructed within the scope
                            root. By passing in the predicates on initialization, we are able to cache which components
                            match the predicate for rapid enumeration later.
 @param componentControllerPredicates Same as componentPredicates above, but for component controllers.
 */
- (instancetype)initWithComponentProvider:(Class<CKComponentProvider>)componentProvider
                                  context:(id<NSObject>)context
                                sizeRange:(const CKSizeRange &)sizeRange
                alwaysSendComponentUpdate:(BOOL)alwaysSendComponentUpdate
                       workThreadOverride:(NSThread *)workThreadOverride
                      componentPredicates:(const std::unordered_set<CKComponentScopePredicate> &)componentPredicates
            componentControllerPredicates:(const std::unordered_set<CKComponentControllerScopePredicate> &)componentControllerPredicates;

@property (nonatomic, assign, readonly) BOOL alwaysSendComponentUpdate;

@property (nonatomic, strong, readonly) NSThread *workThreadOverride;

- (const std::unordered_set<CKComponentScopePredicate> &)componentPredicates;
- (const std::unordered_set<CKComponentControllerScopePredicate> &)componentControllerPredicates;

@end
