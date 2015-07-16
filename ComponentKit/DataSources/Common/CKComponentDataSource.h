/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant 
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <UIKit/UIKit.h>

#import <ComponentKit/CKArrayControllerChangeType.h>
#import <ComponentKit/CKArrayControllerChangeset.h>

#import <ComponentKit/CKMacros.h>
#import <ComponentKit/CKComponentPreparationQueueTypes.h>
#import <ComponentKit/CKDimension.h>

@class CKComponentDataSourceOutputItem;
@class CKComponentLifecycleManager;

@protocol CKComponentDataSourceDelegate;
@protocol CKComponentPreparationQueueListener;
@protocol CKComponentProvider;
@protocol CKComponentDeciding;

class CKComponentBoundsAnimation;

/**
 Given an input of model objects, we transform them asynchronously into instances of CKComponentLifecycleManagers.
 Implementations of UICollectionViewDataSource/UICollectionViewDelegate should defer to methods such as
 -numberOfObjectsInSection and -objectAtIndexPath: to implement -collectionView:numberOfItemsInSection: and
 -collectionView:cellForItemAtIndexPath:.
 
 @see CKCollectionViewDataSource for an example of use of CKComponentDataSource
 */
@interface CKComponentDataSource : NSObject

- (instancetype)init CK_NOT_DESIGNATED_INITIALIZER_ATTRIBUTE;

/**
 Designated initializer.
 @param componentProvider See @protocol(CKComponentProvider)
 @param context Passed to methods exposed by @protocol(CKComponentProvider).
 @param decider Allows for the data source to skip the creation of components. It can be used to progressively move things over to components.
 @returns An instance of CKComponentDataSource.
 */
- (instancetype)initWithComponentProvider:(Class<CKComponentProvider>)componentProvider
                                  context:(id<NSObject>)context
                                  decider:(id<CKComponentDeciding>)decider;

/**
 See CKComponentDataSourceDelegate.
 */
@property (readwrite, nonatomic, weak) id<CKComponentDataSourceDelegate> delegate;

- (NSInteger)numberOfSections;

- (NSInteger)numberOfObjectsInSection:(NSInteger)section;

- (CKComponentDataSourceOutputItem *)objectAtIndexPath:(NSIndexPath *)indexPath;

- (PreparationBatchID)enqueueChangeset:(const CKArrayControllerInputChangeset &)changeset constrainedSize:(const CKSizeRange &)constrainedSize;

/**
 Generates a changeset of update() commands for each object in the data source. The changeset is then enqueued and
 processed asynchronously as normal.

 This can be useful when responding to changes to global state (for example, changes to accessibility) so we can reflow
 all component hierarchies managed by the data source.
 */
- (void)enqueueReload;

/**
 Updates underlying context to the new value and enqueues reload so the component tree will respect the new context value.
 */
- (void)updateContextAndEnqeueReload:(id)newContext;

typedef void(^CKComponentDataSourceEnumerator)(CKComponentDataSourceOutputItem *, NSIndexPath *, BOOL *);

- (void)enumerateObjectsUsingBlock:(CKComponentDataSourceEnumerator)block;

- (void)enumerateObjectsInSectionAtIndex:(NSInteger)section usingBlock:(CKComponentDataSourceEnumerator)block;

typedef BOOL(^CKComponentDataSourcePredicate)(CKComponentDataSourceOutputItem *, NSIndexPath *, BOOL *);

/**
 @predicate Returning YES from the predicate will halt searching. Passing a nil predicate will return a {nil, nil} pair.
 @returns The object passing `predicate` and its corresponding index path. Nil in both fields indicates nothing passed.
 This will always return both fields as nil or non-nil.
 */
- (std::pair<CKComponentDataSourceOutputItem *, NSIndexPath *>)firstObjectPassingTest:(CKComponentDataSourcePredicate)predicate;

/**
 This is O(N).
 */
- (std::pair<CKComponentDataSourceOutputItem *, NSIndexPath *>)objectForUUID:(NSString *)UUID;

/**
 @return YES if the datasource has changesets currently enqueued.
 */
- (BOOL)isComputingChanges;

/**
 Allows adding/removing listeners to hear events on the CKComponentPreparationQueue, which is wrapped within CKComponentDataSource.
 */
- (void)addListener:(id<CKComponentPreparationQueueListener>)listener;
- (void)removeListener:(id<CKComponentPreparationQueueListener>)listener;

@end

typedef CKArrayControllerOutputChangeset(^ck_changeset_applicator_t)(void);

typedef NS_OPTIONS(NSUInteger, CKComponentDataSourceChangeType) {
  CKComponentDataSourceChangeTypeInsertSections = 1 << 0,
  CKComponentDataSourceChangeTypeDeleteSections = 1 << 1,
  CKComponentDataSourceChangeTypeMoveSections = 1 << 2,
  CKComponentDataSourceChangeTypeInsertRows = 1 << 3,
  CKComponentDataSourceChangeTypeDeleteRows = 1 << 4,
  CKComponentDataSourceChangeTypeMoveRows = 1 << 5,
  /** A row has been updated **and** its size changed. (There is no type for updating a row without a size change.) */
  CKComponentDataSourceChangeTypeUpdateSize = 1 << 6,
};

@protocol CKComponentDataSourceDelegate <NSObject>

/**
 Called when a new changeset is ready to be applied

 @param changesetApplicator A block that when executed returns the changeset. You can then map over this changeset to apply it to a TableView
 or CollectionView.
 @param ticker The ticker has to be called to signal the componentDataSource that the caller is ready to receive a new changeset. The ticker is here
 originally to work around a bug in UICollectionViews. Applying a new changeset to a collectionView while the previous one has not been completely applied
 could cause the collectionView to lose track of its internal state and have duplicate entries, for this reason and when a changeset is aplied to a
 collectionView the ticker should be called in the completion block of -(void)performBatchUpdates:Completion:
 */
- (void)componentDataSource:(CKComponentDataSource *)componentDataSource
          hasChangesOfTypes:(CKComponentDataSourceChangeType)changeTypes
        changesetApplicator:(ck_changeset_applicator_t)changesetApplicator;

/**
 Sent when the size of a given component has changed due to a state update (versus a model change).
 The component's view (if any) has already been updated; you will need to signal the component's parent view to update
 its layout (e.g. calling -invalidateLayout on a UICollectionView's layout).
 */
- (void)componentDataSource:(CKComponentDataSource *)componentDataSource
     didChangeSizeForObject:(CKComponentDataSourceOutputItem *)object
                atIndexPath:(NSIndexPath *)indexPath
                  animation:(const CKComponentBoundsAnimation &)animation;

@end
