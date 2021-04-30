/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKDataSourceSplitChangesetModification.h"

#import <map>
#import <mutex>

#import "CKDataSourceConfigurationInternal.h"
#import "CKDataSourceStateInternal.h"
#import "CKDataSourceChange.h"
#import "CKDataSourceChangesetInternal.h"
#import "CKDataSourceChangesetModification.h"
#import "CKDataSourceItemInternal.h"
#import "CKDataSourceAppliedChanges.h"
#import "CKBuildComponent.h"
#import "CKComponentControllerEvents.h"
#import "CKComponentEvents.h"
#import "CKComponentControllerHelper.h"
#import "CKComponentLayout.h"
#import "CKComponentProvider.h"
#import "CKComponentScopeFrame.h"
#import "CKComponentScopeRoot.h"
#import "CKComponentScopeRootFactory.h"
#import "CKDataSourceModificationHelper.h"
#import "CKIndexSetDescription.h"
#import "CKInvalidChangesetOperationType.h"
#import "CKFatal.h"

using namespace CKComponentControllerHelper;

@implementation CKDataSourceSplitChangesetModification
{
  __weak id<CKComponentStateListener> _stateListener;
  NSDictionary *_userInfo;
  CKDataSourceViewport _viewport;
  CKDataSourceQOS _qos;
}

- (instancetype)initWithChangeset:(CKDataSourceChangeset *)changeset
                    stateListener:(id<CKComponentStateListener>)stateListener
                         userInfo:(NSDictionary *)userInfo
                         viewport:(CKDataSourceViewport)viewport
                              qos:(CKDataSourceQOS)qos
{
  if (self = [super init]) {
    _changeset = changeset;
    _stateListener = stateListener;
    _userInfo = [userInfo copy];
    _viewport = viewport;
    _qos = qos;
  }
  return self;
}

