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
#import <ComponentKit/CKDataSourceAnimationOptions.h>
#import <ComponentKit/CKDataSourceQOS.h>
#import <ComponentKit/CKBuildComponent.h>

#import <unordered_set>

@protocol CKAnalyticsListener;

struct CKDataSourceQOSOptions {
  BOOL enabled = NO;
  CKDataSourceQOS workQueueQOS = CKDataSourceQOSDefault;
  CKDataSourceQOS concurrentQueueQOS = CKDataSourceQOSDefault;
};

@interface CKDataSourceConfiguration ()

/**
 @param componentProvider See @protocol(CKComponentProvider)
 @param context Passed to methods exposed by @protocol(CKComponentProvider).
 @param sizeRange Used for the root layout.
 @param workQueue Queue used for processing asynchronous state updates.
 @param applyChangesetsOnWorkQueue Normally, changesets must be applied on the main thread. Specifying
 this option will allow you to call -applyChangeset:mode:userInfo: on `workQueue` instead, where
 synchronous updates will be applied immediately on the queue and asynchronous updates will be enqueued
 to execute asynchronously on the work queue. If this is set to `YES`, all methods called on the data
 source must be called on the work queue rather than the main thread.
 @param componentPredicates A vector of C functions that are executed on each component constructed within the scope
                            root. By passing in the predicates on initialization, we are able to cache which components
                            match the predicate for rapid enumeration later.
 @param componentControllerPredicates Same as componentPredicates above, but for component controllers.
 */
- (instancetype)initWithComponentProvider:(Class<CKComponentProvider>)componentProvider
                                  context:(id<NSObject>)context
                                sizeRange:(const CKSizeRange &)sizeRange
                     buildComponentConfig:(const CKBuildComponentConfig &)buildComponentConfig
                               qosOptions:(const CKDataSourceQOSOptions &)qosOptions
                                workQueue:(dispatch_queue_t)workQueue
               applyChangesetsOnWorkQueue:(BOOL)applyChangesetsOnWorkQueue
                      unifyBuildAndLayout:(BOOL)unifyBuildAndLayout
             parallelInsertBuildAndLayout:(BOOL)parallelInsertBuildAndLayout
    parallelInsertBuildAndLayoutThreshold:(NSUInteger)parallelInsertBuildAndLayoutThreshold
             parallelUpdateBuildAndLayout:(BOOL)parallelUpdateBuildAndLayout
    parallelUpdateBuildAndLayoutThreshold:(NSUInteger)parallelUpdateBuildAndLayoutThreshold
                         animationOptions:(const CKDataSourceAnimationOptions &)animationOptions
                      componentPredicates:(const std::unordered_set<CKComponentPredicate> &)componentPredicates
            componentControllerPredicates:(const std::unordered_set<CKComponentControllerPredicate> &)componentControllerPredicates
                        analyticsListener:(id<CKAnalyticsListener>)analyticsListener;

@property (nonatomic, readonly, strong) id<CKAnalyticsListener> analyticsListener;

@property (nonatomic, strong, readonly) dispatch_queue_t workQueue;
@property (nonatomic, assign, readonly) BOOL applyChangesetsOnWorkQueue;
@property (nonatomic, assign, readonly) BOOL unifyBuildAndLayout;
@property (nonatomic, assign, readonly) BOOL parallelInsertBuildAndLayout;
@property (nonatomic, assign, readonly) NSUInteger parallelInsertBuildAndLayoutThreshold;
@property (nonatomic, assign, readonly) BOOL parallelUpdateBuildAndLayout;
@property (nonatomic, assign, readonly) NSUInteger parallelUpdateBuildAndLayoutThreshold;

- (const std::unordered_set<CKComponentPredicate> &)componentPredicates;
- (const std::unordered_set<CKComponentControllerPredicate> &)componentControllerPredicates;

- (const CKBuildComponentConfig &)buildComponentConfig;
- (const CKDataSourceQOSOptions &)qosOptions;
- (const CKDataSourceAnimationOptions &)animationOptions;

@end
