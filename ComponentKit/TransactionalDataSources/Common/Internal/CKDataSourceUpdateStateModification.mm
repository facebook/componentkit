/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKDataSourceUpdateStateModification.h"

#import "CKDataSourceConfiguration.h"
#import "CKDataSourceConfigurationInternal.h"
#import "CKDataSourceStateInternal.h"
#import "CKDataSourceChange.h"
#import "CKDataSourceItemInternal.h"
#import "CKDataSourceAppliedChanges.h"
#import "CKBuildComponent.h"
#import "CKComponentControllerEvents.h"
#import "CKComponentControllerHelper.h"
#import "CKComponentLayout.h"
#import "CKComponentProvider.h"
#import "CKComponentScopeFrame.h"
#import "CKComponentScopeHandle.h"
#import "CKComponentScopeRoot.h"
#import "CKDataSourceModificationHelper.h"

using namespace CKComponentControllerHelper;

@implementation CKDataSourceUpdateStateModification
{
  CKComponentStateUpdatesMap _stateUpdates;
}

- (instancetype)initWithStateUpdates:(const CKComponentStateUpdatesMap &)stateUpdates
{
  if (self = [super init]) {
    _stateUpdates = stateUpdates;
  }
  return self;
}

- (CKDataSourceChange *)changeFromState:(CKDataSourceState *)oldState
{
  CKDataSourceConfiguration *configuration = [oldState configuration];
  id<NSObject> context = [configuration context];
  const CKSizeRange sizeRange = [configuration sizeRange];

  NSMutableArray *newSections = [NSMutableArray array];
  NSMutableSet *updatedIndexPaths = [NSMutableSet set];
  NSMutableArray<CKComponentController *> *addedComponentControllers = [NSMutableArray array];
  NSMutableArray<CKComponentController *> *invalidComponentControllers = [NSMutableArray array];
  __block CKComponentScopeRootIdentifier globalIdentifier = 0;
  [[oldState sections] enumerateObjectsUsingBlock:^(NSArray *items, NSUInteger sectionIdx, BOOL *sectionStop) {
    NSMutableArray *newItems = [NSMutableArray array];
    [items enumerateObjectsUsingBlock:^(CKDataSourceItem *item, NSUInteger itemIdx, BOOL *itemStop) {
      const auto stateUpdatesForItem = _stateUpdates.find([[item scopeRoot] globalIdentifier]);
      if (stateUpdatesForItem == _stateUpdates.end()) {
        [newItems addObject:item];
      } else {
        const auto stateUpdateMap = stateUpdatesForItem->second;
        const auto stateUpdate = stateUpdateMap.begin();
        if (stateUpdate != stateUpdateMap.end()) {
          globalIdentifier = stateUpdate->first.globalIdentifier;
        }
        [updatedIndexPaths addObject:[NSIndexPath indexPathForItem:itemIdx inSection:sectionIdx]];
        CKDataSourceItem *const newItem = CKBuildDataSourceItem([item scopeRoot], stateUpdatesForItem->second, sizeRange, configuration, [item model], context);
        [newItems addObject:newItem];
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
    [newSections addObject:newItems];
  }];

  CKDataSourceState *newState =
  [[CKDataSourceState alloc] initWithConfiguration:configuration
                                          sections:newSections];

  CKDataSourceAppliedChanges *appliedChanges =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:updatedIndexPaths
                                              removedIndexPaths:nil
                                                removedSections:nil
                                                movedIndexPaths:nil
                                               insertedSections:nil
                                             insertedIndexPaths:nil
                                                       userInfo:@{@"updatedComponentIdentifier":@(globalIdentifier)}];

  return [[CKDataSourceChange alloc] initWithState:newState
                                     previousState:oldState
                                    appliedChanges:appliedChanges
                                  appliedChangeset:nil
                                 deferredChangeset:nil
                         addedComponentControllers:addedComponentControllers
                       invalidComponentControllers:invalidComponentControllers];
}

- (NSDictionary *)userInfo
{
  return nil;
}

- (CKDataSourceQOS)qos
{
  return CKDataSourceQOSDefault;
}

@end
