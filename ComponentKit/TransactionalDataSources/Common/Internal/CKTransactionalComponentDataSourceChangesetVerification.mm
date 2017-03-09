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

#import "CKTransactionalComponentDataSourceChangesetVerification.h"

#import <ComponentKit/CKTransactionalComponentDataSourceChangesetInternal.h>
#import <ComponentKit/CKTransactionalComponentDataSourceChangesetModification.h>
#import <ComponentKit/CKTransactionalComponentDataSourceStateInternal.h>

static NSArray<NSNumber *> *sectionCountsWithModificationsFoldedIntoState(CKTransactionalComponentDataSourceState *state,
                                                                          NSArray<id<CKTransactionalComponentDataSourceStateModifying>> *modifications);

static NSArray<NSNumber *> *sectionCountsForState(CKTransactionalComponentDataSourceState *state);

static NSArray<NSNumber *> *updatedSectionCountsWithModification(NSArray<NSNumber *> *sectionCounts,
                                                                 CKTransactionalComponentDataSourceChangesetModification *changesetModification);

static NSArray<NSIndexPath *> *sortedIndexPaths(NSArray<NSIndexPath *> *indexPaths);

CKBadChangesetOperationType CKIsValidChangesetForState(CKTransactionalComponentDataSourceChangeset *changeset,
                                                       CKTransactionalComponentDataSourceState *state,
                                                       NSArray<id<CKTransactionalComponentDataSourceStateModifying>> *pendingAsynchronousModifications)
{
  /*
   "Fold" any pending asynchronous modifications into the supplied state and compute the number of items in each section.
   This process ensures that the modified state represents the state the changeset will be eventually applied to.
   */
  NSMutableArray<NSNumber *> *sectionCounts = [sectionCountsWithModificationsFoldedIntoState(state, pendingAsynchronousModifications) mutableCopy];
  NSArray *originalSectionCounts = [sectionCounts copy];
  __block BOOL invalidChangeFound = NO;
  // Updated items
  [changeset.updatedItems enumerateKeysAndObjectsUsingBlock:^(NSIndexPath * _Nonnull fromIndexPath, id _Nonnull model, BOOL * _Nonnull stop) {
    const NSInteger section = fromIndexPath.section;
    const NSInteger item = fromIndexPath.item;
    if (section >= originalSectionCounts.count
        || item >= [originalSectionCounts[section] integerValue]
        || section < 0
        || item < 0) {
      invalidChangeFound = YES;
      *stop = YES;
    }
  }];
  if (invalidChangeFound) {
    return CKBadChangesetOperationTypeUpdate;
  }
  /*
   Removed items
   Section counts may not immediately reflect removals as order is not guaranteed and may result in a false positive.
   As long as each item is located within the bounds of its section the changeset is valid.
   */
  NSMutableDictionary<NSNumber *, NSMutableIndexSet *> *itemsToRemove = [NSMutableDictionary new];
  [changeset.removedItems enumerateObjectsUsingBlock:^(NSIndexPath *_Nonnull fromIndexPath, BOOL * _Nonnull stop) {
    const NSInteger section = fromIndexPath.section;
    const NSInteger item = fromIndexPath.item;
    if (section >= sectionCounts.count
        || section < 0
        || item >= [originalSectionCounts[section] integerValue]) {
      invalidChangeFound = YES;
      *stop = YES;
    } else {
      if (!itemsToRemove[@(section)]) {
        itemsToRemove[@(section)] = [NSMutableIndexSet indexSet];
      }
      [itemsToRemove[@(section)] addIndex:item];
    }
  }];
  if (invalidChangeFound) {
    return CKBadChangesetOperationTypeRemoveRow;
  } else {
    [itemsToRemove enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull section, NSMutableIndexSet * _Nonnull indexSet, BOOL * _Nonnull stop) {
      sectionCounts[[section integerValue]] = @([sectionCounts[[section integerValue]] integerValue] - [indexSet count]);
    }];
  }
  /*
   Removed sections
   Section counts may not immediately reflect removals as order is not guaranteed and may result in a false positive.
   As long as each section is located within the bounds of all sections the changeset is valid.
   */
  NSMutableIndexSet *sectionsToRemove = [NSMutableIndexSet indexSet];
  [changeset.removedSections enumerateIndexesUsingBlock:^(NSUInteger fromSection, BOOL * _Nonnull stop) {
    if (fromSection >= originalSectionCounts.count) {
      invalidChangeFound = YES;
      *stop = YES;
    } else {
      [sectionsToRemove addIndex:fromSection];
    }
  }];
  if (invalidChangeFound) {
    return CKBadChangesetOperationTypeRemoveSection;
  } else {
    [sectionCounts removeObjectsAtIndexes:sectionsToRemove];
  }
  /*
   Inserted sections
   Section counts may immediately reflect insertions as they are guaranteed to be contiguous by virtue of NSIndexSet.
   As long as each section is located within the bounds of all sections the changeset is valid.
   */
  [changeset.insertedSections enumerateIndexesUsingBlock:^(NSUInteger toSection, BOOL * _Nonnull stop) {
    if (toSection > sectionCounts.count) {
      invalidChangeFound = YES;
      *stop = YES;
    } else {
      [sectionCounts insertObject:@0 atIndex:toSection];
    }
  }];
  if (invalidChangeFound) {
    return CKBadChangesetOperationTypeInsertSection;
  }
  /*
   Inserted items
   Section counts may immediately reflect insertions as they are guaranteed to be contiguous by virtue of sorting the index paths.
   As long as each item is located within the bounds of its section the changeset is valid.
   */
  [sortedIndexPaths(changeset.insertedItems.allKeys) enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull toIndexPath, NSUInteger index, BOOL * _Nonnull stop) {
    const NSInteger section = toIndexPath.section;
    const NSInteger item = toIndexPath.item;
    if (section >= sectionCounts.count
        || section < 0
        || item > [sectionCounts[section] integerValue]) {
      invalidChangeFound = YES;
      *stop = YES;
    } else {
      sectionCounts[section] = @([sectionCounts[section] integerValue] + 1);
    }
  }];
  if (invalidChangeFound) {
    return CKBadChangesetOperationTypeInsertRow;
  }
  // Moved items
  [changeset.movedItems enumerateKeysAndObjectsUsingBlock:^(NSIndexPath * _Nonnull fromIndexPath, NSIndexPath * _Nonnull toIndexPath, BOOL * _Nonnull stop) {
    const BOOL fromIndexPathSectionInvalid = fromIndexPath.section >= sectionCounts.count;
    const BOOL toIndexPathSectionInvalid = toIndexPath.section >= sectionCounts.count;
    if (fromIndexPathSectionInvalid || toIndexPathSectionInvalid) {
      invalidChangeFound = YES;
      *stop = YES;
    } else {
      const BOOL fromIndexPathItemInvalid = fromIndexPath.item >= [originalSectionCounts[fromIndexPath.section] integerValue];
      const BOOL toIndexPathItemInvalid = ((fromIndexPath.section == toIndexPath.section)
                                           ? toIndexPath.item >= [sectionCounts[toIndexPath.section] integerValue]
                                           : toIndexPath.item > [sectionCounts[toIndexPath.section] integerValue]);
      if (fromIndexPathItemInvalid || toIndexPathItemInvalid) {
        invalidChangeFound = YES;
        *stop = YES;
      } else {
        sectionCounts[fromIndexPath.section] = @([sectionCounts[fromIndexPath.section] integerValue] - 1);
        sectionCounts[toIndexPath.section] = @([sectionCounts[toIndexPath.section] integerValue] + 1);
      }
    }
  }];
  return invalidChangeFound ? CKBadChangesetOperationTypeMoveRow : CKBadChangesetOperationTypeNone;
}

