/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKDataSourceChangesetModification.h"

#import <map>
#import <mutex>

#import "CKDataSourceConfigurationInternal.h"
#import "CKDataSourceStateInternal.h"
#import "CKDataSourceChange.h"
#import "CKDataSourceChangesetInternal.h"
#import "CKDataSourceItemInternal.h"
#import "CKDataSourceAppliedChanges.h"
#import "CKBuildComponent.h"
#import "CKComponentControllerEvents.h"
#import "CKComponentEvents.h"
#import "CKComponentLayout.h"
#import "CKComponentProvider.h"
#import "CKComponentScopeFrame.h"
#import "CKComponentScopeRoot.h"
#import "CKComponentScopeRootFactory.h"
#import "CKDataSourceModificationHelper.h"
#import "CKIndexSetDescription.h"
#import "CKInvalidChangesetOperationType.h"

@implementation CKDataSourceChangesetModification
{
  id<CKComponentStateListener> _stateListener;
  NSDictionary *_userInfo;
  dispatch_queue_t _queue;
  std::mutex _mutex;
}

- (instancetype)initWithChangeset:(CKDataSourceChangeset *)changeset
                    stateListener:(id<CKComponentStateListener>)stateListener
                         userInfo:(NSDictionary *)userInfo
{
  return [self initWithChangeset:changeset
                   stateListener:stateListener
                        userInfo:userInfo
                           queue:nil];
}

- (instancetype)initWithChangeset:(CKDataSourceChangeset *)changeset
                    stateListener:(id<CKComponentStateListener>)stateListener
                         userInfo:(NSDictionary *)userInfo
                            queue:(dispatch_queue_t)queue
{
  if (self = [super init]) {
    _changeset = changeset;
    _stateListener = stateListener;
    _userInfo = [userInfo copy];
    _queue = queue;
  }
  return self;
}

