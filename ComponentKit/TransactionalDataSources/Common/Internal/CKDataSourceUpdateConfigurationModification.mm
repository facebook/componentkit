/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKDataSourceUpdateConfigurationModification.h"

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

@implementation CKDataSourceUpdateConfigurationModification
{
  CKDataSourceConfiguration *_configuration;
  NSDictionary *_userInfo;
}

- (instancetype)initWithConfiguration:(CKDataSourceConfiguration *)configuration
                             userInfo:(NSDictionary *)userInfo
{
  if (self = [super init]) {
    _configuration = configuration;
    _userInfo = [userInfo copy];
  }
  return self;
}

- (CKDataSourceChange *)changeFromState:(CKDataSourceState *)oldState
{
  id<NSObject> context = [_configuration context];
  const CKSizeRange sizeRange = [_configuration sizeRange];

  // If only the size range changed, we don't need to regenerate the component; we can simply re-layout the existing one.
  const BOOL onlySizeRangeChanged = [_configuration hasSameComponentProviderAndContextAs:oldState.configuration];

  NSMutableArray *newSections = [NSMutableArray array];
  NSMutableSet *updatedIndexPaths = [NSMutableSet set];
  NSMutableArray<CKComponentController *> *addedComponentControllers = [NSMutableArray array];
  NSMutableArray<CKComponentController *> *invalidComponentControllers = [NSMutableArray array];
  [[oldState sections] enumerateObjectsUsingBlock:^(NSArray *items, NSUInteger sectionIdx, BOOL *sectionStop) {
    NSMutableArray *newItems = [NSMutableArray array];
    [items enumerateObjectsUsingBlock:^(CKDataSourceItem *item, NSUInteger itemIdx, BOOL *itemStop) {
      [updatedIndexPaths addObject:[NSIndexPath indexPathForItem:itemIdx inSection:sectionIdx]];
      CKDataSourceItem *newItem;
      if (onlySizeRangeChanged) {
        const auto rootLayout = CKComputeRootComponentLayout(item.rootLayout.component(), sizeRange, [item scopeRoot].analyticsListener);
        newItem = [[CKDataSourceItem alloc] initWithRootLayout:rootLayout
                                                         model:[item model]
                                                     scopeRoot:[item scopeRoot]
                                               boundsAnimation:[item boundsAnimation]];
      } else {
        newItem = CKBuildDataSourceItem([item scopeRoot], {}, sizeRange, _configuration, [item model], context);
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
      [newItems addObject:newItem];
    }];
    [newSections addObject:newItems];
  }];

  CKDataSourceState *newState =
  [[CKDataSourceState alloc] initWithConfiguration:_configuration
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
