/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

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
