/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKArrayControllerChangesetVerification.h"

static NSMutableArray<NSNumber *> *sectionCountsForSections(NSArray<NSArray *> *sections)
{
  NSMutableArray *sectionCounts = [NSMutableArray new];
  for (NSArray *section in sections) {
    [sectionCounts addObject:@(section.count)];
  }
  return sectionCounts;
}

CKBadChangesetOperationType CKIsValidChangesetForSections(CKArrayControllerInputChangeset changeset, NSArray<NSArray *> *sections)
{
  NSMutableArray<NSNumber *> *currentSectionCounts = sectionCountsForSections(sections);
  __block BOOL invalidChangeFound = NO;

  // Updates
  changeset.items.enumerateItems(^(NSInteger section, NSInteger index, id<NSObject> object, BOOL *stop) {
    if (section >= [currentSectionCounts count] || index >= [currentSectionCounts[section] integerValue] || section < 0 || index < 0) {
      invalidChangeFound = YES;
      *stop = YES;
    }
  }, nil, nil, nil);

  if (invalidChangeFound) {
    return CKBadChangesetOperationTypeUpdate;
  }

  /*
   Removed rows
   Note we need to use the dictionary of index sets so that we have an index set for each section.
   For discussion about why we need index sets at all, see the 'removed sections' comment below
   */
  NSMutableDictionary<NSNumber *, NSMutableIndexSet *> *rowsToRemove = [NSMutableDictionary new];
  changeset.items.enumerateItems(nil, ^(NSInteger section, NSInteger index, BOOL *stop) {
    if (section >= [currentSectionCounts count] || section < 0 || index >= [currentSectionCounts[section] integerValue]) {
      invalidChangeFound = YES;
      *stop = YES;
    } else {
      if (!rowsToRemove[@(section)]) {
        rowsToRemove[@(section)] = [NSMutableIndexSet indexSet];
      }

      [rowsToRemove[@(section)] addIndex:index];
    }
  }, nil, nil);

  if (invalidChangeFound) {
    return CKBadChangesetOperationTypeRemoveRow;
  } else {
    [rowsToRemove enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull section, NSMutableIndexSet * _Nonnull indexSet, BOOL * _Nonnull stop) {
      currentSectionCounts[[section integerValue]] = @([currentSectionCounts[[section integerValue]] integerValue] - [indexSet count]);
    }];
  }

  /*
   Removed sections
   
   We need to keep an index set to track what sections to remove instead of removing each inline because we cannot
   guarantee the order of the removals, so for example:
   
   Let's say we have 3 sections, and we want to remove the second and third section. If we remove the second section first,
   we'll end up trying to remove the third section when there's only 2 sections left, and we'll get a false negative.
   */
  NSMutableIndexSet *sectionsToRemove = [NSMutableIndexSet indexSet];
  for (NSInteger removal : changeset.sections.removals()) {
    if (removal >= [currentSectionCounts count]) {
      return CKBadChangesetOperationTypeRemoveSection;
    } else {
      [sectionsToRemove addIndex:removal];
    }
  }
  [currentSectionCounts removeObjectsAtIndexes:sectionsToRemove];

  // Inserted sections
  for (NSInteger insertion : changeset.sections.insertions()) {
    // Strictly greater than, since you can always insert at the end
    if (insertion > [currentSectionCounts count]) {
      return CKBadChangesetOperationTypeInsertSection;
    } else {
      [currentSectionCounts insertObject:@0 atIndex:insertion];
    }
  }

  // Moved sections
  for (std::pair<NSInteger, NSInteger> move : changeset.sections.moves()) {
    NSInteger origin = move.first;
    NSInteger destination = move.second;

    if (origin >= [currentSectionCounts count] || destination >= [currentSectionCounts count]) {
      return CKBadChangesetOperationTypeMoveSection;
    } else {
      NSNumber *originSectionCount = currentSectionCounts[origin];
      [currentSectionCounts removeObjectAtIndex:origin];
      [currentSectionCounts insertObject:originSectionCount atIndex:destination];
    }
  }

  // Inserted rows
  changeset.items.enumerateItems(nil, nil, ^(NSInteger section, NSInteger index, id<NSObject> object, BOOL *stop) {
    if (section >= [currentSectionCounts count] || section < 0 || index > [currentSectionCounts[section] integerValue]) {
      invalidChangeFound = YES;
      *stop = YES;
    } else {
      currentSectionCounts[section] = @([currentSectionCounts[section] integerValue] + 1);
    }
  }, nil);

  if (invalidChangeFound) {
    return CKBadChangesetOperationTypeInsertRow;
  }

  // Moved rows
  changeset.items.enumerateItems(nil, nil, nil, ^(const CKArrayControllerIndexPath &fromIndexPath, const CKArrayControllerIndexPath &toIndexPath, BOOL *stop) {
    BOOL fromIndexPathSectionInvalid = fromIndexPath.section >= [currentSectionCounts count];
    BOOL toIndexPathSectionInvalid = toIndexPath.section >= [currentSectionCounts count];

    /*
     First only check section validity.
     If we don't do this first, we risk an index out of bounds crash in the item validity check
     */
    if (fromIndexPathSectionInvalid || toIndexPathSectionInvalid) {
      invalidChangeFound = YES;
      *stop = YES;
    } else {
      BOOL fromIndexPathItemInvalid = fromIndexPath.item >= [currentSectionCounts[fromIndexPath.section] integerValue];
      BOOL toIndexPathItemInvalid = (fromIndexPath.section == toIndexPath.section) ?
      toIndexPath.item >= [currentSectionCounts[toIndexPath.section] integerValue] :
      toIndexPath.item > [currentSectionCounts[toIndexPath.section] integerValue];

      if (fromIndexPathItemInvalid || toIndexPathItemInvalid) {
        invalidChangeFound = YES;
        *stop = YES;
      } else {
        currentSectionCounts[fromIndexPath.section] = @([currentSectionCounts[fromIndexPath.section] integerValue] - 1);
        currentSectionCounts[toIndexPath.section] = @([currentSectionCounts[toIndexPath.section] integerValue] + 1);
      }
    }
  });

  return invalidChangeFound ? CKBadChangesetOperationTypeMoveRow : CKBadChangesetOperationTypeNone;
}

NSString *CKHumanReadableBadChangesetOperation(CKBadChangesetOperationType type)
{
  switch (type) {
    case CKBadChangesetOperationTypeUpdate:
      return @"Bad Update";
    case CKBadChangesetOperationTypeRemoveRow:
      return @"Bad Row Removal";
    case CKBadChangesetOperationTypeRemoveSection:
      return @"Bad Section Removal";
    case CKBadChangesetOperationTypeInsertSection:
      return @"Bad Section Insertion";
    case CKBadChangesetOperationTypeMoveSection:
      return @"Bad Section Move";
    case CKBadChangesetOperationTypeInsertRow:
      return @"Bad Row Insertion";
    case CKBadChangesetOperationTypeMoveRow:
      return @"Bad Row Move";
    case CKBadChangesetOperationTypeNone:
      return @"No Issue";
  }
}
