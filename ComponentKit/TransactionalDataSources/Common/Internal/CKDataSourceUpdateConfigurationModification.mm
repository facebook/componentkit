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
#import "CKComponentLayout.h"
#import "CKComponentProvider.h"
#import "CKComponentScopeFrame.h"
#import "CKComponentScopeRoot.h"

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
  Class<CKComponentProvider> componentProvider = [_configuration componentProvider];
  id<NSObject> context = [_configuration context];
  const CKSizeRange sizeRange = [_configuration sizeRange];

  // If only the size range changed, we don't need to regenerate the component; we can simply re-layout the existing one.
  const BOOL onlySizeRangeChanged = [_configuration context] == [[oldState configuration] context]
  && [_configuration componentProvider] == [[oldState configuration] componentProvider];

  NSMutableArray *newSections = [NSMutableArray array];
  NSMutableSet *updatedIndexPaths = [NSMutableSet set];
  [[oldState sections] enumerateObjectsUsingBlock:^(NSArray *items, NSUInteger sectionIdx, BOOL *sectionStop) {
    NSMutableArray *newItems = [NSMutableArray array];
    [items enumerateObjectsUsingBlock:^(CKDataSourceItem *item, NSUInteger itemIdx, BOOL *itemStop) {
      [updatedIndexPaths addObject:[NSIndexPath indexPathForItem:itemIdx inSection:sectionIdx]];
      CKDataSourceItem *newItem;
      if (!_configuration.unifyBuildAndLayout) {
        if (onlySizeRangeChanged) {
          const CKComponentLayout layout = CKComputeRootComponentLayout(item.layout.component, sizeRange, [item scopeRoot].analyticsListener, _configuration.componentLayoutCacheEnabled);
          newItem = [[CKDataSourceItem alloc] initWithLayout:layout
                                                       model:[item model]
                                                   scopeRoot:[item scopeRoot]
                                             boundsAnimation:[item boundsAnimation]];
        } else {
                  const CKBuildComponentResult result = CKBuildComponent([item scopeRoot], {}, ^{
          return [componentProvider componentForModel:[item model] context:context];
        }, _configuration.buildComponentTreeEnabled, _configuration.alwaysBuildComponentTreeEnabled);
        const CKComponentLayout layout = CKComputeRootComponentLayout(result.component, sizeRange, result.scopeRoot.analyticsListener, _configuration.componentLayoutCacheEnabled);
        newItem = [[CKDataSourceItem alloc] initWithLayout:layout
                                                                           model:[item model]
                                                                       scopeRoot:result.scopeRoot
                                                                 boundsAnimation:result.boundsAnimation];
        }
      } else {
        CKBuildAndLayoutComponentResult result = CKBuildAndLayoutComponent([item scopeRoot],
                                                         {},
                                                         sizeRange,
                                                         _configuration.componentLayoutCacheEnabled,
                                                         ^{
                                                           return [componentProvider componentForModel:[item model] context:context];
                                                         });

        newItem = [[CKDataSourceItem alloc] initWithLayout:result.computedLayout
                                                     model:[item model]
                                                 scopeRoot:result.buildComponentResult.scopeRoot
                                           boundsAnimation:result.buildComponentResult.boundsAnimation];
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
                                    appliedChanges:appliedChanges];
}

- (NSDictionary *)userInfo
{
  return _userInfo;
}

@end
