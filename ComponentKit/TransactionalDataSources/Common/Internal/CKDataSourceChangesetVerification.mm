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

#import "CKFatal.h"
#import "CKDataSourceChangesetVerification.h"

#import <ComponentKit/CKDataSourceChangesetInternal.h>
#import <ComponentKit/CKDataSourceChangesetModification.h>
#import <ComponentKit/CKDataSourceSplitChangesetModification.h>
#import <ComponentKit/CKDataSourceStateInternal.h>
#import <ComponentKit/CKIndexTransform.h>

static NSArray<NSNumber *> *sectionCountsWithModificationsFoldedIntoState(CKDataSourceState *state,
                                                                          NSArray<id<CKDataSourceStateModifying>> *modifications);

static NSArray<NSNumber *> *sectionCountsForState(CKDataSourceState *state);

static CKDataSourceChangeset *changesetFromModification(id<CKDataSourceStateModifying> modification);

static NSArray<NSNumber *> *updatedSectionCountsWithChangeset(NSArray<NSNumber *> *sectionCounts,
                                                              CKDataSourceChangeset *changeset);

static NSArray<NSIndexPath *> *sortedIndexPaths(NSArray<NSIndexPath *> *indexPaths);

CKInvalidChangesetInfo CKIsValidChangesetForState(CKDataSourceChangeset *changeset,
                                                  CKDataSourceState *state,
                                                  NSArray<id<CKDataSourceStateModifying>> *pendingAsynchronousModifications)
{
  /*
   "Fold" any pending asynchronous modifications into the supplied state and compute the number of items in each section.
   This process ensures that the modified state represents the state the changeset will be eventually applied to.
   */
  NSMutableArray<NSNumber *> *sectionCounts = [sectionCountsWithModificationsFoldedIntoState(state, pendingAsynchronousModifications) mutableCopy];
  NSMutableArray<NSNumber *> *originalSectionCounts = [sectionCounts mutableCopy];
  __block BOOL invalidChangeFound = NO;
  __block NSInteger invalidSection = -1;
  __block NSInteger invalidItem = -1;
  // Updated items
  [changeset.updatedItems enumerateKeysAndObjectsUsingBlock:^(NSIndexPath * _Nonnull fromIndexPath, id _Nonnull model, BOOL * _Nonnull stop) {
    const NSInteger section = fromIndexPath.section;
    const NSInteger item = fromIndexPath.item;
    if (section >= originalSectionCounts.count
        || item >= [originalSectionCounts[section] integerValue]
        || section < 0
        || item < 0) {
      invalidChangeFound = YES;
      invalidSection = section;
      invalidItem = item;
      *stop = YES;
    }
  }];
  if (invalidChangeFound) {
    return { CKInvalidChangesetOperationTypeUpdate, invalidSection, invalidItem };
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
      invalidSection = section;
      invalidItem = item;
      *stop = YES;
    } else {
      if (!itemsToRemove[@(section)]) {
        itemsToRemove[@(section)] = [NSMutableIndexSet indexSet];
      }
      [itemsToRemove[@(section)] addIndex:item];
    }
  }];
  if (invalidChangeFound) {
    return { CKInvalidChangesetOperationTypeRemoveRow, invalidSection, invalidItem };
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
      invalidSection = fromSection;
      *stop = YES;
    } else {
      [sectionsToRemove addIndex:fromSection];
    }
  }];
  if (invalidChangeFound) {
    return { CKInvalidChangesetOperationTypeRemoveSection, invalidSection, invalidItem };
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
      invalidSection = toSection;
      *stop = YES;
    } else {
      [sectionCounts insertObject:@0 atIndex:toSection];
    }
  }];
  if (invalidChangeFound) {
    return { CKInvalidChangesetOperationTypeInsertSection, invalidSection, invalidItem };
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
      invalidSection = section;
      invalidItem = item;
      *stop = YES;
    } else {
      sectionCounts[section] = @([sectionCounts[section] integerValue] + 1);
    }
  }];
  if (invalidChangeFound) {
    return { CKInvalidChangesetOperationTypeInsertRow, invalidSection, invalidItem };
  }
  // Moved items
  const auto sectionIdxTransform =
  CK::makeCompositeIndexTransform(CK::RemovalIndexTransform(changeset.removedSections),
                                  CK::InsertionIndexTransform(changeset.insertedSections));
  
  [changeset.movedItems enumerateKeysAndObjectsUsingBlock:^(NSIndexPath * _Nonnull fromIndexPath, NSIndexPath * _Nonnull toIndexPath, BOOL * _Nonnull stop) {
    const BOOL fromIndexPathSectionInvalid = fromIndexPath.section >= originalSectionCounts.count;
    const BOOL toIndexPathSectionInvalid = toIndexPath.section >= sectionCounts.count;
    if (fromIndexPathSectionInvalid || toIndexPathSectionInvalid) {
      invalidChangeFound = YES;
      invalidSection = fromIndexPathSectionInvalid ? fromIndexPath.section : toIndexPath.section;
      *stop = YES;
    } else {
      const BOOL fromIndexPathItemInvalid = fromIndexPath.item >= [originalSectionCounts[fromIndexPath.section] integerValue];
      originalSectionCounts[fromIndexPath.section] = @([originalSectionCounts[fromIndexPath.section] integerValue] - 1);
      const auto fromSectionIdxAfterUpdate = sectionIdxTransform.applyToIndex(fromIndexPath.section);
      if (fromSectionIdxAfterUpdate != NSNotFound) {
        sectionCounts[fromSectionIdxAfterUpdate] = @([sectionCounts[fromSectionIdxAfterUpdate] integerValue] - 1);
      }
      const auto originalSectionIdx = sectionIdxTransform.applyInverseToIndex(toIndexPath.section);
      const auto movingToJustInsertedSection = (originalSectionIdx == NSNotFound);
      if (!movingToJustInsertedSection) {
        originalSectionCounts[originalSectionIdx] = @([originalSectionCounts[originalSectionIdx] integerValue] + 1);
      }
      const auto toIndexPathItemInvalid = toIndexPath.item > [sectionCounts[toIndexPath.section] integerValue];
      sectionCounts[toIndexPath.section] = @([sectionCounts[toIndexPath.section] integerValue] + 1);
      if (fromIndexPathItemInvalid || toIndexPathItemInvalid) {
        invalidSection = fromIndexPathItemInvalid ? fromIndexPath.section : toIndexPath.section;
        invalidItem = fromIndexPathItemInvalid ? fromIndexPath.row : toIndexPath.row;
        invalidChangeFound = YES;
        *stop = YES;
      }
    }
  }];
  return {
    invalidChangeFound ? CKInvalidChangesetOperationTypeMoveRow : CKInvalidChangesetOperationTypeNone,
    invalidSection,
    invalidItem
  };
}