- (CKDataSourceChange *)changeFromState:(CKDataSourceState *)oldState
{
  CKDataSourceConfiguration *configuration = [oldState configuration];
  id<NSObject> context = [configuration context];
  const CKSizeRange sizeRange = [configuration sizeRange];
  const auto animationPredicates = CKComponentAnimationPredicates(configuration.animationOptions);

  NSMutableArray *newSections = [NSMutableArray array];
  [[oldState sections] enumerateObjectsUsingBlock:^(NSArray *items, NSUInteger sectionIdx, BOOL *sectionStop) {
    [newSections addObject:[items mutableCopy]];
  }];

  // Update items
  if (configuration.parallelUpdateBuildAndLayout &&
      [_changeset updatedItems].count >= configuration.parallelUpdateBuildAndLayoutThreshold &&
      _queue) {
    dispatch_group_t group = dispatch_group_create();
    [[_changeset updatedItems] enumerateKeysAndObjectsUsingBlock:^(NSIndexPath *indexPath, id model, BOOL *stop) {
      NSMutableArray *const section = newSections[indexPath.section];
      std::lock_guard<std::mutex> lRead(_mutex);
      CKDataSourceItem *const oldItem = section[indexPath.item];
      dispatch_group_async(group, _queue, ^{
        CKDataSourceItem *const item = CKBuildDataSourceItem([oldItem scopeRoot], {}, sizeRange, configuration, model, context, animationPredicates);
        std::lock_guard<std::mutex> lWrite(_mutex);
        [section replaceObjectAtIndex:indexPath.item withObject:item];
      });
    }];
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
  } else {
    [[_changeset updatedItems] enumerateKeysAndObjectsUsingBlock:^(NSIndexPath *indexPath, id model, BOOL *stop) {
      if (indexPath.section >= newSections.count) {
        CKCFatalWithCategory(CKHumanReadableInvalidChangesetOperationType(CKInvalidChangesetOperationTypeUpdate),
                             @"Invalid section: %lu (>= %lu). Changeset: %@, user info: %@, state: %@",
                             (unsigned long)indexPath.section,
                             (unsigned long)newSections.count,
                             _changeset,
                             _userInfo,
                             oldState);
      }
      NSMutableArray *const section = newSections[indexPath.section];
      if (indexPath.item >= section.count) {
        CKCFatalWithCategory(CKHumanReadableInvalidChangesetOperationType(CKInvalidChangesetOperationTypeUpdate),
                             @"Invalid item: %lu (>= %lu). Changeset: %@, user info: %@, state: %@",
                             (unsigned long)indexPath.item,
                             (unsigned long)section.count,
                             _changeset,
                             _userInfo,
                             oldState);
      }
      CKDataSourceItem *const oldItem = section[indexPath.item];
      CKDataSourceItem *const item = CKBuildDataSourceItem([oldItem scopeRoot], {}, sizeRange, configuration, model, context, animationPredicates);
      [section replaceObjectAtIndex:indexPath.item withObject:item];
    }];
  }

  __block std::unordered_map<NSUInteger, std::map<NSUInteger, CKDataSourceItem *>> insertedItemsBySection;
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
    if (from.section >= newSections.count) {
      CKCFatalWithCategory(CKHumanReadableInvalidChangesetOperationType(CKInvalidChangesetOperationTypeMoveRow),
                           @"Invalid section: %lu (>= %lu) while processing moved items. Changeset: %@, user info: %@, state: %@",
                           (unsigned long)from.section,
                           (unsigned long)newSections.count,
                           CK::changesetDescription(_changeset),
                           _userInfo,
                           oldState);
    }
    const auto fromSection = static_cast<NSArray *>(newSections[from.section]);
    if (from.item >= fromSection.count) {
      CKCFatalWithCategory(CKHumanReadableInvalidChangesetOperationType(CKInvalidChangesetOperationTypeMoveRow),
                           @"Invalid item: %lu (>= %lu) while processing moved items. Changeset: %@, user info: %@, state: %@",
                           (unsigned long)from.item,
                           (unsigned long)fromSection.count,
                           CK::changesetDescription(_changeset),
                           _userInfo,
                           oldState);
    }
    insertedItemsBySection[to.section][to.row] = fromSection[from.item];
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
    if (it.first >= newSections.count) {
      CKCFatalWithCategory(CKHumanReadableInvalidChangesetOperationType(CKInvalidChangesetOperationTypeRemoveRow),
                           @"Invalid section: %lu (>= %lu) while processing moved items. Changeset: %@, user info: %@, state: %@",
                           (unsigned long)it.first,
                           (unsigned long)newSections.count,
                           CK::changesetDescription(_changeset),
                           _userInfo,
                           oldState);
    }
    const auto section = static_cast<NSMutableArray *>(newSections[it.first]);
#ifdef CK_ASSERTIONS_ENABLED
    const auto invalidIndexes = CK::invalidIndexesForRemovalFromArray(section, it.second);
    if (invalidIndexes.count > 0) {
      CKCFatalWithCategory(CKHumanReadableInvalidChangesetOperationType(CKInvalidChangesetOperationTypeRemoveRow),
                           @"%@ (>= %lu) in section: %lu. Changeset: %@, user info: %@, state: %@",
                           CK::indexSetDescription(invalidIndexes, @"Invalid indexes", 0),
                           (unsigned long)section.count,
                           (unsigned long)it.first,
                           CK::changesetDescription(_changeset),
                           _userInfo,
                           oldState);
    }
#endif
    [section removeObjectsAtIndexes:it.second];
  }

  // Remove sections
  [newSections removeObjectsAtIndexes:[_changeset removedSections]];

  // Insert sections
  [newSections insertObjects:emptyMutableArrays([[_changeset insertedSections] count]) atIndexes:[_changeset insertedSections]];

  // Insert items
  if (configuration.parallelInsertBuildAndLayout &&
      [_changeset insertedItems].count >= configuration.parallelInsertBuildAndLayoutThreshold &&
      _queue) {
    dispatch_group_t group = dispatch_group_create();
    [[_changeset insertedItems] enumerateKeysAndObjectsUsingBlock:^(NSIndexPath *indexPath, id model, BOOL *stop) {
      dispatch_group_async(group, _queue, ^{
        CKDataSourceItem *const item = CKBuildDataSourceItem(CKComponentScopeRootWithPredicates(_stateListener,
                                                                                                configuration.analyticsListener,
                                                                                                configuration.componentPredicates,
                                                                                                configuration.componentControllerPredicates), {},
                                                             sizeRange,
                                                             configuration,
                                                             model,
                                                             context,
                                                             animationPredicates);
        std::lock_guard<std::mutex> l(_mutex);
        insertedItemsBySection[indexPath.section][indexPath.item] = item;
      });
    }];
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
  } else {
    [[_changeset insertedItems] enumerateKeysAndObjectsUsingBlock:^(NSIndexPath *indexPath, id model, BOOL *stop) {
      CKDataSourceItem *const item = CKBuildDataSourceItem(CKComponentScopeRootWithPredicates(_stateListener,
                                                                                              configuration.analyticsListener,
                                                                                              configuration.componentPredicates,
                                                                                              configuration.componentControllerPredicates), {},
                                                           sizeRange,
                                                           configuration,
                                                           model,
                                                           context,
                                                           animationPredicates);
      insertedItemsBySection[indexPath.section][indexPath.item] = item;
    }];
  }

  for (const auto &sectionIt : insertedItemsBySection) {
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    NSMutableArray *items = [NSMutableArray array];
    // Note this enumeration is ordered by virtue of std::map, which is crucial (we need items to match indexes):
    for (const auto &itemIt : sectionIt.second) {
      [indexes addIndex:itemIt.first];
      [items addObject:itemIt.second];
    }

    if (sectionIt.first >= newSections.count) {
      CKCFatalWithCategory(CKHumanReadableInvalidChangesetOperationType(CKInvalidChangesetOperationTypeInsertRow),
                           @"Invalid section: %lu (>= %lu) while processing inserted items. Changeset: %@, user info: %@, state: %@",
                           (unsigned long)sectionIt.first,
                           (unsigned long)newSections.count,
                           CK::changesetDescription(_changeset),
                           _userInfo,
                           oldState);
    }
#ifdef CK_ASSERTIONS_ENABLED
    const auto sectionItems = static_cast<NSArray *>([newSections objectAtIndex:sectionIt.first]);
    const auto invalidIndexes = CK::invalidIndexesForInsertionInArray(sectionItems, indexes);
    if (invalidIndexes.count > 0) {
      CKCFatalWithCategory(CKHumanReadableInvalidChangesetOperationType(CKInvalidChangesetOperationTypeInsertRow),
                           @"%@ for range: %@ in section: %lu. Changeset: %@, user info: %@, state: %@",
                           CK::indexSetDescription(invalidIndexes, @"Invalid indexes", 0),
                           NSStringFromRange({0, sectionItems.count}),
                           (unsigned long)sectionIt.first,
                           CK::changesetDescription(_changeset),
                           _userInfo,
                           oldState);
    }
#endif
    [[newSections objectAtIndex:sectionIt.first] insertObjects:items atIndexes:indexes];
  }

  CKDataSourceState *newState =
  [[CKDataSourceState alloc] initWithConfiguration:configuration
                                          sections:newSections];

  CKDataSourceAppliedChanges *appliedChanges =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithArray:[[_changeset updatedItems] allKeys]]
                                              removedIndexPaths:[_changeset removedItems]
                                                removedSections:[_changeset removedSections]
                                                movedIndexPaths:[_changeset movedItems]
                                               insertedSections:[_changeset insertedSections]
                                             insertedIndexPaths:[NSSet setWithArray:[[_changeset insertedItems] allKeys]]
                                                       userInfo:_userInfo];

  return [[CKDataSourceChange alloc] initWithState:newState
                                    appliedChanges:appliedChanges];
}

- (NSDictionary *)userInfo
{
  return _userInfo;
}

- (NSString *)description
{
  return [_changeset description];
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

#ifdef CK_ASSERTIONS_ENABLED
namespace CK {
  auto invalidIndexesForInsertionInArray(NSArray *const a, NSIndexSet *const is) -> NSIndexSet *
  {
    auto r = [NSMutableIndexSet new];
    __block auto arrayCount = a.count;
    [is enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull) {
      if (idx > arrayCount) {
        [r addIndex:idx];
      }
      arrayCount++;
    }];
    return r;
  }

  auto invalidIndexesForRemovalFromArray(NSArray *const a, NSIndexSet *const is) -> NSIndexSet *
  {
    auto r = [NSMutableIndexSet new];
    [is enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull) {
      if (idx >= a.count) {
        [r addIndex:idx];
      }
    }];
    return r;
  }
}
#endif
