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
#import "CKTransactionalComponentDataSourceAppliedChangesInternal.h"

#import "ComponentUtilities.h"
#import "CKEqualityHashHelpers.h"
#import "CKMacros.h"

@implementation CKTransactionalComponentDataSourceAppliedChanges

- (instancetype)initWithUpdatedIndexPaths:(NSDictionary *)updatedIndexPaths
                        removedIndexPaths:(NSSet *)removedIndexPaths
                          removedSections:(NSIndexSet *)removedSections
                          movedIndexPaths:(NSDictionary *)movedIndexPaths
                         insertedSections:(NSIndexSet *)insertedSections
                       insertedIndexPaths:(NSSet *)insertedIndexPaths
                                 userInfo:(NSDictionary *)userInfo
{
  if (self = [super init]) {
    _updatedIndexPaths = [updatedIndexPaths copy] ?: @{};
    _removedIndexPaths = [removedIndexPaths copy] ?: [NSSet set];
    _removedSections = [removedSections copy] ?: [NSIndexSet indexSet];
    _movedIndexPaths = [movedIndexPaths copy] ?: @{};
    _insertedSections = [insertedSections copy] ?: [NSIndexSet indexSet];
    _insertedIndexPaths = [insertedIndexPaths copy] ?: [NSSet set];
    _userInfo = [userInfo copy];
  }
  return self;
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
