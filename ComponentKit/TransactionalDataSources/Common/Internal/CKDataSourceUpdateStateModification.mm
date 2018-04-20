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
#import "CKComponentLayout.h"
#import "CKComponentProvider.h"
#import "CKComponentScopeFrame.h"
#import "CKComponentScopeHandle.h"
#import "CKComponentScopeRoot.h"

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
  Class<CKComponentProvider> componentProvider = [configuration componentProvider];
  id<NSObject> context = [configuration context];
  const CKSizeRange sizeRange = [configuration sizeRange];

  NSMutableArray *newSections = [NSMutableArray array];
  NSMutableSet *updatedIndexPaths = [NSMutableSet set];
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
        if (!configuration.unifyBuildAndLayout) {
          const CKBuildComponentResult result = CKBuildComponent([item scopeRoot], stateUpdatesForItem->second, ^{
            return [componentProvider componentForModel:[item model] context:context];
          }, configuration.buildComponentTreeEnabled, configuration.alwaysBuildComponentTreeEnabled);
          const CKComponentLayout layout = CKComputeRootComponentLayout(result.component, sizeRange, result.scopeRoot.analyticsListener);
          [newItems addObject:[[CKDataSourceItem alloc] initWithLayout:layout
                                                                 model:[item model]
                                                             scopeRoot:result.scopeRoot
                                                       boundsAnimation:result.boundsAnimation]];
        } else {
          CKBuildAndLayoutComponentResult result = CKBuildAndLayoutComponent([item scopeRoot],
                                                           stateUpdatesForItem->second,
                                                           sizeRange,
                                                           ^{
                                                             return [componentProvider componentForModel:[item model] context:context];
                                                           });
          [newItems addObject:[[CKDataSourceItem alloc] initWithLayout:result.computedLayout
                                                                 model:[item model]
                                                             scopeRoot:result.buildComponentResult.scopeRoot
                                                       boundsAnimation:result.buildComponentResult.boundsAnimation]];
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
                                    appliedChanges:appliedChanges];
}

- (NSDictionary *)userInfo
{
  return nil;
}

@end
