/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKTransactionalComponentDataSourceChangeset.h"
#import "CKTransactionalComponentDataSourceChangesetInternal.h"

@implementation CKTransactionalComponentDataSourceChangeset

- (instancetype)initWithUpdatedItems:(NSDictionary<NSIndexPath *, id<NSObject>> *)updatedItems
                        removedItems:(NSSet<NSIndexPath *> *)removedItems
                     removedSections:(NSIndexSet *)removedSections
                          movedItems:(NSDictionary<NSIndexPath *, NSIndexPath *> *)movedItems
                    insertedSections:(NSIndexSet *)insertedSections
                       insertedItems:(NSDictionary<NSIndexPath *, id<NSObject>> *)insertedItems
{
  if (self = [super init]) {
    _updatedItems = [updatedItems copy] ?: @{};
    _removedItems = [removedItems copy] ?: [NSSet set];
    _removedSections = [removedSections copy] ?: [NSIndexSet indexSet];
    _movedItems = [movedItems copy] ?: @{};
    _insertedSections = [insertedSections copy] ?: [NSIndexSet indexSet];
    _insertedItems = [insertedItems copy] ?: @{};
  }
  return self;
}

@end

@implementation CKTransactionalComponentDataSourceChangesetBuilder
{
  NSDictionary<NSIndexPath *, id<NSObject>> *_updatedItems;
  NSSet<NSIndexPath *> *_removedItems;
  NSIndexSet *_removedSections;
  NSDictionary<NSIndexPath *, NSIndexPath *> *_movedItems;
  NSIndexSet *_insertedSections;
  NSDictionary<NSIndexPath *, id<NSObject>> *_insertedItems;
}

+ (instancetype)transactionalComponentDataSourceChangeset { return [[self alloc] init]; }
- (instancetype)withUpdatedItems:(NSDictionary<NSIndexPath *, id<NSObject>> *)updatedItems { _updatedItems = updatedItems; return self;}
- (instancetype)withRemovedItems:(NSSet<NSIndexPath *> *)removedItems { _removedItems = removedItems; return self; }
- (instancetype)withRemovedSections:(NSIndexSet *)removedSections { _removedSections = removedSections; return self; }
- (instancetype)withMovedItems:(NSDictionary<NSIndexPath *, NSIndexPath *> *)movedItems { _movedItems = movedItems; return self; }
- (instancetype)withInsertedSections:(NSIndexSet *)insertedSections { _insertedSections = insertedSections; return self; }
- (instancetype)withInsertedItems:(NSDictionary<NSIndexPath *, id<NSObject>> *)insertedItems { _insertedItems = insertedItems; return self; }

- (CKTransactionalComponentDataSourceChangeset *)build
{
  return [[CKTransactionalComponentDataSourceChangeset alloc] initWithUpdatedItems:_updatedItems
                                                                      removedItems:_removedItems
                                                                   removedSections:_removedSections
                                                                        movedItems:_movedItems
                                                                  insertedSections:_insertedSections
                                                                     insertedItems:_insertedItems];
}

@end
