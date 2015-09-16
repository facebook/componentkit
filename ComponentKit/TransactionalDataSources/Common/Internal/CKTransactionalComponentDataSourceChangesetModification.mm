/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKTransactionalComponentDataSourceChangesetModification.h"

#import <map>

#import "CKArgumentPrecondition.h"
#import "CKFunctor.h"
#import "CKTransactionalComponentDataSourceConfiguration.h"
#import "CKTransactionalComponentDataSourceStateInternal.h"
#import "CKTransactionalComponentDataSourceChange.h"
#import "CKTransactionalComponentDataSourceChangesetInternal.h"
#import "CKTransactionalComponentDataSourceItemInternal.h"
#import "CKTransactionalComponentDataSourceAppliedChangesInternal.h"
#import "CKComponentLayout.h"
#import "CKComponentProvider.h"
#import "CKComponentScopeFrame.h"
#import "CKComponentScopeRoot.h"
#import "CKComponentSubclass.h"

@implementation CKTransactionalComponentDataSourceChangesetModification
{
  CKTransactionalComponentDataSourceChangeset *_changeset;
  id<CKComponentStateListener> _stateListener;
  NSDictionary *_userInfo;
}

- (instancetype)initWithChangeset:(CKTransactionalComponentDataSourceChangeset *)changeset
                    stateListener:(id<CKComponentStateListener>)stateListener
                         userInfo:(NSDictionary *)userInfo
{
  if (self = [super init]) {
    _changeset = changeset;
    _stateListener = stateListener;
    _userInfo = [userInfo copy];
  }
  return self;
}

