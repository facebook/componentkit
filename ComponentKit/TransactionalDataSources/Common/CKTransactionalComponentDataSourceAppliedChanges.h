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

/** userInfo from the CKTransactionalComponentDataSourceChangeset object that caused this change. */
@property (nonatomic, copy, readonly) NSDictionary *userInfo;


/** Any of the parameters may be nil, in which case a default value will be substituted instead. */
- (instancetype)initWithUpdatedIndexPaths:(NSSet *)updatedIndexPaths
                        removedIndexPaths:(NSSet *)removedIndexPaths
                          removedSections:(NSIndexSet *)removedSections
                          movedIndexPaths:(NSDictionary *)movedIndexPaths
                         insertedSections:(NSIndexSet *)insertedSections
                       insertedIndexPaths:(NSSet *)insertedIndexPaths
                                 userInfo:(NSDictionary *)userInfo NS_DESIGNATED_INITIALIZER;

@end
