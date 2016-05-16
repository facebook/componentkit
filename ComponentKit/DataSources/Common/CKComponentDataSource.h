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
                                  decider:(Class<CKComponentDeciding>)decider;

/**
 @see `CKComponentDataSourceDelegate`
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
- (void)updateContextAndEnqueueReload:(id)newContext;

typedef void(^CKComponentDataSourceEnumerator)(CKComponentDataSourceOutputItem *, NSIndexPath *, BOOL *);

- (void)enumerateObjectsUsingBlock:(CKComponentDataSourceEnumerator)block;

- (void)enumerateObjectsInSectionAtIndex:(NSInteger)section usingBlock:(CKComponentDataSourceEnumerator)block;

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
