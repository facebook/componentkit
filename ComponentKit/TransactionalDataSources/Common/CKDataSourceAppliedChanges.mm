/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKDataSourceAppliedChanges.h"

#import <ComponentKit/CKEqualityHelpers.h>
#import <ComponentKit/CKMacros.h>

#import "CKIndexSetDescription.h"
#import "ComponentUtilities.h"

@implementation CKDataSourceAppliedChanges

- (instancetype)init
{
  return [self initWithUpdatedIndexPaths:nil
                       removedIndexPaths:nil
                         removedSections:nil
                         movedIndexPaths:nil
                        insertedSections:nil
                      insertedIndexPaths:nil
                                userInfo:nil];
}

- (instancetype)initWithUpdatedIndexPaths:(NSSet *)updatedIndexPaths
                        removedIndexPaths:(NSSet *)removedIndexPaths
                          removedSections:(NSIndexSet *)removedSections
                          movedIndexPaths:(NSDictionary *)movedIndexPaths
                         insertedSections:(NSIndexSet *)insertedSections
                       insertedIndexPaths:(NSSet *)insertedIndexPaths
                                 userInfo:(NSDictionary *)userInfo
{
  if (self = [super init]) {
    _updatedIndexPaths = [updatedIndexPaths copy] ?: [NSSet set];
    _removedIndexPaths = [removedIndexPaths copy] ?: [NSSet set];
    _removedSections = [removedSections copy] ?: [NSIndexSet indexSet];
    _movedIndexPaths = [movedIndexPaths copy] ?: @{};
    _insertedSections = [insertedSections copy] ?: [NSIndexSet indexSet];
    _insertedIndexPaths = [insertedIndexPaths copy] ?: [NSSet set];
    _userInfo = [userInfo copy];
    _finalUpdatedIndexPaths = finalUpdatedIndexPaths(_updatedIndexPaths,
                                                     _removedIndexPaths,
                                                     _removedSections,
                                                     _movedIndexPaths,
                                                     _insertedSections,
                                                     _insertedIndexPaths);
  }
  return self;
}

- (BOOL)isEmpty
{
  return [_updatedIndexPaths count] == 0 && [_removedIndexPaths count] == 0 &&
  [_removedSections count] == 0 && [_movedIndexPaths count] == 0 &&
  [_insertedSections count] == 0 && [_insertedIndexPaths count] == 0;
}

- (NSString *)description
{
  if ([self isEmpty]) {
    return @"";
  }

  auto const description = [NSMutableString new];
  [description appendString:@"{\n"];
  [description appendString:indexPathsDescriptionWithTitle(_updatedIndexPaths, @"Updated Items")];
  [description appendString:indexPathsDescriptionWithTitle(_removedIndexPaths, @"Removed Items")];
  [description appendString:withNewLineIfNotEmpty(CK::indexSetDescription(_removedSections, @"Removed Sections", 2))];
  [description appendString:indexPathToIndexPathMapDescriptionWithTitle(_movedIndexPaths, @"Moved Items")];
  [description appendString:withNewLineIfNotEmpty(CK::indexSetDescription(_insertedSections, @"Inserted Sections", 2))];
  [description appendString:indexPathsDescriptionWithTitle(_insertedIndexPaths, @"Inserted Items")];
  [description appendString:@"}"];
  return description;
}

- (BOOL)isEqual:(id)object
{
  return CKCompareObjectEquality(self, object, ^BOOL(CKDataSourceAppliedChanges *a, CKDataSourceAppliedChanges *b) {
    return CKObjectIsEqual(a.updatedIndexPaths, b.updatedIndexPaths)
    && CKObjectIsEqual(a.removedIndexPaths, b.removedIndexPaths)
    && CKObjectIsEqual(a.removedSections, b.removedSections)
    && CKObjectIsEqual(a.movedIndexPaths, b.movedIndexPaths)
    && CKObjectIsEqual(a.insertedSections, b.insertedSections)
    && CKObjectIsEqual(a.insertedIndexPaths, b.insertedIndexPaths)
    && CKObjectIsEqual(a.userInfo, b.userInfo);
  });
}

