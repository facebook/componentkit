/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <UIKit/UIKit.h>

@interface CKTransactionalComponentDataSourceChangeset : NSObject

/**
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
                       movedSections:(NSDictionary *)movedSections
                    insertedSections:(NSIndexSet *)insertedSections
                       insertedItems:(NSDictionary *)insertedItems;

@end

/** A helper object that allows you to build changesets. */
@interface CKTransactionalComponentDataSourceChangesetBuilder : NSObject

+ (instancetype)transactionalComponentDataSourceChangeset;
- (instancetype)withUpdatedItems:(NSDictionary *)updatedItems;
- (instancetype)withRemovedItems:(NSSet *)removedItems;
- (instancetype)withRemovedSections:(NSIndexSet *)removedSections;
- (instancetype)withMovedItems:(NSDictionary *)movedItems;
- (instancetype)withMovedSections:(NSDictionary *)movedSections;
- (instancetype)withInsertedSections:(NSIndexSet *)insertedSections;
- (instancetype)withInsertedItems:(NSDictionary *)insertedItems;
- (CKTransactionalComponentDataSourceChangeset *)build;

@end

/**
 Block-based DSL changeset builder.
 */
@interface CKTransactionalComponentDataSourceChangesetDSLBuilder : NSObject

/**
 Convenience method for one-off changeset creation.
 @see Instance method for more information.
 */
+ (CKTransactionalComponentDataSourceChangeset*)build:(void(^)(CKTransactionalComponentDataSourceChangesetDSLBuilder *builder))block;

/**
 Instance method builder is intended to be used as a local variable.
 For example, it might be used within a loop to add various items.
 Expressions are natural language of the form(s):
 
 [CKTransactionalComponentDataSourceChangesetDSLBuilder build:^(CKTransactionalComponentDataSourceChangesetDSLBuilder *builder) {
   builder.insert.section.at.index(0);
   builder.insert.item(@"Foo").at.indexPath([NSIndexPath indexPathForItem:1 inSection:4]);
   builder.remove.section.at.index(1);
   builder.move.section.at.index(0).to.index(4);
 }];
 
 @note Prepositions are optional, but recommended.
 @see CKTransactionalComponentDataSourceChangesetBuilderTests for examples.
*/
- (instancetype)build:(void(^)(CKTransactionalComponentDataSourceChangesetDSLBuilder *builder))block;

- (CKTransactionalComponentDataSourceChangeset *)build;

/** Verbs */
@property (nonatomic, strong, readonly) CKTransactionalComponentDataSourceChangesetDSLBuilder *update;
@property (nonatomic, strong, readonly) CKTransactionalComponentDataSourceChangesetDSLBuilder *insert;
@property (nonatomic, strong, readonly) CKTransactionalComponentDataSourceChangesetDSLBuilder *remove;
@property (nonatomic, strong, readonly) CKTransactionalComponentDataSourceChangesetDSLBuilder *move;

/** Nouns */
@property (nonatomic, strong, readonly) CKTransactionalComponentDataSourceChangesetDSLBuilder *section;
@property (nonatomic, strong, readonly) CKTransactionalComponentDataSourceChangesetDSLBuilder *(^item)(id item);
@property (nonatomic, strong, readonly) CKTransactionalComponentDataSourceChangesetDSLBuilder *(^index)(NSUInteger index);
@property (nonatomic, strong, readonly) CKTransactionalComponentDataSourceChangesetDSLBuilder *(^indexPath)(NSIndexPath *indexPath);

/** 
 Prepositions 
 @note Optional, but certainly aid natural language readibility
 */
@property (nonatomic, strong, readonly) CKTransactionalComponentDataSourceChangesetDSLBuilder *at;
@property (nonatomic, strong, readonly) CKTransactionalComponentDataSourceChangesetDSLBuilder *to;
@property (nonatomic, strong, readonly) CKTransactionalComponentDataSourceChangesetDSLBuilder *with;

@end

/**
 Additional syntactic sugar
 */
#define ck_indexPath(ITEM, SECTION)	indexPath([NSIndexPath indexPathForItem:ITEM inSection:SECTION])
#define ck_removeItem 							remove.item(nil)
#define ck_moveItem 								move.item(nil)