- (CKTransactionalComponentDataSourceChange *)changeFromState:(CKTransactionalComponentDataSourceState *)oldState
{
  CKTransactionalComponentDataSourceConfiguration *configuration = [oldState configuration];
  Class<CKComponentProvider> componentProvider = [configuration componentProvider];
  id<NSObject> context = [configuration context];
  const CKSizeRange sizeRange = [configuration sizeRange];

  NSMutableArray *newSections = [NSMutableArray array];
  [[oldState sections] enumerateObjectsUsingBlock:^(NSArray *items, NSUInteger sectionIdx, BOOL *sectionStop) {
    [newSections addObject:[items mutableCopy]];
  }];

  // Update items
  // This structure is used for computing post-changeset-application index paths for updated items.
  __block std::unordered_map<CKTransactionalComponentDataSourceItem *, NSIndexPath *, CK::HashFunctor<NSObject *>> itemToInitialIndexPathMap;
  [[_changeset updatedItems] enumerateKeysAndObjectsUsingBlock:^(NSIndexPath *indexPath, id model, BOOL *stop) {
    NSMutableArray *section = newSections[indexPath.section];
    CKTransactionalComponentDataSourceItem *oldItem = section[indexPath.item];

    const CKBuildComponentResult result = CKBuildComponent([oldItem scopeRoot], {}, ^{
      return [componentProvider componentForModel:model context:context];
    });
    const CKComponentLayout layout = [result.component layoutThatFits:sizeRange parentSize:sizeRange.max];

    CKTransactionalComponentDataSourceItem *newItem = [[CKTransactionalComponentDataSourceItem alloc] initWithLayout:layout model:model scopeRoot:result.scopeRoot];
    [section replaceObjectAtIndex:indexPath.item withObject:newItem];
    itemToInitialIndexPathMap[newItem] = indexPath;
  }];

  __block std::unordered_map<NSUInteger, std::map<NSUInteger, CKTransactionalComponentDataSourceItem *>> insertedItemsBySection;
  __block std::unordered_map<NSUInteger, NSMutableIndexSet *> removedItemsBySection;
  void (^addRemovedIndexPath)(NSIndexPath *) = ^(NSIndexPath *ip){
    const auto &element = removedItemsBySection.find(ip.section);
    if (element == removedItemsBySection.end()) {
      removedItemsBySection.insert({ip.section, [NSMutableIndexSet indexSetWithIndex:ip.item]});
    } else {
      [element->second addIndex:ip.item];
    }
  };

  // Moves: first record as inserts for later processing
  [[_changeset movedItems] enumerateKeysAndObjectsUsingBlock:^(NSIndexPath *from, NSIndexPath *to, BOOL *stop) {
    insertedItemsBySection[to.section][to.row] = newSections[from.section][from.item];
  }];

  // Moves: then record as removals
  [[_changeset movedItems] enumerateKeysAndObjectsUsingBlock:^(NSIndexPath *from, NSIndexPath *to, BOOL *stop) {
    addRemovedIndexPath(from);
  }];

  // Remove items
  for (NSIndexPath *removedItem in [_changeset removedItems]) {
    addRemovedIndexPath(removedItem);
  }
  for (const auto &it : removedItemsBySection) {
    [[newSections objectAtIndex:it.first] removeObjectsAtIndexes:it.second];
  }

  // Remove sections
  [newSections removeObjectsAtIndexes:[_changeset removedSections]];

  // Insert sections
  [newSections insertObjects:emptyMutableArrays([[_changeset insertedSections] count]) atIndexes:[_changeset insertedSections]];

  // Insert items
  [[_changeset insertedItems] enumerateKeysAndObjectsUsingBlock:^(NSIndexPath *indexPath, id model, BOOL *stop) {
    const CKBuildComponentResult result = CKBuildComponent([CKComponentScopeRoot rootWithListener:_stateListener], {}, ^{
      return [componentProvider componentForModel:model context:context];
    });
    const CKComponentLayout layout = [result.component layoutThatFits:sizeRange parentSize:sizeRange.max];
    insertedItemsBySection[indexPath.section][indexPath.item] =
    [[CKTransactionalComponentDataSourceItem alloc] initWithLayout:layout model:model scopeRoot:result.scopeRoot];
  }];

  for (const auto &sectionIt : insertedItemsBySection) {
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    NSMutableArray *items = [NSMutableArray array];
    // Note this enumeration is ordered by virtue of std::map, which is crucial (we need items to match indexes):
    for (const auto &itemIt : sectionIt.second) {
      [indexes addIndex:itemIt.first];
      [items addObject:itemIt.second];
    }
    [[newSections objectAtIndex:sectionIt.first] insertObjects:items atIndexes:indexes];
  }

  NSDictionary *updatedIndexPaths = computeUpdateIndexPaths(newSections, itemToInitialIndexPathMap);
  CKTransactionalComponentDataSourceState *newState =
  [[CKTransactionalComponentDataSourceState alloc] initWithConfiguration:configuration
                                                                sections:newSections];
  CKTransactionalComponentDataSourceAppliedChanges *appliedChanges =
  [[CKTransactionalComponentDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:updatedIndexPaths
                                                                    removedIndexPaths:[_changeset removedItems]
                                                                      removedSections:[_changeset removedSections]
                                                                      movedIndexPaths:[_changeset movedItems]
                                                                     insertedSections:[_changeset insertedSections]
                                                                   insertedIndexPaths:[NSSet setWithArray:[[_changeset insertedItems] allKeys]]
                                                                             userInfo:_userInfo];

  return [[CKTransactionalComponentDataSourceChange alloc] initWithState:newState
                                                          appliedChanges:appliedChanges];
}

/**
 This function computes a pre-changeset-application -> post-changeset-application index path map for updated items.
 It does a linear pass over all items (in `newState`), and each item is looked up in a previously constructed map (`itemToInitialIndexPathMap`) of item -> pre-changeset-application index path.
 If it exists we know it was updated and can easily create the mapping (since `newState` is post-changeset-application).
 */
static NSDictionary *computeUpdateIndexPaths(NSArray *newState, const std::unordered_map<CKTransactionalComponentDataSourceItem *, NSIndexPath *, CK::HashFunctor<NSObject *>> &itemToInitialIndexPathMap)
{
  __block NSMutableDictionary *updatedItemIndexPaths = [NSMutableDictionary dictionary];
  [newState enumerateObjectsUsingBlock:^(NSArray *items, NSUInteger sectionIdx, BOOL *sectionStop) {
    [items enumerateObjectsUsingBlock:^(CKTransactionalComponentDataSourceItem *item, NSUInteger index, BOOL *stop) {
      const auto &itemIndexPathPair = itemToInitialIndexPathMap.find(item);
      if (itemIndexPathPair != itemToInitialIndexPathMap.end()) {
        updatedItemIndexPaths[itemIndexPathPair->second] = [NSIndexPath indexPathForItem:index inSection:sectionIdx];
      }
    }];
  }];
  CKInternalConsistencyCheckIf([updatedItemIndexPaths count] == itemToInitialIndexPathMap.size(), @"There are not enough (or too much) updates in the state after applying the changeset. It probably means your changeset is invalid.");
  return updatedItemIndexPaths;
}

static NSArray *emptyMutableArrays(NSUInteger count)
{
  NSMutableArray *arrays = [NSMutableArray array];
  for (NSUInteger i = 0; i < count; i++) {
    [arrays addObject:[NSMutableArray array]];
  }
  return arrays;
}

@end
