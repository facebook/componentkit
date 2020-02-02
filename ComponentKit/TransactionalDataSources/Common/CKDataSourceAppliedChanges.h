/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKDefines.h>

#if CK_NOT_SWIFT

#import <Foundation/Foundation.h>

@interface CKDataSourceAppliedChanges : NSObject

@property (nonatomic, copy, readonly) NSSet *updatedIndexPaths;
@property (nonatomic, copy, readonly) NSSet *removedIndexPaths;
@property (nonatomic, copy, readonly) NSIndexSet *removedSections;
@property (nonatomic, copy, readonly) NSDictionary *movedIndexPaths;
@property (nonatomic, copy, readonly) NSIndexSet *insertedSections;
@property (nonatomic, copy, readonly) NSSet *insertedIndexPaths;

/** userInfo from the CKDataSourceChangeset object that caused this change. */
@property (nonatomic, copy, readonly) NSDictionary *userInfo;

/**
 This property returns a mapping for each row being updated
 from their current index path to their new index path after the changeset has been applied.

 Because this is pretty confusing, here's a simple example:
 Let's say we have a changeset made up of the following operations:
 Insert a row at (0, 0)
 Update the row at (0, 1)

 Feeding this changeset into the function below would return:
 (0,1) -> (0,2)

 This mapping occurs because the inserted row at (0,0) pushes the row at (0,1) down one row.

 Of course, these changesets can be more and more complicated, so updated rows can move up or down, and change rows or sections.

 There are also certain assumptions made:
 - An updated row cannot also be removed, both in terms of row removal and section removal (if it's removed, we ignore it and continue as normal)
 - A section cannot be inserted and removed in the same changeset
 - A row cannot be inserted and removed in the same changeset
 - A row cannot be moved and removed in the same changeset
 */
@property (nonatomic, readonly) NSDictionary<NSIndexPath *, NSIndexPath *>* finalUpdatedIndexPaths;

/** Any of the parameters may be nil, in which case a default value will be substituted instead. */
- (instancetype)initWithUpdatedIndexPaths:(NSSet *)updatedIndexPaths
                        removedIndexPaths:(NSSet *)removedIndexPaths
                          removedSections:(NSIndexSet *)removedSections
                          movedIndexPaths:(NSDictionary *)movedIndexPaths
                         insertedSections:(NSIndexSet *)insertedSections
                       insertedIndexPaths:(NSSet *)insertedIndexPaths
                                 userInfo:(NSDictionary *)userInfo NS_DESIGNATED_INITIALIZER;

@end

#endif
