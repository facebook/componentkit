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

#import "ComponentUtilities.h"
#import "CKEqualityHashHelpers.h"
#import "CKMacros.h"


@implementation CKDataSourceAppliedChanges {
  NSDictionary<NSIndexPath *, NSIndexPath *>* _finalUpdatedIndexPaths;
  dispatch_once_t _finalUpdatedPathsToken;
}

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
  }
  return self;
}

- (NSString *)description
{
  return [NSString stringWithFormat:
          @"<CKDataSourceAppliedChanges: %p>\n \
          Updated Index Paths: %@\n \
          Removed Index Paths: %@\n \
          Remove Sections: %@\n \
          Moves: %@\n \
          Inserted Sections: %@\n \
          Inserted Index Paths: %@",
          self, _updatedIndexPaths, _removedIndexPaths, _removedSections, _movedIndexPaths, _insertedSections, _insertedIndexPaths];
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

- (NSDictionary<NSIndexPath *, NSIndexPath *> *)finalUpdatedIndexPaths
{
  dispatch_once(&_finalUpdatedPathsToken, ^{
    NSArray *updatedIndexPaths = [self.updatedIndexPaths allObjects];
    
    // The dictionary that will be returned will have the structure:
    // (old update index path) -> (new update index path)
    NSMutableDictionary<NSIndexPath *, NSIndexPath *> *finalUpdatedIndexPaths = [NSMutableDictionary new];
    
    // Initialize with updated index paths mapping to themselves
    for (NSIndexPath *indexPath in [self.updatedIndexPaths allObjects]) {
      finalUpdatedIndexPaths[indexPath] = indexPath;
    }
    
    
    // Translate moves into removals and insertions
    NSArray *moveRemovals = [self.movedIndexPaths allKeys];
    NSArray *moveInsertions = [self.movedIndexPaths allValues];
    
    // Removed rows
    // Reverse sort (hence the -1 coefficient) so we don't end up in a situation like the following
    // Updating (0, 5) and removing (0,2) (0,3) (0,4). Since the removed index paths are unordered (NSSet) we could end up in a situation where we remove (0,2) and (0,3), so (0,5) -> (0,3) and when we remove (0,4) the updated row is assumed unaffected
    NSArray *allRemovals = [[self.removedIndexPaths allObjects] arrayByAddingObjectsFromArray:moveRemovals];
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
    [self.removedSections enumerateIndexesWithOptions:NSEnumerationReverse usingBlock:^(NSUInteger removedSection, BOOL *_Nonnull removedSectionsStop) {
      for (NSIndexPath *sourceUpdatePath in updatedIndexPaths) {
        NSIndexPath *destinationUpdatePath = finalUpdatedIndexPaths[sourceUpdatePath];
        if (removedSection < destinationUpdatePath.section) {
          finalUpdatedIndexPaths[sourceUpdatePath] = indexPathWithDeltas(destinationUpdatePath, -1, 0);
        }
      }
    }];
    
    // Inserted sections
    [self.insertedSections enumerateIndexesUsingBlock:^(NSUInteger insertedSection, BOOL *_Nonnull insertedSectionsStop) {
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
    NSArray *allInsertions = [[self.insertedIndexPaths allObjects] arrayByAddingObjectsFromArray:moveInsertions];
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
    [self.movedIndexPaths enumerateKeysAndObjectsUsingBlock:^(NSIndexPath *sourceIndexPath, NSIndexPath *destinationIndexPath, BOOL *_Nonnull stop) {
      if (finalUpdatedIndexPaths[sourceIndexPath]) {
        finalUpdatedIndexPaths[sourceIndexPath] = destinationIndexPath;
      }
    }];
    
    _finalUpdatedIndexPaths = finalUpdatedIndexPaths;
  });
  return _finalUpdatedIndexPaths;
}

@end
