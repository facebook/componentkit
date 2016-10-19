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

#import <map>
#import <unordered_map>

#import "CKTransactionalComponentDataSourceChangesetVerification.h"

#import <ComponentKit/CKTransactionalComponentDataSourceChangesetInternal.h>
#import <ComponentKit/CKTransactionalComponentDataSourceChangesetModification.h>
#import <ComponentKit/CKTransactionalComponentDataSourceStateInternal.h>

static CKTransactionalComponentDataSourceState *foldModificationsIntoState(CKTransactionalComponentDataSourceState *state,
                                                                           NSArray<id<CKTransactionalComponentDataSourceStateModifying>> *modifications);

static CKTransactionalComponentDataSourceState *foldModificationIntoState(CKTransactionalComponentDataSourceState *state,
                                                                          CKTransactionalComponentDataSourceChangesetModification *changesetModification);

static NSArray *emptyMutableArrays(NSUInteger count);

static NSMutableArray<NSNumber *> *sectionCountsForState(CKTransactionalComponentDataSourceState *state);

static NSArray<NSIndexPath *> *sortedIndexPaths(NSArray<NSIndexPath *> *indexPaths);

CKBadChangesetOperationType CKIsValidChangesetForState(CKTransactionalComponentDataSourceChangeset *changeset,
                                                       CKTransactionalComponentDataSourceState *state,
                                                       NSArray<id<CKTransactionalComponentDataSourceStateModifying>> *pendingAsynchronousModifications)
{
  /*
   "Fold" any pending asynchronous modifications into the supplied state.
   This process ensures that the modified state represents the actual state the changeset will be applied to.
   */
  CKTransactionalComponentDataSourceState *modifiedState = foldModificationsIntoState(state, pendingAsynchronousModifications);
  // Compute the number of items in each section used to maintain a running tally as changeset modifications are "applied".
  NSMutableArray<NSNumber *> *sectionCounts = sectionCountsForState(modifiedState);
  __block BOOL invalidChangeFound = NO;
  // Updated items
  [changeset.updatedItems enumerateKeysAndObjectsUsingBlock:^(NSIndexPath * _Nonnull indexPath, id _Nonnull model, BOOL * _Nonnull stop) {
    const NSInteger section = indexPath.section;
    const NSInteger item = indexPath.item;
    if (section >= sectionCounts.count
        || item >= [sectionCounts[section] integerValue]
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
  [changeset.removedItems enumerateObjectsUsingBlock:^(NSIndexPath *_Nonnull indexPath, BOOL * _Nonnull stop) {
    const NSInteger section = indexPath.section;
    const NSInteger item = indexPath.item;
    if (section >= sectionCounts.count
        || section < 0
        || item >= [sectionCounts[section] integerValue]) {
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
  [changeset.removedSections enumerateIndexesUsingBlock:^(NSUInteger section, BOOL * _Nonnull stop) {
    if (section >= sectionCounts.count) {
      invalidChangeFound = YES;
      *stop = YES;
    } else {
      [sectionsToRemove addIndex:section];
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
  [changeset.insertedSections enumerateIndexesUsingBlock:^(NSUInteger section, BOOL * _Nonnull stop) {
    if (section > sectionCounts.count) {
      invalidChangeFound = YES;
      *stop = YES;
    } else {
      [sectionCounts insertObject:@0 atIndex:section];
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
  [sortedIndexPaths(changeset.insertedItems.allKeys) enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull indexPath, NSUInteger index, BOOL * _Nonnull stop) {
    const NSInteger section = indexPath.section;
    const NSInteger item = indexPath.item;
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
      const BOOL fromIndexPathItemInvalid = fromIndexPath.item >= [sectionCounts[fromIndexPath.section] integerValue];
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

static CKTransactionalComponentDataSourceState *foldModificationsIntoState(CKTransactionalComponentDataSourceState *state,
                                                                           NSArray<id<CKTransactionalComponentDataSourceStateModifying>> *modifications)
{
  CKTransactionalComponentDataSourceState *modifiedState = state;
  for (id<CKTransactionalComponentDataSourceStateModifying> modification in modifications) {
    if ([modification isKindOfClass:[CKTransactionalComponentDataSourceChangesetModification class]]) {
      modifiedState = foldModificationIntoState(modifiedState, modification);
    }
  }
  return modifiedState;
}

static CKTransactionalComponentDataSourceState *foldModificationIntoState(CKTransactionalComponentDataSourceState *state,
                                                                          CKTransactionalComponentDataSourceChangesetModification *changesetModification)
{
  CKTransactionalComponentDataSourceChangeset *changeset = changesetModification.changeset;
  NSMutableArray *modifiedSections = [NSMutableArray new];
  [state.sections enumerateObjectsUsingBlock:^(NSArray *items, NSUInteger index, BOOL *sectionStop) {
    [modifiedSections addObject:[items mutableCopy]];
  }];
  // Update items
  [[changeset updatedItems] enumerateKeysAndObjectsUsingBlock:^(NSIndexPath *indexPath, id model, BOOL *stop) {
    [modifiedSections[indexPath.section] replaceObjectAtIndex:indexPath.item withObject:model];
  }];
  __block std::unordered_map<NSUInteger, std::map<NSUInteger, id>> insertedItemsBySection;
  __block std::unordered_map<NSUInteger, NSMutableIndexSet *> removedItemsBySection;
  void (^addRemovedIndexPath)(NSIndexPath *) = ^(NSIndexPath *indexPath){
    const auto &element = removedItemsBySection.find(indexPath.section);
    if (element == removedItemsBySection.end()) {
      removedItemsBySection.insert({indexPath.section, [NSMutableIndexSet indexSetWithIndex:indexPath.item]});
    } else {
      [element->second addIndex:indexPath.item];
    }
  };
  // Move items
  [[changeset movedItems] enumerateKeysAndObjectsUsingBlock:^(NSIndexPath *fromIndexPath, NSIndexPath *toIndexPath, BOOL *stop) {
    insertedItemsBySection[toIndexPath.section][toIndexPath.row] = modifiedSections[fromIndexPath.section][fromIndexPath.item];
  }];
  [[changeset movedItems] enumerateKeysAndObjectsUsingBlock:^(NSIndexPath *fromIndexPath, NSIndexPath *toIndexPath, BOOL *stop) {
    addRemovedIndexPath(fromIndexPath);
  }];
  // Remove items
  for (NSIndexPath *removedItem in [changeset removedItems]) {
    addRemovedIndexPath(removedItem);
  }
  for (const auto &removedItems : removedItemsBySection) {
    [[modifiedSections objectAtIndex:removedItems.first] removeObjectsAtIndexes:removedItems.second];
  }
  // Remove sections
  [modifiedSections removeObjectsAtIndexes:[changeset removedSections]];
  // Insert sections
  [modifiedSections insertObjects:emptyMutableArrays([[changeset insertedSections] count])
                        atIndexes:[changeset insertedSections]];
  // Insert items
  [[changeset insertedItems] enumerateKeysAndObjectsUsingBlock:^(NSIndexPath *indexPath, id model, BOOL *stop) {
    insertedItemsBySection[indexPath.section][indexPath.item] = model;
  }];
  for (const auto &section : insertedItemsBySection) {
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    NSMutableArray *items = [NSMutableArray array];
    for (const auto &item : section.second) {
      [indexes addIndex:item.first];
      [items addObject:item.second];
    }
    [[modifiedSections objectAtIndex:section.first] insertObjects:items atIndexes:indexes];
  }
  return [[CKTransactionalComponentDataSourceState alloc] initWithConfiguration:state.configuration
                                                                       sections:modifiedSections];
}

static NSArray *emptyMutableArrays(NSUInteger count)
{
  NSMutableArray *arrays = [NSMutableArray new];
  for (NSUInteger i = 0; i < count; i++) {
    [arrays addObject:[NSMutableArray new]];
  }
  return arrays;
}

static NSMutableArray<NSNumber *> *sectionCountsForState(CKTransactionalComponentDataSourceState *state)
{
  NSMutableArray *sectionCounts = [NSMutableArray new];
  for (NSArray *section in state.sections) {
    [sectionCounts addObject:@(section.count)];
  }
  return sectionCounts;
}

static NSArray<NSIndexPath *> *sortedIndexPaths(NSArray<NSIndexPath *> *indexPaths)
{
  return [indexPaths sortedArrayUsingSelector:@selector(compare:)];
}