- (CKDataSourceChange *)changeFromState:(CKDataSourceState *)oldState
{
  CKDataSourceConfiguration *configuration = [oldState configuration];
  id<NSObject> context = [configuration context];
  const CKSizeRange sizeRange = [configuration sizeRange];
  const auto splitChangesetOptions = [configuration options].splitChangesetOptions;
  const BOOL enableChangesetSplitting = splitChangesetOptions.enabled;
  const CGSize viewportSize = (_viewport.size.width == 0.0 || _viewport.size.height == 0.0)
  ? splitChangesetOptions.viewportBoundingSize
  : _viewport.size;

  NSMutableArray<CKComponentController *> *addedComponentControllers = [NSMutableArray array];
  NSMutableArray<CKComponentController *> *invalidComponentControllers = [NSMutableArray array];

  NSMutableArray *newSections = [NSMutableArray array];
  [[oldState sections] enumerateObjectsUsingBlock:^(NSArray *items, NSUInteger sectionIdx, BOOL *sectionStop) {
    [newSections addObject:[items mutableCopy]];
  }];

  // Update items
  NSDictionary<NSIndexPath *, id> *const updatedItems = [_changeset updatedItems];
  NSDictionary<NSIndexPath *, id> *initialUpdatedItems = nil;
  NSDictionary<NSIndexPath *, id> *deferredUpdatedItems = nil;

  if (enableChangesetSplitting && splitChangesetOptions.splitUpdates) {
    const CKDataSourceSplitUpdateResult result =
    splitUpdatedItems(newSections,
                      updatedItems,
                      addedComponentControllers,
                      invalidComponentControllers,
                      sizeRange,
                      configuration,
                      context,
                      _changeset,
                      _userInfo,
                      oldState,
                      viewportSize,
                      splitChangesetOptions.layoutAxis,
                      _viewport.contentOffset);
    initialUpdatedItems = result.splitItems.initialChangesetItems;
    deferredUpdatedItems = result.splitItems.deferredChangesetItems;
    [result.computedItems enumerateKeysAndObjectsUsingBlock:^(NSIndexPath *indexPath, CKDataSourceItem *item, BOOL *stop) {
      NSMutableArray *const section = newSections[indexPath.section];
      [section replaceObjectAtIndex:indexPath.item withObject:item];
    }];
  } else {
    initialUpdatedItems = updatedItems;
    [updatedItems enumerateKeysAndObjectsUsingBlock:^(NSIndexPath *indexPath, id model, BOOL *stop) {
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
      CKDataSourceItem *const item = CKBuildDataSourceItem([oldItem scopeRoot], {}, sizeRange, configuration, model, context);
      [section replaceObjectAtIndex:indexPath.item withObject:item];
      for (auto componentController : addedControllersFromPreviousScopeRootMatchingPredicate(item.scopeRoot,
                                                                                             oldItem.scopeRoot,
                                                                                             &CKComponentControllerInitializeEventPredicate)) {
        [addedComponentControllers addObject:componentController];
      }
      for (auto componentController : removedControllersFromPreviousScopeRootMatchingPredicate(item.scopeRoot,
                                                                                               oldItem.scopeRoot,
                                                                                               &CKComponentControllerInvalidateEventPredicate)) {
        [invalidComponentControllers addObject:componentController];
      }
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
  // Used to keep track of the items in each section that have been marked for a deferred update,
  // once removals are processed we use this to compute the final set of deferred updates using the correct indices.
  NSMutableArray<NSMutableArray<id> *> *sectionsForDeferredUpdatedItems = nil;
  if (deferredUpdatedItems.count != 0) {
    sectionsForDeferredUpdatedItems = [NSMutableArray<NSMutableArray<id> *> arrayWithCapacity:newSections.count];
    [sectionsForDeferredUpdatedItems addObjectsFromArray:emptyMutableArrays(newSections.count)];
    [newSections enumerateObjectsUsingBlock:^(NSArray<CKDataSourceItem *> *items, NSUInteger idx, BOOL *stop) {
      [sectionsForDeferredUpdatedItems[idx] addObjectsFromArray:nullPlaceholderArray(items.count)];
    }];
    [deferredUpdatedItems enumerateKeysAndObjectsUsingBlock:^(NSIndexPath *indexPath, id obj, BOOL *stop) {
      sectionsForDeferredUpdatedItems[indexPath.section][indexPath.item] = obj;
    }];
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
#if CK_ASSERTIONS_ENABLED
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
    [sectionsForDeferredUpdatedItems[it.first] removeObjectsAtIndexes:it.second];
  }

  // Remove sections
  NSIndexSet *const removedSections = [_changeset removedSections];
  if ([removedSections count] > 0) {
    [newSections removeObjectsAtIndexes:removedSections];
    [sectionsForDeferredUpdatedItems removeObjectsAtIndexes:removedSections];
  }

  // Insert sections

  // Quick validation to make sure the locations specified by indexes do not exceed the bounds of the receiving array.
  if ([[_changeset insertedSections] count] > 0 &&
      ([[_changeset insertedSections] firstIndex] > newSections.count)) {
    CKCFatalWithCategory(CKHumanReadableInvalidChangesetOperationType(CKInvalidChangesetOperationTypeInsertSection),
                         @"Invalid first index location: %lu (> %lu) while processing inserted sections. Changeset: %@, user info: %@, state: %@",
                         (unsigned long)[[_changeset insertedSections] firstIndex],
                         (unsigned long)newSections.count,
                         CK::changesetDescription(_changeset),
                         _userInfo,
                         oldState);
  }
#if CK_ASSERTIONS_ENABLED
    // Deep validation of the indexes we are going to insert for better logging.
  auto const invalidInsertedSectionsIndexes = CK::invalidIndexesForInsertionInArray(newSections, [_changeset insertedSections]);
  if (invalidInsertedSectionsIndexes.count) {
  CKCFatalWithCategory(CKHumanReadableInvalidChangesetOperationType(CKInvalidChangesetOperationTypeInsertSection),
                       @"%@ for range: %@ in sections: %@. Changeset: %@, user info: %@, state: %@",
                       CK::indexSetDescription(invalidInsertedSectionsIndexes, @"Invalid indexes", 0),
                       NSStringFromRange({0, newSections.count}),
                       newSections,
                       CK::changesetDescription(_changeset),
                       _userInfo,
                       oldState);
  }
#endif
  [newSections insertObjects:emptyMutableArrays([[_changeset insertedSections] count]) atIndexes:[_changeset insertedSections]];
  if (sectionsForDeferredUpdatedItems != nil) {
    [sectionsForDeferredUpdatedItems insertObjects:emptyMutableArrays([[_changeset insertedSections] count]) atIndexes:[_changeset insertedSections]];
  }

  // Insert items
  const auto buildItem = ^CKDataSourceItem *(id model) {
    return CKBuildDataSourceItem(CKComponentScopeRootWithPredicates(_stateListener,
                                                                    configuration.analyticsListener,
                                                                    configuration.componentPredicates,
                                                                    configuration.componentControllerPredicates), {},
                                 sizeRange,
                                 configuration,
                                 model,
                                 context);
  };

  NSDictionary<NSIndexPath *, id> *const insertedItems = [_changeset insertedItems];
  NSDictionary<NSIndexPath *, id> *initialInsertedItems = nil;
  NSDictionary<NSIndexPath *, id> *deferredInsertedItems = nil;

  if (enableChangesetSplitting) {
    // Compute the height of the existing content (after updates and removals) -- if changeset splitting is
    // enabled and the content is already overflowing the viewport, we won't split the changeset.
    __block CGSize contentSize = computeTotalHeightOfSections(newSections);
    if (!contentSizeOverflowsViewportAtTail(contentSize, _viewport.contentOffset, viewportSize, splitChangesetOptions.layoutAxis)) {
      NSArray<NSIndexPath *> *const sortedIndexPaths = [[insertedItems allKeys] sortedArrayUsingSelector:@selector(compare:)];
      if (indexPathsAreContiguousAtTail(sortedIndexPaths, newSections)) {
        __block NSUInteger endIndex = sortedIndexPaths.count;
        [sortedIndexPaths enumerateObjectsUsingBlock:^(NSIndexPath *indexPath, NSUInteger idx, BOOL *stop) {
          CKDataSourceItem *const item = buildItem(insertedItems[indexPath]);
          insertedItemsBySection[indexPath.section][indexPath.item] = item;
          contentSize = addSizeToSize(contentSize, item.rootLayout.size());

          if (contentSizeOverflowsViewportAtTail(contentSize, _viewport.contentOffset, viewportSize, splitChangesetOptions.layoutAxis)) {
            *stop = YES;
            endIndex = idx + 1;
          }
        }];

        const CKDataSourceSplitChangesetItems splitChangesetItems = splitItemsAtIndex(endIndex, sortedIndexPaths, insertedItems);
        initialInsertedItems = splitChangesetItems.initialChangesetItems;
        deferredInsertedItems = splitChangesetItems.deferredChangesetItems;
      }
    }
  }
  if (initialInsertedItems == nil) {
    [insertedItems enumerateKeysAndObjectsUsingBlock:^(NSIndexPath *indexPath, id model, BOOL *stop) {
      insertedItemsBySection[indexPath.section][indexPath.item] = buildItem(model);
    }];
    initialInsertedItems = insertedItems;
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
#if CK_ASSERTIONS_ENABLED
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
    [[sectionsForDeferredUpdatedItems objectAtIndex:sectionIt.first] insertObjects:nullPlaceholderArray(indexes.count) atIndexes:indexes];
  }

  CKDataSourceState *newState =
  [[CKDataSourceState alloc] initWithConfiguration:configuration
                                          sections:newSections];

  CKDataSourceAppliedChanges *appliedChanges =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithArray:[initialUpdatedItems allKeys]]
                                              removedIndexPaths:[_changeset removedItems]
                                                removedSections:[_changeset removedSections]
                                                movedIndexPaths:[_changeset movedItems]
                                               insertedSections:[_changeset insertedSections]
                                             insertedIndexPaths:[NSSet setWithArray:[initialInsertedItems allKeys]]
                                                       userInfo:_userInfo];
  CKDataSourceChangeset *appliedChangeset =
  [[[[[[[[CKDataSourceChangesetBuilder dataSourceChangeset]
         withUpdatedItems:initialUpdatedItems]
        withRemovedItems:[_changeset removedItems]]
       withRemovedSections:[_changeset removedSections]]
      withMovedItems:[_changeset movedItems]]
     withInsertedSections:[_changeset insertedSections]]
    withInsertedItems:initialInsertedItems] build];

  return [[CKDataSourceChange alloc] initWithState:newState
                                     previousState:oldState
                                    appliedChanges:appliedChanges
                                  appliedChangeset:appliedChangeset
                                 deferredChangeset:createDeferredChangeset(deferredInsertedItems, computeDeferredItems(sectionsForDeferredUpdatedItems))
                         addedComponentControllers:addedComponentControllers
                       invalidComponentControllers:invalidComponentControllers];
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

static NSArray<NSNull *> *nullPlaceholderArray(NSUInteger count)
{
  NSMutableArray<NSNull *> *const array = [NSMutableArray<NSNull *> arrayWithCapacity:count];
  for (NSUInteger i = 0; i < count; i++) {
    [array addObject:[NSNull null]];
  }
  return array;
}

static CGSize computeTotalHeightOfSections(NSArray<NSArray<CKDataSourceItem *> *> *sections)
{
  CGSize contentSize = CGSizeZero;
  for (NSArray<CKDataSourceItem *> *items in sections) {
    for (CKDataSourceItem *item in items) {
      contentSize = addSizeToSize(contentSize, item.rootLayout.size());
    }
  }
  return contentSize;
}

struct CKDataSourceSplitChangesetItems {
  NSDictionary<NSIndexPath *, id> *initialChangesetItems;
  NSDictionary<NSIndexPath *, id> *deferredChangesetItems;
};

static CKDataSourceSplitChangesetItems splitItemsAtIndex(NSUInteger splitIndex, NSArray<NSIndexPath *> *indexPaths, NSDictionary<NSIndexPath *, id> *allItems)
{
  NSDictionary<NSIndexPath *, id> *initialChangesetItems = nil;
  NSDictionary<NSIndexPath *, id> *deferredChangesetItems = nil;
  if (splitIndex < indexPaths.count) {
    initialChangesetItems = dictionaryWithValuesForKeys(allItems, [indexPaths subarrayWithRange:NSMakeRange(0, splitIndex)]);
    deferredChangesetItems = dictionaryWithValuesForKeys(allItems, [indexPaths subarrayWithRange:NSMakeRange(splitIndex, indexPaths.count - splitIndex)]);
  } else {
    initialChangesetItems = allItems;
  }
  return {
    .initialChangesetItems = initialChangesetItems,
    .deferredChangesetItems = deferredChangesetItems,
  };
}

struct CKDataSourceSplitUpdateResult {
  CKDataSourceSplitChangesetItems splitItems;
  NSDictionary<NSIndexPath *, CKDataSourceItem *> *computedItems;
};

static CKDataSourceSplitUpdateResult splitUpdatedItems(NSArray<NSArray<CKDataSourceItem *> *> *sections,
                                                       NSDictionary<NSIndexPath *, id> *updatedItems,
                                                       NSMutableArray<CKComponentController *> *addedComponentControllers,
                                                       NSMutableArray<CKComponentController *> *invalidComponentControllers,
                                                       const CKSizeRange &sizeRange,
                                                       CKDataSourceConfiguration *configuration,
                                                       id<NSObject> context,
                                                       CKDataSourceChangeset *changeset,
                                                       NSDictionary *userInfo,
                                                       CKDataSourceState *oldState,
                                                       CGSize viewportSize,
                                                       CKDataSourceLayoutAxis layoutAxis,
                                                       CGPoint contentOffset)
{
  if (updatedItems.count == 0) {
    return {};
  }

  NSMutableDictionary<NSIndexPath *, CKDataSourceItem *> *const computedItems = [NSMutableDictionary<NSIndexPath *, CKDataSourceItem *> dictionary];
  NSMutableDictionary<NSIndexPath *, id> *mutableUpdatedItems = [updatedItems mutableCopy];
  NSMutableDictionary<NSIndexPath *, id> *initialUpdatedItems = [NSMutableDictionary<NSIndexPath *, id> dictionary];
  NSMutableDictionary<NSIndexPath *, id> *deferredUpdatedItems = [NSMutableDictionary<NSIndexPath *, id> dictionary];

  __block CGSize contentSize = CGSizeZero;
  [sections enumerateObjectsUsingBlock:^(NSArray<CKDataSourceItem *> *items, NSUInteger sectionIdx, BOOL *stop) {
    [items enumerateObjectsUsingBlock:^(CKDataSourceItem *item, NSUInteger itemIdx, BOOL *stop1) {
      NSIndexPath *const indexPath = [NSIndexPath indexPathForItem:itemIdx inSection:sectionIdx];
      id const updatedModel = mutableUpdatedItems[indexPath];
      [mutableUpdatedItems removeObjectForKey:indexPath];

      if (updatedModel == nil) {
        contentSize = addSizeToSize(contentSize, [item rootLayout].size());
      } else if (contentSizeOverflowsViewport(contentSize, contentOffset, viewportSize, layoutAxis)) {
        // If the item was already out of the viewport, we assume that it will still be out
        // of the viewport once the item is updated. This assumption may not hold true
        // if the update *reduces* the size of the item enough such that it now is inside
        // the viewport. In this scenario, we under-render and there is a potential performance
        // regression.
        deferredUpdatedItems[indexPath] = updatedModel;
        contentSize = addSizeToSize(contentSize, [item rootLayout].size());
      } else {
        // If the item was in the viewport before the update, we assume that the item will still
        // be in the viewport after the update. This assumption may not hold true if the update
        // *increases* the size of the item such that it is now outside the viewport. In this
        // scenario, we over-render, which is not a problem since that is not a regression over
        // the original behavior.
        CKDataSourceItem *const newItem = CKBuildDataSourceItem([item scopeRoot], {}, sizeRange, configuration, updatedModel, context);
        computedItems[indexPath] = newItem;
        initialUpdatedItems[indexPath] = updatedModel;
        contentSize = addSizeToSize(contentSize, [newItem rootLayout].size());
        for (auto componentController : addedControllersFromPreviousScopeRootMatchingPredicate(newItem.scopeRoot,
                                                                                               item.scopeRoot,
                                                                                               &CKComponentControllerInitializeEventPredicate)) {
          [addedComponentControllers addObject:componentController];
        }
        for (auto componentController : removedControllersFromPreviousScopeRootMatchingPredicate(newItem.scopeRoot,
                                                                                                 item.scopeRoot,
                                                                                                 &CKComponentControllerInvalidateEventPredicate)) {
          [invalidComponentControllers addObject:componentController];
        }
      }
    }];
  }];

  // Anything that is left has an invalid index path.
  [mutableUpdatedItems enumerateKeysAndObjectsUsingBlock:^(NSIndexPath *indexPath, id model, BOOL *stop) {
    if (indexPath.section >= sections.count) {
      CKCFatalWithCategory(CKHumanReadableInvalidChangesetOperationType(CKInvalidChangesetOperationTypeUpdate),
                           @"Invalid section: %lu (>= %lu). Changeset: %@, user info: %@, state: %@",
                           (unsigned long)indexPath.section,
                           (unsigned long)sections.count,
                           changeset,
                           userInfo,
                           oldState);
    }
    NSArray<CKDataSourceItem *> *const section = sections[indexPath.section];
    if (indexPath.item >= section.count) {
      CKCFatalWithCategory(CKHumanReadableInvalidChangesetOperationType(CKInvalidChangesetOperationTypeUpdate),
                           @"Invalid item: %lu (>= %lu). Changeset: %@, user info: %@, state: %@",
                           (unsigned long)indexPath.item,
                           (unsigned long)section.count,
                           changeset,
                           userInfo,
                           oldState);
    }
  }];

  return {
    .splitItems = {
      .initialChangesetItems = initialUpdatedItems,
      .deferredChangesetItems = deferredUpdatedItems,
    },
    .computedItems = computedItems,
  };
}

static NSDictionary *dictionaryWithValuesForKeys(NSDictionary *dictionary, NSArray<id<NSCopying>> *keys)
{
  NSMutableDictionary *const subdictionary = [NSMutableDictionary dictionaryWithCapacity:keys.count];
  for (id<NSCopying> key in keys) {
    subdictionary[key] = dictionary[key];
  }
  return subdictionary;
}

static NSDictionary<NSIndexPath *, id> *computeDeferredItems(NSArray<NSArray<id> *> *sectionsForDeferredItems)
{
  NSMutableDictionary<NSIndexPath *, id> *const deferredItems = [NSMutableDictionary<NSIndexPath *, id> new];
  [sectionsForDeferredItems enumerateObjectsUsingBlock:^(NSArray<id> *items, NSUInteger sectionIdx, BOOL *stop) {
    [items enumerateObjectsUsingBlock:^(id obj, NSUInteger itemIdx, BOOL *stop1) {
      if (obj != [NSNull null]) {
        deferredItems[[NSIndexPath indexPathForItem:itemIdx inSection:sectionIdx]] = obj;
      }
    }];
  }];
  return deferredItems;
}

static CKDataSourceChangeset *createDeferredChangeset(NSDictionary<NSIndexPath *, id> *insertedItems, NSDictionary<NSIndexPath *, id> *updatedItems)
{
  if (insertedItems.count == 0 && updatedItems.count == 0) {
    return nil;
  }
  return [[[[CKDataSourceChangesetBuilder dataSourceChangeset]
            withUpdatedItems:updatedItems]
           withInsertedItems:insertedItems]
          build];
}

static BOOL contentSizeOverflowsViewport(CGSize contentSize, CGPoint contentOffset, CGSize viewportSize, CKDataSourceLayoutAxis layoutAxis)
{
  switch (layoutAxis) {
    case CKDataSourceLayoutAxisVertical:
      return (contentSize.height < contentOffset.y) || (contentSize.height >= (contentOffset.y + viewportSize.height));
    case CKDataSourceLayoutAxisHorizontal:
      return (contentSize.width < contentOffset.x) || (contentSize.width >= (contentOffset.x + viewportSize.width));
  }
}

static BOOL contentSizeOverflowsViewportAtTail(CGSize contentSize, CGPoint contentOffset, CGSize viewportSize, CKDataSourceLayoutAxis layoutAxis)
{
  switch (layoutAxis) {
    case CKDataSourceLayoutAxisVertical:
      return contentSize.height >= (contentOffset.y + viewportSize.height);
    case CKDataSourceLayoutAxisHorizontal:
      return contentSize.width >= (contentOffset.x + viewportSize.width);
  }
}

static BOOL indexPathsAreContiguousAtTail(NSArray<NSIndexPath *> *indexPaths, NSArray<NSArray<CKDataSourceItem *> *> *sections)
{
  __block BOOL isContiguousAtTail = YES;
  [sections enumerateObjectsUsingBlock:^(NSArray<CKDataSourceItem *> *section, NSUInteger idx, BOOL *stop) {
    NSArray<NSIndexPath *> *const filteredBySection =
    [indexPaths filteredArrayUsingPredicate:
     [NSPredicate predicateWithBlock:^BOOL(NSIndexPath *indexPath, NSDictionary *bindings) {
      return [indexPath section] == idx;
    }]];
    if (!indexPathsAreContiguousAtTailForSection(filteredBySection, section, idx)) {
      isContiguousAtTail = NO;
      *stop = YES;
    }
  }];
  return isContiguousAtTail;
}

static BOOL indexPathsAreContiguousAtTailForSection(NSArray<NSIndexPath *> *indexPaths, NSArray<CKDataSourceItem *> *section, NSUInteger sectionIndex)
{
  NSUInteger expectedItemIndex = section.count;
  for (NSIndexPath *indexPath in indexPaths) {
    if ([indexPath section] != sectionIndex || [indexPath item] != expectedItemIndex) {
      return NO;
    }
    expectedItemIndex++;
  }
  return YES;
}

static CGSize addSizeToSize(CGSize existingSize, CGSize additionalSize)
{
  existingSize.width += additionalSize.width;
  existingSize.height += additionalSize.height;
  return existingSize;
}

- (CKDataSourceQOS)qos
{
  return _qos;
}

@end
