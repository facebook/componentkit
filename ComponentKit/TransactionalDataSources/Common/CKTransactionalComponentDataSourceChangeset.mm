/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKTransactionalComponentDataSourceChangesetInternal.h"

#import "CKEqualityHashHelpers.h"
#import "CKMacros.h"

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


- (NSString *)description
{
  return [NSString stringWithFormat:@"Updates: %@\nRemoved Items: %@\nRemove Sections: %@\nMoves: %@\nInserted Sections: %@\nInserted Items: %@", _updatedItems, _removedItems, _removedSections, _movedItems, _insertedSections, _insertedItems];
}

- (BOOL)isEqual:(id)object
{
  if (![object isKindOfClass:[CKTransactionalComponentDataSourceChangeset class]]) {
    return NO;
  } else {
    CKTransactionalComponentDataSourceChangeset *obj = (CKTransactionalComponentDataSourceChangeset *)object;
    return
    [_updatedItems isEqualToDictionary:obj.updatedItems] &&
    [_removedItems isEqualToSet:obj.removedItems] &&
    [_removedSections isEqualToIndexSet:obj.removedSections] &&
    [_movedItems isEqualToDictionary:obj.movedItems] &&
    [_insertedSections isEqualToIndexSet:obj.insertedSections] &&
    [_insertedItems isEqual:obj.insertedItems];
  }
}

- (NSUInteger)hash
{
  NSUInteger hashes[6] = {
    [_updatedItems hash],
    [_removedItems hash],
    [_removedSections hash],
    [_movedItems hash],
    [_insertedSections hash],
    [_insertedItems hash]
  };
  return CKIntegerArrayHash(hashes, CK_ARRAY_COUNT(hashes));
}

@end

@implementation CKTransactionalComponentDataSourceChangesetBuilder
{
  NSDictionary *_updatedItems;
  NSSet *_removedItems;
  NSIndexSet *_removedSections;
  NSDictionary *_movedItems;
  NSIndexSet *_insertedSections;
  NSDictionary *_insertedItems;
}

+ (instancetype)transactionalComponentDataSourceChangeset { return [[self alloc] init]; }
- (instancetype)withUpdatedItems:(NSDictionary *)updatedItems { _updatedItems = updatedItems; return self;}
- (instancetype)withRemovedItems:(NSSet *)removedItems { _removedItems = removedItems; return self; }
- (instancetype)withRemovedSections:(NSIndexSet *)removedSections { _removedSections = removedSections; return self; }
- (instancetype)withMovedItems:(NSDictionary *)movedItems { _movedItems = movedItems; return self; }
- (instancetype)withInsertedSections:(NSIndexSet *)insertedSections { _insertedSections = insertedSections; return self; }
- (instancetype)withInsertedItems:(NSDictionary *)insertedItems { _insertedItems = insertedItems; return self; }

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
