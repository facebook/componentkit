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

#import <ComponentKit/CKExceptionInfo.h>

#import "CKDataSourceConfigurationInternal.h"
#import "CKDataSourceStateInternal.h"
#import "CKDataSourceChange.h"
#import "CKDataSourceChangesetInternal.h"
#import "CKDataSourceItemInternal.h"
#import "CKDataSourceAppliedChanges.h"
#import "CKBuildComponent.h"
#import "CKComponentControllerEvents.h"
#import "CKComponentControllerHelper.h"
#import "CKComponentEvents.h"
#import "CKComponentLayout.h"
#import "CKComponentProvider.h"
#import "CKComponentScopeRoot.h"
#import "CKComponentScopeRootFactory.h"
#import "CKDataSourceModificationHelper.h"
#import "CKIndexSetDescription.h"
#import "CKInvalidChangesetOperationType.h"
#import "CKFatal.h"

using namespace CKComponentControllerHelper;

@implementation CKDataSourceChangesetModification
{
  __weak id<CKComponentStateListener> _stateListener;
  NSDictionary *_userInfo;
  CKDataSourceQOS _qos;
  __weak id<CKDataSourceChangesetModificationItemGenerator> _itemGenerator;
}

- (instancetype)initWithChangeset:(CKDataSourceChangeset *)changeset
                    stateListener:(id<CKComponentStateListener>)stateListener
                         userInfo:(NSDictionary *)userInfo
                              qos:(CKDataSourceQOS)qos
{
  if (self = [super init]) {
    _changeset = changeset;
    _stateListener = stateListener;
    _userInfo = [userInfo copy];
    _qos = qos;
  }
  return self;
}

- (void)setItemGenerator:(id<CKDataSourceChangesetModificationItemGenerator>)itemGenerator
{
  _itemGenerator = itemGenerator;
}

- (CKDataSourceChange *)changeFromState:(CKDataSourceState *)oldState
{
  @try {
    return [self __changeFromState:oldState];
  } @catch (NSException *exception) {
    CKExceptionInfoSetValueForKey(@"ck_changeset", _changeset.description);
    CKExceptionInfoSetValueForKey(@"ck_changeset_origin", _changeset.originName);
    CKExceptionInfoSetValueForKey(@"ck_user_info", _userInfo.description);
    CKExceptionInfoSetValueForKey(@"ck_data_source_state", oldState.description);
    CKExceptionInfoSetValueForKey(
      @"assert_message",
      ([NSString stringWithFormat:@"<force_category:%@:force_category> Raised an exception applying modification",
       oldState.contentsFingerprint])
    );
    [exception raise];
  } @catch (...) {
    CKExceptionInfoSetValueForKey(@"ck_changeset", _changeset.description);
    CKExceptionInfoSetValueForKey(@"ck_changeset_origin", _changeset.originName);
    CKExceptionInfoSetValueForKey(@"ck_user_info", _userInfo.description);
    CKExceptionInfoSetValueForKey(@"ck_data_source_state", oldState.description);
    CKExceptionInfoSetValueForKey(
      @"assert_message",
      ([NSString stringWithFormat:@"<force_category:%@:force_category> Raised an unknown c++ exception applying modification",
       oldState.contentsFingerprint])
    );
    throw;
  }
}

