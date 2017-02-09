/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKTransactionalComponentDataSourceAppliedChanges.h"
#import "CKTransactionalComponentDataSourceAppliedChanges.h"

#import "ComponentUtilities.h"
#import "CKEqualityHashHelpers.h"
#import "CKMacros.h"

@implementation CKTransactionalComponentDataSourceAppliedChanges

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
          @"<CKTransactionalComponentDataSourceAppliedChanges: %p>\n \
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
  return CKCompareObjectEquality(self, object, ^BOOL(CKTransactionalComponentDataSourceAppliedChanges *a, CKTransactionalComponentDataSourceAppliedChanges *b) {
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

@end


NSDictionary<NSIndexPath *, NSIndexPath *> *CKComputeFinalUpdatedIndexPathsForAppliedChanges(CKTransactionalComponentDataSourceAppliedChanges *changes)
{
  NSMutableDictionary<NSIndexPath *, NSIndexPath *> *mapping = [NSMutableDictionary new];
  for (NSIndexPath *indexPath in changes.updatedIndexPaths) {
    // If the index path in quesiton was removed, then there is no new
    // index path.
    if ([changes.removedIndexPaths containsObject:indexPath]) {
      continue;
    }
    
    __block NSInteger section = indexPath.section;
    NSInteger item = indexPath.item;
    
    // If the section of the index path in question was removed then there is
    // no new index path.
    if ([changes.removedSections containsIndex:section]) {
      continue;
    }
    
    // Every index path deleted before the index path in question in the same section
    // moves the index path forward by one item.
    for (NSIndexPath *removedIndexPath in changes.removedIndexPaths) {
      if (removedIndexPath.section == section && removedIndexPath.item < indexPath.item) {
        item--;
      }
    }
    
    // Let's count moves as deletes from the source index path.
    for (NSIndexPath *sourceIndexPath in changes.movedIndexPaths.keyEnumerator) {
      if (sourceIndexPath.section == section && sourceIndexPath.item < indexPath.item) {
        item--;
      }
    }
    
    // Every section deleted before the index path in question bumps the index path
    // forward by one section. This calculates that in one step.
    section -= [changes.removedSections countOfIndexesInRange:NSMakeRange(0, section)];
    
    // Every section inserted before the index path in question moves the index path
    // back by one section. However, inserts function differently than removals. If there
    // is a section 0, and a new section is inserted at index 0, then the previous section
    // moves to section 1. Inserts also cascade, so if there is a section 0, and sections
    // are inserted at indexes 0,1 and 2, then the previous section would be at index 3.
    // Notice how the comparison is `<= section`, where `section` is the incremented value.
    [changes.insertedSections enumerateIndexesUsingBlock:^(NSUInteger insertedSection, BOOL *stop) {
      if (insertedSection <= section) {
        section++;
      } else {
        *stop = YES;
      }
    }];
    
    // We apply the same cascading insert behavior here for index paths inserted in the
    // same section.
    for (NSIndexPath *insertedIndexPath in changes.insertedIndexPaths) {
      if (insertedIndexPath.section == section && insertedIndexPath.item <= item) {
        item++;
      }
    }
    
    // Let's count moves as inserts at the destination index path.
    for (NSIndexPath *destinationIndexPath in changes.movedIndexPaths.objectEnumerator) {
      if (destinationIndexPath.section == section && destinationIndexPath.item <= item) {
        item++;
      }
    }
    
    mapping[indexPath] = [NSIndexPath indexPathForItem:item inSection:section];
  }
  return mapping;
}
