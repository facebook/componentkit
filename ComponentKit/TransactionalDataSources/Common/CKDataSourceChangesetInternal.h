/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKDataSourceChangeset.h>

/** Internal interface since this class is usually only consumed internally. */
@interface CKDataSourceChangeset<__covariant ModelType> ()

@property (nonatomic, copy, readonly) NSDictionary *updatedItems;
@property (nonatomic, copy, readonly) NSSet *removedItems;
@property (nonatomic, copy, readonly) NSIndexSet *removedSections;
@property (nonatomic, copy, readonly) NSDictionary *movedItems;
@property (nonatomic, copy, readonly) NSIndexSet *insertedSections;
@property (nonatomic, copy, readonly) NSDictionary *insertedItems;

/**
 Designated initializer. Any parameter may be nil.
 @param updatedItems Mapping from NSIndexPath to updated model.
 @param removedItems Set of NSIndexPath.
 @param removedSections NSIndexSet of section indices.
 @param movedItems Mapping from NSIndexPath to NSIndexPath.
 @param insertedSections NSIndexSet of section indices.
 @param insertedItems Mapping from NSIndexPath to new model.
 */
- (instancetype)initWithUpdatedItems:(NSDictionary<NSIndexPath *, ModelType> *)updatedItems
                        removedItems:(NSSet<NSIndexPath *> *)removedItems
                     removedSections:(NSIndexSet *)removedSections
                          movedItems:(NSDictionary<NSIndexPath *, NSIndexPath *> *)movedItems
                    insertedSections:(NSIndexSet *)insertedSections
                       insertedItems:(NSDictionary<NSIndexPath *, ModelType> *)insertedItems;

- (BOOL)isEmpty;

@end

namespace CK {
  auto changesetDescription(const CKDataSourceChangeset * changeset) -> NSString *;

  /**
   @return  `true` is the changeset may be valid, and `false` if it is definitely invalid.

   @discussion  This function performs a number of checks similar to what `UICollectionView` will do when performing
   batch updates. Not everything in a changeset can be validated without the actual data source state but these checks
   can be performed on a changeset alone. This helps with pinpointing the source of an invalid changeset.
   */
  auto changesetMayBeValid(const CKDataSourceChangeset *changeset) -> bool;
}
