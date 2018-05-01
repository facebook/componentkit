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
#import "CKComponentLayout.h"
#import "CKComponentProvider.h"
#import "CKComponentScopeFrame.h"
#import "CKComponentScopeRoot.h"

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
  Class<CKComponentProvider> componentProvider = [configuration componentProvider];
  id<NSObject> context = [configuration context];
  const CKSizeRange sizeRange = [configuration sizeRange];

  NSMutableArray *newSections = [NSMutableArray array];
  NSMutableSet *updatedIndexPaths = [NSMutableSet set];
  [[oldState sections] enumerateObjectsUsingBlock:^(NSArray *items, NSUInteger sectionIdx, BOOL *sectionStop) {
    NSMutableArray *newItems = [NSMutableArray array];
    [items enumerateObjectsUsingBlock:^(CKDataSourceItem *item, NSUInteger itemIdx, BOOL *itemStop) {
      [updatedIndexPaths addObject:[NSIndexPath indexPathForItem:itemIdx inSection:sectionIdx]];
      if (!configuration.unifyBuildAndLayout) {
        const CKBuildComponentResult result = CKBuildComponent([item scopeRoot], {}, ^{
          return [componentProvider componentForModel:[item model] context:context];
        }, configuration.buildComponentTree, configuration.alwaysBuildComponentTree, configuration.forceParent);
        const CKComponentLayout layout = CKComputeRootComponentLayout(result.component, sizeRange, result.scopeRoot.analyticsListener);
        [newItems addObject:[[CKDataSourceItem alloc] initWithLayout:layout
                                                               model:[item model]
                                                           scopeRoot:result.scopeRoot
                                                     boundsAnimation:result.boundsAnimation]];
      } else {
        CKBuildAndLayoutComponentResult result = CKBuildAndLayoutComponent([item scopeRoot],
                                                                           {},
                                                                           sizeRange,
                                                                           ^{
                                                                             return [componentProvider componentForModel:[item model] context:context];
                                                                           },
                                                                           configuration.forceParent);
        [newItems addObject:[[CKDataSourceItem alloc] initWithLayout:result.computedLayout
                                                               model:[item model]
                                                           scopeRoot:result.buildComponentResult.scopeRoot
                                                     boundsAnimation:result.buildComponentResult.boundsAnimation]];
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
                                    appliedChanges:appliedChanges];
}

- (NSDictionary *)userInfo
{
  return _userInfo;
}

@end
