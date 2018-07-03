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
#import <ComponentKit/CKDataSourceQOS.h>

#import <unordered_set>

@protocol CKAnalyticsListener;

struct CKDataSourceQOSOptions {
  CKDataSourceQOS workQueueQOS = CKDataSourceQOSDefault;
  CKDataSourceQOS concurrentQueueQOS = CKDataSourceQOSDefault;
};

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
                      unifyBuildAndLayout:(BOOL)unifyBuildAndLayout
                              forceParent:(BOOL)forceParent
             parallelInsertBuildAndLayout:(BOOL)parallelInsertBuildAndLayout
    parallelInsertBuildAndLayoutThreshold:(NSUInteger)parallelInsertBuildAndLayoutThreshold
             parallelUpdateBuildAndLayout:(BOOL)parallelUpdateBuildAndLayout
    parallelUpdateBuildAndLayoutThreshold:(NSUInteger)parallelUpdateBuildAndLayoutThreshold
                      componentPredicates:(const std::unordered_set<CKComponentScopePredicate> &)componentPredicates
            componentControllerPredicates:(const std::unordered_set<CKComponentControllerScopePredicate> &)componentControllerPredicates
                        analyticsListener:(id<CKAnalyticsListener>)analyticsListener
                               qosOptions:(CKDataSourceQOSOptions)qosOptions;

@property (nonatomic, readonly, strong) id<CKAnalyticsListener> analyticsListener;

@property (nonatomic, assign, readonly) BOOL unifyBuildAndLayout;
@property (nonatomic, assign, readonly) BOOL forceParent;
@property (nonatomic, assign, readonly) BOOL parallelInsertBuildAndLayout;
@property (nonatomic, assign, readonly) NSUInteger parallelInsertBuildAndLayoutThreshold;
@property (nonatomic, assign, readonly) BOOL parallelUpdateBuildAndLayout;
@property (nonatomic, assign, readonly) NSUInteger parallelUpdateBuildAndLayoutThreshold;
@property (nonatomic, assign, readonly) CKDataSourceQOSOptions qosOptions;

- (const std::unordered_set<CKComponentScopePredicate> &)componentPredicates;
- (const std::unordered_set<CKComponentControllerScopePredicate> &)componentControllerPredicates;

@end
