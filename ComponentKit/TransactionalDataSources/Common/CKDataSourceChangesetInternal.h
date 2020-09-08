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
@property (nonatomic, copy, readonly) NSString *originName; // Use for debugging purpose only.
@property (nonatomic, copy, readonly) NSDictionary *updatedItems;
@property (nonatomic, copy, readonly) NSSet *removedItems;
@property (nonatomic, copy, readonly) NSIndexSet *removedSections;
@property (nonatomic, copy, readonly) NSDictionary *movedItems;
@property (nonatomic, copy, readonly) NSIndexSet *insertedSections;
@property (nonatomic, copy, readonly) NSDictionary *insertedItems;

/**
 Deprecated. Use -initWithOriginName:updatedItems:removedItems:removedSections:movedItems:insertedSections:insertedItems: instead.
 Designated initializer. Any parameter may be nil.
 @param updatedItems Mapping from NSIndexPath to updated model.
 @param removedItems Set of NSIndexPath.
 @param removedSections NSIndexSet of section indices.
 @param movedItems Mapping from NSIndexPath to NSIndexPath.
 @param insertedSections NSIndexSet of section indices.
 @param insertedItems Mapping from NSIndexPath to new model.
 */
- (instancetype)initWithUpdatedItems:(NSDictionary *)updatedItems
                        removedItems:(NSSet *)removedItems
                     removedSections:(NSIndexSet *)removedSections
                          movedItems:(NSDictionary *)movedItems
                    insertedSections:(NSIndexSet *)insertedSections
                       insertedItems:(NSDictionary *)insertedItems;

/**
 Designated initializer. Any parameter may be nil.
 @param originName A string that uniquely identifies the places in the program where changeset is generated. Used for debugging purpose.
 @param updatedItems Mapping from NSIndexPath to updated model.
 @param removedItems Set of NSIndexPath.
 @param removedSections NSIndexSet of section indices.
 @param movedItems Mapping from NSIndexPath to NSIndexPath.
 @param insertedSections NSIndexSet of section indices.
 @param insertedItems Mapping from NSIndexPath to new model.
 */
- (instancetype)initWithOriginName:(NSString *)originName
                      updatedItems:(NSDictionary *)updatedItems
                      removedItems:(NSSet *)removedItems
                   removedSections:(NSIndexSet *)removedSections
                        movedItems:(NSDictionary *)movedItems
                  insertedSections:(NSIndexSet *)insertedSections
                     insertedItems:(NSDictionary *)insertedItems;

- (BOOL)isEmpty;

@end

namespace CK {
  auto changesetDescription(const CKDataSourceChangeset *const changeset) -> NSString *;
}

#endif
