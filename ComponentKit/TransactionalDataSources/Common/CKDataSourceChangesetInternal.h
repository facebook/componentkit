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

#import <ComponentKit/CKDataSourceChangeset.h>

/** Internal interface since this class is usually only consumed internally. */
@interface CKDataSourceChangeset<__covariant ModelType> ()

@property (nonatomic, copy, readonly) NSDictionary *updatedItems;
@property (nonatomic, copy, readonly) NSSet *removedItems;
@property (nonatomic, copy, readonly) NSIndexSet *removedSections;
@property (nonatomic, copy, readonly) NSDictionary *movedItems;
@property (nonatomic, copy, readonly) NSIndexSet *insertedSections;
@property (nonatomic, copy, readonly) NSDictionary *insertedItems;

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

- (BOOL)isEmpty;

@end

namespace CK {
  auto changesetDescription(const CKDataSourceChangeset *const changeset) -> NSString *;
}

#endif
