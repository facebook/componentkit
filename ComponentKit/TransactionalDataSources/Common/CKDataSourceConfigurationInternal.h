/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKDataSourceConfiguration.h>

#import <ComponentKit/CKComponentScopeTypes.h>

#import <unordered_set>

@protocol CKAnalyticsListener;

@interface CKDataSourceConfiguration ()

/**
 @param componentProvider See @protocol(CKComponentProvider)
 @param context Passed to methods exposed by @protocol(CKComponentProvider).
 @param sizeRange Used for the root layout.
 @param componentPredicates A vector of C functions that are executed on each component constructed within the scope
                            root. By passing in the predicates on initialization, we are able to cache which components
                            match the predicate for rapid enumeration later.
 @param componentControllerPredicates Same as componentPredicates above, but for component controllers.
 */
- (instancetype)initWithComponentProvider:(Class<CKComponentProvider>)componentProvider
                                  context:(id<NSObject>)context
                                sizeRange:(const CKSizeRange &)sizeRange
                       buildComponentTree:(BOOL)buildComponentTree
                 alwaysBuildComponentTree:(BOOL)alwaysBuildComponentTree
                      unifyBuildAndLayout:(BOOL)unifyBuildAndLayout
                              forceParent:(BOOL)forceParent
                      componentPredicates:(const std::unordered_set<CKComponentScopePredicate> &)componentPredicates
            componentControllerPredicates:(const std::unordered_set<CKComponentControllerScopePredicate> &)componentControllerPredicates
                        analyticsListener:(id<CKAnalyticsListener>)analyticsListener;

@property (nonatomic, readonly, strong) id<CKAnalyticsListener> analyticsListener;

@property (nonatomic, assign, readonly) BOOL buildComponentTree;
@property (nonatomic, assign, readonly) BOOL alwaysBuildComponentTree;
@property (nonatomic, assign, readonly) BOOL unifyBuildAndLayout;
@property (nonatomic, assign, readonly) BOOL forceParent;

- (const std::unordered_set<CKComponentScopePredicate> &)componentPredicates;
- (const std::unordered_set<CKComponentControllerScopePredicate> &)componentControllerPredicates;

@end
