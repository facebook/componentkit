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

@interface CKTransactionalComponentDataSourceChangeset<__covariant ModelType> : NSObject

/**
 Designated initializer. Any parameter may be nil.
 @param updatedItems Mapping from NSIndexPath to updated model.
 @param removedItems Set of NSIndexPath.
 @param removedSections NSIndexSet of section indices.
 @param movedItems Mapping from NSIndexPath to NSIndexPath.
 @param insertedSections NSIndexSet of section indices.
 @param insertedItems Mapping from NSIndexPath to new model.
 */
- (instancetype)initWithUpdatedItems:(NSDictionary<NSIndexPath *, ModelType> *)updatedItems
                        removedItems:(NSSet<NSIndexPath *> *)removedItems
                     removedSections:(NSIndexSet *)removedSections
                          movedItems:(NSDictionary<NSIndexPath *, NSIndexPath *> *)movedItems
                    insertedSections:(NSIndexSet *)insertedSections
                       insertedItems:(NSDictionary<NSIndexPath *, ModelType> *)insertedItems;

@end

/** A helper object that allows you to build changesets. */
@interface CKTransactionalComponentDataSourceChangesetBuilder<__covariant ModelType> : NSObject

+ (instancetype)transactionalComponentDataSourceChangeset;
- (instancetype)withUpdatedItems:(NSDictionary<NSIndexPath *, ModelType> *)updatedItems;
- (instancetype)withRemovedItems:(NSSet *)removedItems;
- (instancetype)withRemovedSections:(NSIndexSet *)removedSections;
- (instancetype)withMovedItems:(NSDictionary<NSIndexPath *, NSIndexPath *> *)movedItems;
- (instancetype)withInsertedSections:(NSIndexSet *)insertedSections;
- (instancetype)withInsertedItems:(NSDictionary<NSIndexPath *, ModelType> *)insertedItems;
- (CKTransactionalComponentDataSourceChangeset<ModelType> *)build;

@end
