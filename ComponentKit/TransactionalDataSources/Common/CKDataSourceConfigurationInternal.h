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

#import <ComponentKit/CKDataSourceConfiguration.h>

#import <ComponentKit/CKComponentScopeTypes.h>
#import <ComponentKit/CKDataSourceQOS.h>
#import <ComponentKit/CKBuildComponent.h>
#import <ComponentKit/CKOptional.h>

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

struct CKDataSourceOptions {
  CKDataSourceSplitChangesetOptions splitChangesetOptions;
  /**
   `componentController.component` will be updated right after commponent build if this is enabled.
   This is only for running expeirment in ComponentKit. Please DO NOT USE.
   */
  CK::Optional<BOOL> updateComponentInControllerAfterBuild = CK::none;
};

@interface CKDataSourceConfiguration ()

/**
 @param componentProvider The class that provides the component (@see CKComponentProvider).
 @param context Passed to methods exposed by the protocol CKComponentProvider (@see CKComponentProvider).
 @param sizeRange Used for the root layout.
 @param componentPredicates A vector of C functions that are executed on each component constructed within the scope
                            root. By passing in the predicates on initialization, we are able to cache which components
                            match the predicate for rapid enumeration later.
 @param componentControllerPredicates Same as componentPredicates above, but for component controllers.
 */
- (instancetype)initWithComponentProvider:(Class<CKComponentProvider>)componentProvider
                                  context:(id<NSObject>)context
                                sizeRange:(const CKSizeRange &)sizeRange
                                  options:(const CKDataSourceOptions &)options
                      componentPredicates:(const std::unordered_set<CKComponentPredicate> &)componentPredicates
            componentControllerPredicates:(const std::unordered_set<CKComponentControllerPredicate> &)componentControllerPredicates
                        analyticsListener:(id<CKAnalyticsListener>)analyticsListener;

- (instancetype)initWithComponentProviderFunc:(CKComponentProviderFunc)componentProvider
                                      context:(id<NSObject>)context
                                    sizeRange:(const CKSizeRange &)sizeRange
                                      options:(const CKDataSourceOptions &)options
                          componentPredicates:(const std::unordered_set<CKComponentPredicate> &)componentPredicates
                componentControllerPredicates:(const std::unordered_set<CKComponentControllerPredicate> &)componentControllerPredicates
                            analyticsListener:(id<CKAnalyticsListener>)analyticsListener;

- (instancetype)copyWithContext:(id<NSObject>)context sizeRange:(const CKSizeRange &)sizeRange;

@property (nonatomic, readonly, strong) id<CKAnalyticsListener> analyticsListener;

- (const std::unordered_set<CKComponentPredicate> &)componentPredicates;
- (const std::unordered_set<CKComponentControllerPredicate> &)componentControllerPredicates;

- (const CKDataSourceOptions &)options;

@end

#endif