- (NSUInteger)hash
{
  NSUInteger subhashes[] = {
    [_updatedIndexPaths hash],
    [_removedIndexPaths hash],
    [_removedSections hash],
    [_movedIndexPaths hash],
    [_insertedSections hash],
    [_insertedIndexPaths hash],
    [_userInfo hash],
  };
  return CKIntegerArrayHash(subhashes, CK_ARRAY_COUNT(subhashes));
}

static auto withNewLineIfNotEmpty(NSString *s) -> NSString *
{
  return s.length > 0 ? [s stringByAppendingString:@"\n"] : @"";
}

static auto indexPathsDescriptionWithTitle(NSSet<NSIndexPath *> *indexPaths, NSString *title) -> NSString *
{
  if ([indexPaths count] == 0) {
    return @"";
  }

  auto description = [NSMutableString new];
  [description appendFormat:@"  %@: {\n", title];

  auto const sortedIndexPaths = [[indexPaths allObjects] sortedArrayUsingSelector:@selector(compare:)];
  auto const indexPathStrs = [NSMutableArray<NSString *> new];
  for (NSIndexPath *const indexPath : sortedIndexPaths) {
    auto const ipStr = [NSString stringWithFormat:@"    (%ld-%ld)", (long)indexPath.section, (long)indexPath.item];
    [indexPathStrs addObject:ipStr];
  }
  [description appendString:[indexPathStrs componentsJoinedByString:@",\n"]];

  [description appendString:@"\n  }\n"];
  return description;
}

static auto indexPathToIndexPathMapDescriptionWithTitle(NSDictionary<NSIndexPath *, NSIndexPath *> *map, NSString *title) -> NSString *
{
  if ([map count] == 0) {
    return @"";
  }

  auto description = [NSMutableString new];
  [description appendFormat:@"  %@: {\n", title];

  auto const sortedIndexPaths = [[map allKeys] sortedArrayUsingSelector:@selector(compare:)];
  auto const indexPathStrs = [NSMutableArray<NSString *> new];
  for (NSIndexPath *const indexPath : sortedIndexPaths) {
    auto const toIndexPath = map[indexPath];
    auto const ipStr = [NSString stringWithFormat:@"    (%ld-%ld) -> (%ld-%ld)",
                        (long)indexPath.section, (long)indexPath.item,
                        (long)toIndexPath.section, (long)toIndexPath.item];
    [indexPathStrs addObject:ipStr];
  }
  [description appendString:[indexPathStrs componentsJoinedByString:@",\n"]];

  [description appendString:@"\n  }\n"];
  return description;
}

static NSArray *sortedIndexPaths(NSArray<NSIndexPath *> *indexPaths, BOOL reverse)
{
  return [indexPaths sortedArrayUsingComparator:^NSComparisonResult(NSIndexPath *_Nonnull obj1, NSIndexPath *_Nonnull obj2) {
    NSComparisonResult sectionComparison = [@(obj1.section) compare:@(obj2.section)];
    if (sectionComparison != NSOrderedSame) {
      return (NSComparisonResult)(sectionComparison * (reverse ? -1 : 1));
    } else {
      return (NSComparisonResult)([@(obj1.row) compare:@(obj2.row)] * (reverse ? -1 : 1));
    }
  }];
}

static NSIndexPath *indexPathWithDeltas(NSIndexPath *indexPath, NSUInteger sectionDelta, NSUInteger rowDelta)
{
  return [NSIndexPath indexPathForRow:(indexPath.row + rowDelta) inSection:(indexPath.section + sectionDelta)];
}

