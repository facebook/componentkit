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

- (instancetype)initWithUpdatedItems:(NSDictionary *)updatedItems
                        removedItems:(NSSet *)removedItems
                     removedSections:(NSIndexSet *)removedSections
                          movedItems:(NSDictionary *)movedItems
                    insertedSections:(NSIndexSet *)insertedSections
                       insertedItems:(NSDictionary *)insertedItems
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
  id _updatedItems;
  id _removedItems;
  id _removedSections;
  id _movedItems;
  id _insertedSections;
  id _insertedItems;
}

+ (instancetype)transactionalComponentDataSourceChangeset { return [[self alloc] init]; }

- (instancetype)withUpdatedItems:(NSDictionary *)updatedItems {
  if (_updatedItems) {
    _updatedItems = [_updatedItems mutableCopy];
    [_updatedItems addEntriesFromDictionary:updatedItems];
  } else {
    _updatedItems = updatedItems;
  }
	return self;
}

- (instancetype)withRemovedItems:(NSSet *)removedItems {
  if (_removedItems) {
    _removedItems = [_removedItems mutableCopy];
    [_removedItems addObjectsFromArray:removedItems.allObjects];
  } else {
    _removedItems = removedItems;
  }
  return self;
}

- (instancetype)withRemovedSections:(NSIndexSet *)removedSections {
  if (_removedSections) {
    _removedSections = [_removedSections mutableCopy];
    [_removedSections addIndexes:removedSections];
  } else {
    _removedSections = removedSections;
  }
  return self;
}

- (instancetype)withMovedItems:(NSDictionary *)movedItems {
  if (_movedItems) {
    _movedItems = [_movedItems mutableCopy];
    [_movedItems addEntriesFromDictionary:movedItems];
  } else {
    _movedItems = movedItems;
  }
  return self;
}

- (instancetype)withInsertedSections:(NSIndexSet *)insertedSections {
  if (_insertedSections) {
    _insertedSections = [_insertedSections mutableCopy];
    [_insertedSections addIndexes:insertedSections];
  } else {
    _insertedSections = insertedSections;
  }
  return self;
}

- (instancetype)withInsertedItems:(NSDictionary *)insertedItems {
  if (_insertedItems) {
    _insertedItems = [_insertedItems mutableCopy];
    [_insertedItems addEntriesFromDictionary:insertedItems];
  } else {
    _insertedItems = insertedItems;
  }
  return self;
}

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
