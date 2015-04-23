/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <Foundation/Foundation.h>

@interface CKTransactionalComponentDataSourceAppliedChanges : NSObject

@property (nonatomic, copy, readonly) NSSet *updatedIndexPaths;
@property (nonatomic, copy, readonly) NSSet *removedIndexPaths;
@property (nonatomic, copy, readonly) NSIndexSet *removedSections;
@property (nonatomic, copy, readonly) NSDictionary *movedIndexPaths;
@property (nonatomic, copy, readonly) NSIndexSet *insertedSections;
@property (nonatomic, copy, readonly) NSSet *insertedIndexPaths;

/**
 Array of NSDictionary containing all non-nil userInfo objects from the CKTransactionalComponentDataSourceChangeset
 objects that caused this change. (Multiple changesets may result in only a single AppliedChanges.)
 */
@property (nonatomic, copy, readonly) NSArray *userInfos;

@end