static NSString *readableStringForArray(NSArray *array)
{
  if (!array || array.count == 0) {
    return @"()";
  }
  NSMutableString *mutableString = [NSMutableString new];
  [mutableString appendFormat:@"(\n"];
  for (id value in array) {
    [mutableString appendFormat:@"\t%@,\n", value];
  }
  [mutableString appendString:@")\n"];
  return mutableString;
}

void CKVerifyChangeset(CKDataSourceChangeset *changeset,
                       CKDataSourceState *state,
                       NSArray<id<CKDataSourceStateModifying>> *pendingAsynchronousModifications)
{
  const CKInvalidChangesetInfo invalidChangesetInfo = CKIsValidChangesetForState(changeset,
                                                                                 state,
                                                                                 pendingAsynchronousModifications);
  if (invalidChangesetInfo.operationType != CKInvalidChangesetOperationTypeNone) {
    NSString *const humanReadableInvalidChangesetOperationType = CKHumanReadableInvalidChangesetOperationType(invalidChangesetInfo.operationType);
    NSString *const humanReadablePendingAsynchronousModifications = readableStringForArray(pendingAsynchronousModifications);
    CKCFatalWithCategory(humanReadableInvalidChangesetOperationType, @"Invalid changeset: %@\n*** Changeset:\n%@\n*** Data source state:\n%@\n*** Pending data source modifications:\n%@\n*** Invalid section:\n%ld\n*** Invalid item:\n%ld", humanReadableInvalidChangesetOperationType, changeset, state, humanReadablePendingAsynchronousModifications, (long)invalidChangesetInfo.section, (long)invalidChangesetInfo.item);
  }
}

static NSArray<NSNumber *> *sectionCountsWithModificationsFoldedIntoState(CKDataSourceState *state,
                                                                          NSArray<id<CKDataSourceStateModifying>> *modifications)
{
  NSArray<NSNumber *> *sectionCounts = sectionCountsForState(state);
  for (id<CKDataSourceStateModifying> modification in modifications) {
    sectionCounts = updatedSectionCountsWithChangeset(sectionCounts, changesetFromModification(modification));
  }
  return sectionCounts;
}

static NSArray<NSNumber *> *sectionCountsForState(CKDataSourceState *state)
{
  NSMutableArray *sectionCounts = [NSMutableArray new];
  for (NSArray *section in state.sections) {
    [sectionCounts addObject:@(section.count)];
  }
  return sectionCounts;
}

static CKDataSourceChangeset *changesetFromModification(id<CKDataSourceStateModifying> modification)
{
  if ([modification isKindOfClass:[CKDataSourceChangesetModification class]]) {
    return [(CKDataSourceChangesetModification *)modification changeset];
  } else if ([modification isKindOfClass:[CKDataSourceSplitChangesetModification class]]) {
    return [(CKDataSourceSplitChangesetModification *)modification changeset];
  }
  return nil;
}

static NSArray<NSNumber *> *updatedSectionCountsWithChangeset(NSArray<NSNumber *> *sectionCounts,
                                                              CKDataSourceChangeset *changeset)
{
  if (changeset == nil) {
    return sectionCounts;
  }

  NSMutableArray *updatedSectionCounts = [sectionCounts mutableCopy];
  // Move items
  [changeset.movedItems enumerateKeysAndObjectsUsingBlock:^(NSIndexPath * _Nonnull fromIndexPath, NSIndexPath *, BOOL *) {
    // "Remove" the item
    updatedSectionCounts[fromIndexPath.section] = @([updatedSectionCounts[fromIndexPath.section] integerValue] - 1);
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
  [changeset.movedItems enumerateKeysAndObjectsUsingBlock:^(NSIndexPath *, NSIndexPath * _Nonnull toIndexPath, BOOL *) {
    // "Insert" the item
    updatedSectionCounts[toIndexPath.section] = @([updatedSectionCounts[toIndexPath.section] integerValue] + 1);
  }];
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
