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

@implementation CKTransactionalComponentDataSourceAppliedChanges

- (instancetype)initWithUpdatedIndexPaths:(NSSet *)updatedIndexPaths
                        removedIndexPaths:(NSSet *)removedIndexPaths
                          removedSections:(NSIndexSet *)removedSections
                          movedIndexPaths:(NSDictionary *)movedIndexPaths
                         insertedSections:(NSIndexSet *)insertedSections
                       insertedIndexPaths:(NSSet *)insertedIndexPaths
                                userInfos:(NSArray *)userInfos
{
  if (self = [super init]) {
    _updatedIndexPaths = [updatedIndexPaths copy] ?: [NSSet set];
    _removedIndexPaths = [removedIndexPaths copy] ?: [NSSet set];
    _removedSections = [removedSections copy] ?: [NSIndexSet indexSet];
    _movedIndexPaths = [movedIndexPaths copy] ?: @{};
    _insertedSections = [insertedSections copy] ?: [NSIndexSet indexSet];
    _insertedIndexPaths = [insertedIndexPaths copy] ?: [NSSet set];
    _userInfos = [userInfos copy] ?: @[];
  }
  return self;
}

@end
