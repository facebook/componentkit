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
#import <ComponentKit/CKBuildComponent.h>

#import <unordered_set>

@protocol CKAnalyticsListener;
@protocol CKComponentStateListener;

typedef NS_ENUM(NSInteger, CKDataSourceLayoutAxis) {
  CKDataSourceLayoutAxisVertical,
  CKDataSourceLayoutAxisHorizontal
};

/**
 * Configuration for splitting changesets so that the part of the changeset that fills
 * the viewport with the specified bounding size gets applied first, and the second
 * part of the changeset is deferred until immediately after.
 */
struct CKDataSourceSplitChangesetOptions {
  /** Whether changeset splitting is enabled. */
  BOOL enabled = NO;

  /**
   * Whether updates for items not in the viewport should also be split to a
   * deferred changeset. The default behavior is to only split for insertions.
   */
  BOOL splitUpdates = NO;

  /**
   * The size of the viewport to use for component layout. Any components that are laid out outside
   * this bounding size are deferred to a second changeset.
   */
  CGSize viewportBoundingSize = CGSizeZero;
  /**
   * The direction in which components are being laid out. This, along with `viewportBoundingSize`
   * is used to compute whether a component layout is outside of the bounds of the viewport.
   */
  CKDataSourceLayoutAxis layoutAxis = CKDataSourceLayoutAxisVertical;
};

@interface CKDataSourceConfiguration ()

/**
 @param componentProvider See @protocol(CKComponentProvider)
 @param context Passed to methods exposed by @protocol(CKComponentProvider).
 @param sizeRange Used for the root layout.
 @param workQueue Queue used for processing asynchronous state updates.
 @param applyModificationsOnWorkQueue Normally, modifications must be applied on the main thread.
 Specifying this option will allow you to call -applyChangeset:mode:userInfo: on `workQueue` instead, where
 synchronous updates will be applied immediately on the queue and asynchronous updates will be enqueued
 to execute asynchronously on the work queue. If this is set to `YES`, all methods called on the data
 source must be called on the work queue rather than the main thread.
 @param componentPredicates A vector of C functions that are executed on each component constructed within the scope
                            root. By passing in the predicates on initialization, we are able to cache which components
                            match the predicate for rapid enumeration later.
 @param componentControllerPredicates Same as componentPredicates above, but for component controllers.
 @param stateListener A state listener that listens to state updates from the generated components. If
 unspecified, this defaults to the data source itself.
 */
- (instancetype)initWithComponentProvider:(Class<CKComponentProvider>)componentProvider
                                  context:(id<NSObject>)context
                                sizeRange:(const CKSizeRange &)sizeRange
                     buildComponentConfig:(const CKBuildComponentConfig &)buildComponentConfig
                    splitChangesetOptions:(const CKDataSourceSplitChangesetOptions &)splitChangesetOptions
                                workQueue:(dispatch_queue_t)workQueue
            applyModificationsOnWorkQueue:(BOOL)applyModificationsOnWorkQueue
                      componentPredicates:(const std::unordered_set<CKComponentPredicate> &)componentPredicates
            componentControllerPredicates:(const std::unordered_set<CKComponentControllerPredicate> &)componentControllerPredicates
                        analyticsListener:(id<CKAnalyticsListener>)analyticsListener
                            stateListener:(id<CKComponentStateListener>)stateListener;

- (instancetype)initWithComponentProviderFunc:(CKComponentProviderFunc)componentProvider
                                      context:(id<NSObject>)context
                                    sizeRange:(const CKSizeRange &)sizeRange
                         buildComponentConfig:(const CKBuildComponentConfig &)buildComponentConfig
                        splitChangesetOptions:(const CKDataSourceSplitChangesetOptions &)splitChangesetOptions
                                    workQueue:(dispatch_queue_t)workQueue
                applyModificationsOnWorkQueue:(BOOL)applyModificationsOnWorkQueue
                          componentPredicates:(const std::unordered_set<CKComponentPredicate> &)componentPredicates
                componentControllerPredicates:(const std::unordered_set<CKComponentControllerPredicate> &)componentControllerPredicates
                            analyticsListener:(id<CKAnalyticsListener>)analyticsListener
                                stateListener:(id<CKComponentStateListener>)stateListener;

- (instancetype)copyWithContext:(id<NSObject>)context sizeRange:(const CKSizeRange &)sizeRange;

@property (nonatomic, readonly, strong) id<CKAnalyticsListener> analyticsListener;
@property (nonatomic, readonly, strong) id<CKComponentStateListener> stateListener;

@property (nonatomic, strong, readonly) dispatch_queue_t workQueue;
@property (nonatomic, assign, readonly) BOOL applyModificationsOnWorkQueue;

- (const std::unordered_set<CKComponentPredicate> &)componentPredicates;
- (const std::unordered_set<CKComponentControllerPredicate> &)componentControllerPredicates;

- (const CKBuildComponentConfig &)buildComponentConfig;
- (const CKDataSourceSplitChangesetOptions &)splitChangesetOptions;

@end
