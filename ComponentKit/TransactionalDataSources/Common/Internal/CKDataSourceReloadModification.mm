/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKDataSourceReloadModification.h"

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
#import "CKComponentScopeRoot.h"
#import "CKDataSourceModificationHelper.h"

using namespace CKComponentControllerHelper;

@implementation CKDataSourceReloadModification
{
  NSDictionary *_userInfo;
}

- (instancetype)initWithUserInfo:(NSDictionary *)userInfo
{
  if (self = [super init]) {
    _userInfo = [userInfo copy];
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
  [[oldState sections] enumerateObjectsUsingBlock:^(NSArray *items, NSUInteger sectionIdx, BOOL *sectionStop) {
    NSMutableArray *newItems = [NSMutableArray array];
    [items enumerateObjectsUsingBlock:^(CKDataSourceItem *item, NSUInteger itemIdx, BOOL *itemStop) {
      [updatedIndexPaths addObject:[NSIndexPath indexPathForItem:itemIdx inSection:sectionIdx]];
      // On reload, we would like avoid component reuse - by passing `enableComponentReuseOptimizations = NO`, we make sure that all the components will be recreated.
      CKDataSourceItem *const newItem = CKBuildDataSourceItem([item scopeRoot], {}, sizeRange, configuration, [item model], context, NO);
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
                                                       userInfo:_userInfo];

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
  return _userInfo;
}

- (CKDataSourceQOS)qos
{
  return CKDataSourceQOSDefault;
}

@end
