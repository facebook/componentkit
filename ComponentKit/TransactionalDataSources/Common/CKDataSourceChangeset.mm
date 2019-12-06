/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */
#import "CKDataSourceChangeset.h"
#import "CKDataSourceChangesetInternal.h"

#import <UIKit/UICollectionView.h>
#import <UIKit/UITableView.h>

#import <ComponentKit/CKEqualityHelpers.h>
#import <ComponentKit/CKMacros.h>
#import <ComponentKit/CKAssert.h>

#import "CKIndexSetDescription.h"

@implementation CKDataSourceChangeset

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
  return CK::changesetDescription(self);
}

- (BOOL)isEmpty
{
  return
  (_insertedSections.count == 0 &&
   _removedSections.count == 0 &&
   _updatedItems.count == 0 &&
   _movedItems.count == 0 &&
   _insertedItems.count == 0 &&
   _removedItems.count == 0);
}

- (BOOL)isEqual:(id)object
{
  if (![object isKindOfClass:[CKDataSourceChangeset class]]) {
    return NO;
  } else {
    CKDataSourceChangeset *obj = (CKDataSourceChangeset *)object;
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

@implementation CKDataSourceChangesetBuilder
{
  NSDictionary *_updatedItems;
  NSSet *_removedItems;
  NSIndexSet *_removedSections;
  NSDictionary *_movedItems;
  NSIndexSet *_insertedSections;
  NSDictionary *_insertedItems;
}

+ (instancetype)dataSourceChangeset { return [[self alloc] init]; }
- (instancetype)withUpdatedItems:(NSDictionary *)updatedItems { _updatedItems = updatedItems; return self;}
- (instancetype)withRemovedItems:(NSSet *)removedItems { _removedItems = removedItems; return self; }
- (instancetype)withRemovedSections:(NSIndexSet *)removedSections { _removedSections = removedSections; return self; }
- (instancetype)withMovedItems:(NSDictionary *)movedItems { _movedItems = movedItems; return self; }
- (instancetype)withInsertedSections:(NSIndexSet *)insertedSections { _insertedSections = insertedSections; return self; }
- (instancetype)withInsertedItems:(NSDictionary *)insertedItems { _insertedItems = insertedItems; return self; }

- (CKDataSourceChangeset *)build
{
  return [[CKDataSourceChangeset alloc] initWithUpdatedItems:_updatedItems
                                                                      removedItems:_removedItems
                                                                   removedSections:_removedSections
                                                                        movedItems:_movedItems
                                                                  insertedSections:_insertedSections
                                                                     insertedItems:_insertedItems];
}

@end

namespace CK {
  static auto withNewLineIfNotEmpty(NSString const* s) -> NSString *
  {
    return s.length > 0 ? [s stringByAppendingString:@"\n"] : @"";
  }

  auto itemsByIndexPathDescription(NSDictionary<NSIndexPath *, NSObject *> * const items, NSString * const title) -> NSString *
  {
    if (items.count == 0) {
      return @"";
    }

    auto description = [NSMutableString new];
    [description appendFormat:@"  %@: {\n", title];
    auto itemStrings = static_cast<NSMutableArray <NSString *> *>([NSMutableArray new]);
    const auto sortedIps = [[items allKeys] sortedArrayUsingSelector:@selector(compare:)];
    for (NSIndexPath * const ip in sortedIps) {
      const auto itemStr = [NSString stringWithFormat:@"    (%ld-%ld): %@", (long)ip.section, (long)ip.item, items[ip]];
      [itemStrings addObject:itemStr];
    }
    [description appendString:[itemStrings componentsJoinedByString:@",\n"]];
    [description appendString:@"\n  }\n"];
    return description;
  }

  static auto movedItemsDescription(NSDictionary<NSIndexPath *, NSIndexPath *> * const ips) -> NSString *
  {
    if (ips.count == 0) {
      return @"";
    }

    auto description = [NSMutableString new];
    [description appendString:@"  Moved Items: {\n"];
    auto ipStrings = static_cast<NSMutableArray <NSString *> *>([NSMutableArray new]);
    const auto sortedIps = [[ips allKeys] sortedArrayUsingSelector:@selector(compare:)];
    for (NSIndexPath * const ip in sortedIps) {
      const auto ipStr = [NSString stringWithFormat:@"    (%ld-%ld) → (%ld-%ld)", (long)ip.section, (long)ip.item, (long)ips[ip].section, (long)ips[ip].item];
      [ipStrings addObject:ipStr];
    }
    [description appendString:[ipStrings componentsJoinedByString:@",\n"]];
    [description appendString:@"\n  }\n"];
    return description;
  }

  static auto removedItemsDescription(NSSet<NSIndexPath *> const* ips) -> NSString *
  {
    if (ips.count == 0) {
      return @"";
    }

    auto description = [NSMutableString new];
    [description appendString:@"  Removed Items: {\n"];
    auto items = static_cast<NSMutableArray<NSString *> *>([NSMutableArray new]);
    const auto sortedIps = [[ips allObjects] sortedArrayUsingSelector:@selector(compare:)];
    for (NSIndexPath * const ip : sortedIps) {
      const auto ipStr = [NSString stringWithFormat:@"    (%ld-%ld)", (long)ip.section, (long)ip.item];
      [items addObject:ipStr];
    }
    [description appendString:[items componentsJoinedByString:@",\n"]];
    [description appendString:@"\n  }\n"];
    return description;
  }

  auto changesetDescription(const CKDataSourceChangeset *const changeset) -> NSString *
  {
    if (changeset.isEmpty) {
      return @"";
    }

    auto description = [NSMutableString new];
    [description appendString:@"{\n"];
    [description appendString:itemsByIndexPathDescription(changeset.updatedItems, @"Updated Items")];
    [description appendString:removedItemsDescription(changeset.removedItems)];
    [description appendString:withNewLineIfNotEmpty(indexSetDescription(changeset.removedSections, @"Removed Sections", 2))];
    [description appendString:movedItemsDescription(changeset.movedItems)];
    [description appendString:withNewLineIfNotEmpty(indexSetDescription(changeset.insertedSections, @"Inserted Sections", 2))];
    [description appendString:itemsByIndexPathDescription(changeset.insertedItems, @"Inserted Items")];
    [description appendString:@"}"];
    return description;
  }
}