static NSArray<NSNumber *> *sectionCountsWithModificationsFoldedIntoState(CKTransactionalComponentDataSourceState *state,
                                                                          NSArray<id<CKTransactionalComponentDataSourceStateModifying>> *modifications)
{
  NSArray<NSNumber *> *sectionCounts = sectionCountsForState(state);
  for (id<CKTransactionalComponentDataSourceStateModifying> modification in modifications) {
    if ([modification isKindOfClass:[CKTransactionalComponentDataSourceChangesetModification class]]) {
      sectionCounts = updatedSectionCountsWithModification(sectionCounts, modification);
    }
  }
  return sectionCounts;
}

static NSArray<NSNumber *> *sectionCountsForState(CKTransactionalComponentDataSourceState *state)
{
  NSMutableArray *sectionCounts = [NSMutableArray new];
  for (NSArray *section in state.sections) {
    [sectionCounts addObject:@(section.count)];
  }
  return sectionCounts;
}

static NSArray<NSNumber *> *updatedSectionCountsWithModification(NSArray<NSNumber *> *sectionCounts,
                                                                 CKTransactionalComponentDataSourceChangesetModification *changesetModification)
{
  CKTransactionalComponentDataSourceChangeset *changeset = changesetModification.changeset;
  NSMutableArray *updatedSectionCounts = [sectionCounts mutableCopy];
  // Move items
  [changeset.movedItems enumerateKeysAndObjectsUsingBlock:^(NSIndexPath * _Nonnull fromIndexPath, NSIndexPath * _Nonnull toIndexPath, BOOL * _Nonnull stop) {
    // "Remove" the item
    updatedSectionCounts[fromIndexPath.section] = @([updatedSectionCounts[fromIndexPath.section] integerValue] - 1);
    // "Insert" the item
    updatedSectionCounts[toIndexPath.section] = @([updatedSectionCounts[toIndexPath.section] integerValue] + 1);
  }];
  // Remove items
  [changeset.removedItems enumerateObjectsUsingBlock:^(NSIndexPath *_Nonnull indexPath, BOOL * _Nonnull stop) {
    updatedSectionCounts[indexPath.section] = @([updatedSectionCounts[indexPath.section] integerValue] - 1);
  }];
  // Remove sections
  [updatedSectionCounts removeObjectsAtIndexes:changeset.removedSections];
  // Insert sections
  NSMutableArray *emptySections = [NSMutableArray new];
  for (NSUInteger i = 0; i < changeset.insertedSections.count; i++) {
    [emptySections addObject:@0];
  }
  [updatedSectionCounts insertObjects:emptySections atIndexes:changeset.insertedSections];
  // Insert items
  [changeset.insertedItems enumerateKeysAndObjectsUsingBlock:^(NSIndexPath * _Nonnull indexPath, id _Nonnull model, BOOL * _Nonnull stop) {
    updatedSectionCounts[indexPath.section] = @([updatedSectionCounts[indexPath.section] integerValue] + 1);
  }];
  return updatedSectionCounts;
}

static NSArray<NSIndexPath *> *sortedIndexPaths(NSArray<NSIndexPath *> *indexPaths)
{
  return [indexPaths sortedArrayUsingSelector:@selector(compare:)];
}