- (CKDataSourceChange *)__changeFromState:(CKDataSourceState *)oldState
{
  CKDataSourceConfiguration *configuration = [oldState configuration];
  id<NSObject> context = [configuration context];
  const CKSizeRange sizeRange = [configuration sizeRange];

  NSMutableArray<CKComponentController *> *addedComponentControllers = [NSMutableArray array];
  NSMutableArray<CKComponentController *> *invalidComponentControllers = [NSMutableArray array];

  const auto newSections = [NSMutableArray<NSMutableArray *> array];
  [[oldState sections] enumerateObjectsUsingBlock:^(NSArray *items, NSUInteger sectionIdx, BOOL *sectionStop) {
    [newSections addObject:[items mutableCopy]];
  }];

  // Update items
  NSDictionary<NSIndexPath *, id> *const updatedItems = [_changeset updatedItems];
  void(^processUpdatedItem)(NSIndexPath *indexPath, id model) = ^(NSIndexPath *indexPath, id model) {
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
    CKDataSourceItem *const item = [self _buildDataSourceItemForPreviousRoot:[oldItem scopeRoot]
                                                                stateUpdates:{}
                                                                   sizeRange:sizeRange
                                                               configuration:configuration
                                                                       model:model
                                                                     context:context
                                                                    itemType:CKDataSourceChangesetModificationItemTypeUpdate];
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
  };
  [updatedItems enumerateKeysAndObjectsUsingBlock:^(NSIndexPath *indexPath, id model, BOOL *stop) {
    processUpdatedItem(indexPath, model);
  }];

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
    NSMutableArray *sectionItems = nil;
    @try {
      sectionItems = newSections[it.first];
    } @catch (NSException *exception) {
      CKExceptionInfoSetValueForKey(@"ck_changeset_operation", CKHumanReadableInvalidChangesetOperationType(CKInvalidChangesetOperationTypeRemoveRow));

      [exception raise];
    }

    @try {
      [sectionItems removeObjectsAtIndexes:it.second];
    } @catch (NSException *exception) {
      CKExceptionInfoSetValueForKey(@"ck_changeset_operation", CKHumanReadableInvalidChangesetOperationType(CKInvalidChangesetOperationTypeRemoveRow));
      CKExceptionInfoSetValueForKey(@"ck_invalid_indexes", CK::indexSetDescription(CK::invalidIndexesForRemovalFromArray(sectionItems, it.second), @"", 0));
      CKExceptionInfoSetValueForKey(@"ck_section", ([NSString stringWithFormat:@"%lu", (unsigned long)it.first]));

      [exception raise];
    }
  }

  // Remove sections
  NSIndexSet *const removedSections = [_changeset removedSections];
  if ([removedSections count] > 0) {
    [newSections removeObjectsAtIndexes:removedSections];
  }

  // Insert sections
  @try {
    [newSections insertObjects:emptyMutableArrays([[_changeset insertedSections] count]) atIndexes:[_changeset insertedSections]];
  } @catch (NSException *exception) {
    CKExceptionInfoSetValueForKey(@"ck_changeset_operation", CKHumanReadableInvalidChangesetOperationType(CKInvalidChangesetOperationTypeInsertSection));
    CKExceptionInfoSetValueForKey(@"ck_invalid_indexes", CK::indexSetDescription(CK::invalidIndexesForInsertionInArray(newSections, [_changeset insertedSections]), @"", 0));

    [exception raise];
  }

  // Insert items
  const auto buildItem = ^CKDataSourceItem *(id model) {
    return [self _buildDataSourceItemForPreviousRoot:CKComponentScopeRootWithPredicates(_stateListener,
                                                                                        configuration.analyticsListener,
                                                                                        configuration.componentPredicates,
                                                                                        configuration.componentControllerPredicates)
                                        stateUpdates:{}
                                           sizeRange:sizeRange
                                       configuration:configuration
                                               model:model
                                             context:context
                                            itemType:CKDataSourceChangesetModificationItemTypeInsert];
  };

  NSDictionary<NSIndexPath *, id> *const insertedItems = [_changeset insertedItems];
  [insertedItems enumerateKeysAndObjectsUsingBlock:^(NSIndexPath *indexPath, id model, BOOL *stop) {
    insertedItemsBySection[indexPath.section][indexPath.item] = buildItem(model);
  }];

  for (const auto &sectionIt : insertedItemsBySection) {
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    NSMutableArray *items = [NSMutableArray array];
    // Note this enumeration is ordered by virtue of std::map, which is crucial (we need items to match indexes):
    for (const auto &itemIt : sectionIt.second) {
      [indexes addIndex:itemIt.first];
      [items addObject:itemIt.second];
    }

    NSMutableArray *sectionItems = nil;
    @try {
      sectionItems = [newSections objectAtIndex:sectionIt.first];
    } @catch (NSException *exception) {
      CKExceptionInfoSetValueForKey(@"ck_changeset_operation", CKHumanReadableInvalidChangesetOperationType(CKInvalidChangesetOperationTypeInsertRow));

      [exception raise];
    }

    @try {
      [sectionItems insertObjects:items atIndexes:indexes];
    } @catch (NSException *exception) {
      CKExceptionInfoSetValueForKey(@"ck_changeset_operation", CKHumanReadableInvalidChangesetOperationType(CKInvalidChangesetOperationTypeInsertRow));
      CKExceptionInfoSetValueForKey(@"ck_invalid_indexes", CK::indexSetDescription(CK::invalidIndexesForInsertionInArray(sectionItems, indexes), @"", 0));
      CKExceptionInfoSetValueForKey(@"ck_section", ([NSString stringWithFormat:@"%lu", (unsigned long)sectionIt.first]));

      [exception raise];
    }
  }

  CKDataSourceState *newState =
  [[CKDataSourceState alloc] initWithConfiguration:configuration
                                          sections:newSections];

  CKDataSourceAppliedChanges *appliedChanges =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithArray:[updatedItems allKeys]]
                                              removedIndexPaths:[_changeset removedItems]
                                                removedSections:[_changeset removedSections]
                                                movedIndexPaths:[_changeset movedItems]
                                               insertedSections:[_changeset insertedSections]
                                             insertedIndexPaths:[NSSet setWithArray:[insertedItems allKeys]]
                                                       userInfo:_userInfo];

  return [[CKDataSourceChange alloc] initWithState:newState
                                     previousState:oldState
                                    appliedChanges:appliedChanges
                                  appliedChangeset:_changeset
                                 deferredChangeset:nil
                         addedComponentControllers:addedComponentControllers
                       invalidComponentControllers:invalidComponentControllers];
}

- (CKDataSourceItem *)_buildDataSourceItemForPreviousRoot:(CK::NonNull<CKComponentScopeRoot *>)previousRoot
                                             stateUpdates:(const CKComponentStateUpdateMap &)stateUpdates
                                                sizeRange:(const CKSizeRange &)sizeRange
                                            configuration:(CKDataSourceConfiguration *)configuration
                                                    model:(id)model
                                                  context:(id)context
                                                 itemType:(CKDataSourceChangesetModificationItemType)itemType
{
  if (_itemGenerator) {
    return [_itemGenerator buildDataSourceItemForPreviousRoot:previousRoot
                                                 stateUpdates:stateUpdates
                                                    sizeRange:sizeRange
                                                configuration:configuration
                                                        model:model
                                                      context:context
                                                     itemType:itemType];
  } else {
    return CKBuildDataSourceItem(previousRoot, stateUpdates, sizeRange, configuration, model, context);
  }
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

- (CKDataSourceQOS)qos
{
  return _qos;
}

@end

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