static NSDictionary<NSIndexPath *, NSIndexPath *> *finalUpdatedIndexPaths(NSSet *updatedIndexPaths,
                                                                          NSSet *removedIndexPaths,
                                                                          NSIndexSet *removedSections,
                                                                          NSDictionary *movedIndexPaths,
                                                                          NSIndexSet *insertedSections,
                                                                          NSSet *insertedIndexPaths)
{
  // The dictionary that will be returned will have the structure:
  // (old update index path) -> (new update index path)
  NSMutableDictionary<NSIndexPath *, NSIndexPath *> *finalUpdatedIndexPaths = [NSMutableDictionary new];

  // Initialize with updated index paths mapping to themselves
  for (NSIndexPath *indexPath in updatedIndexPaths) {
    finalUpdatedIndexPaths[indexPath] = indexPath;
  }

  // Translate moves into removals and insertions
  NSArray *moveRemovals = [movedIndexPaths allKeys];
  NSArray *moveInsertions = [movedIndexPaths allValues];

  // Removed rows
  // Reverse sort (hence the -1 coefficient) so we don't end up in a situation like the following
  // Updating (0, 5) and removing (0,2) (0,3) (0,4). Since the removed index paths are unordered (NSSet) we could end up in a situation where we remove (0,2) and (0,3), so (0,5) -> (0,3) and when we remove (0,4) the updated row is assumed unaffected
  NSArray *allRemovals = [[removedIndexPaths allObjects] arrayByAddingObjectsFromArray:moveRemovals];
  for (NSIndexPath *removedIndexPath in sortedIndexPaths(allRemovals, YES)) {
    for (NSIndexPath *sourceUpdatePath in updatedIndexPaths) {
      NSIndexPath *destinationUpdatePath = finalUpdatedIndexPaths[sourceUpdatePath];
      if (removedIndexPath.section == destinationUpdatePath.section &&
          removedIndexPath.row < destinationUpdatePath.row) {
        finalUpdatedIndexPaths[sourceUpdatePath] = indexPathWithDeltas(destinationUpdatePath, 0, -1);
      }
    }
  }

  // Removed sections
  [removedSections enumerateIndexesWithOptions:NSEnumerationReverse usingBlock:^(NSUInteger removedSection, BOOL *_Nonnull removedSectionsStop) {
    for (NSIndexPath *sourceUpdatePath in updatedIndexPaths) {
      NSIndexPath *destinationUpdatePath = finalUpdatedIndexPaths[sourceUpdatePath];
      if (removedSection < destinationUpdatePath.section) {
        finalUpdatedIndexPaths[sourceUpdatePath] = indexPathWithDeltas(destinationUpdatePath, -1, 0);
      }
    }
  }];

  // Inserted sections
  [insertedSections enumerateIndexesUsingBlock:^(NSUInteger insertedSection, BOOL *_Nonnull insertedSectionsStop) {
    for (NSIndexPath *sourceUpdatePath in updatedIndexPaths) {
      NSIndexPath *destinationUpdatePath = finalUpdatedIndexPaths[sourceUpdatePath];
      if (insertedSection <= destinationUpdatePath.section) {
        finalUpdatedIndexPaths[sourceUpdatePath] = indexPathWithDeltas(destinationUpdatePath, 1, 0);
      }
    }
  }];

  // Inserted rows
  // Sort for the same reason as above when we sorted the removed index paths
  // First take care of the "normal" insertions, where we check the destination update path
  NSArray *allInsertions = [[insertedIndexPaths allObjects] arrayByAddingObjectsFromArray:moveInsertions];
  for (NSIndexPath *insertedIndexPath in sortedIndexPaths(allInsertions, NO)) {
    for (NSIndexPath *sourceUpdatePath in updatedIndexPaths) {
      NSIndexPath *destinationUpdatePath = finalUpdatedIndexPaths[sourceUpdatePath];
      if (insertedIndexPath.section == destinationUpdatePath.section &&
          insertedIndexPath.row <= destinationUpdatePath.row) {
        finalUpdatedIndexPaths[sourceUpdatePath] = indexPathWithDeltas(destinationUpdatePath, 0, 1);
      }
    }
  }

  // The destination index path of a move is *always* correct and we have it take the precedence over all above.
  // If one inserts a section at the front, even a move within an existing section
  // has to provide the correct final section index.
  [movedIndexPaths enumerateKeysAndObjectsUsingBlock:^(NSIndexPath *sourceIndexPath, NSIndexPath *destinationIndexPath, BOOL *_Nonnull stop) {
    if (finalUpdatedIndexPaths[sourceIndexPath]) {
      finalUpdatedIndexPaths[sourceIndexPath] = destinationIndexPath;
    }
  }];

  return finalUpdatedIndexPaths;
}

@end
