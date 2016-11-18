/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKTransactionalComponentDataSourceReloadModification.h"

#import "CKTransactionalComponentDataSourceConfiguration.h"
#import "CKTransactionalComponentDataSourceStateInternal.h"
#import "CKTransactionalComponentDataSourceChange.h"
#import "CKTransactionalComponentDataSourceItemInternal.h"
#import "CKTransactionalComponentDataSourceAppliedChanges.h"
#import "CKComponentLayout.h"
#import "CKComponentProvider.h"
#import "CKComponentScopeFrame.h"
#import "CKComponentScopeRoot.h"

@implementation CKTransactionalComponentDataSourceReloadModification
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

- (CKTransactionalComponentDataSourceChange *)changeFromState:(CKTransactionalComponentDataSourceState *)oldState
{
  CKTransactionalComponentDataSourceConfiguration *configuration = [oldState configuration];
  Class<CKComponentProvider> componentProvider = [configuration componentProvider];
  id<NSObject> context = [configuration context];
  const CKSizeRange sizeRange = [configuration sizeRange];

  NSMutableArray *newSections = [NSMutableArray array];
  NSMutableSet *updatedIndexPaths = [NSMutableSet set];
  [[oldState sections] enumerateObjectsUsingBlock:^(NSArray *items, NSUInteger sectionIdx, BOOL *sectionStop) {
    NSMutableArray *newItems = [NSMutableArray array];
    [items enumerateObjectsUsingBlock:^(CKTransactionalComponentDataSourceItem *item, NSUInteger itemIdx, BOOL *itemStop) {
      [updatedIndexPaths addObject:[NSIndexPath indexPathForItem:itemIdx inSection:sectionIdx]];
      const CKBuildComponentResult result = CKBuildComponent([item scopeRoot], {}, ^{
        return [componentProvider componentForModel:[item model] context:context];
      });
      const CKComponentLayout layout = CKComputeRootComponentLayout(result.component, sizeRange);
      [newItems addObject:[[CKTransactionalComponentDataSourceItem alloc] initWithLayout:layout
                                                                                   model:[item model]
                                                                               scopeRoot:result.scopeRoot]];
    }];
    [newSections addObject:newItems];
  }];

  CKTransactionalComponentDataSourceState *newState =
  [[CKTransactionalComponentDataSourceState alloc] initWithConfiguration:configuration
                                                                sections:newSections];

  CKTransactionalComponentDataSourceAppliedChanges *appliedChanges =
  [[CKTransactionalComponentDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:updatedIndexPaths
                                                                    removedIndexPaths:nil
                                                                      removedSections:nil
                                                                      movedIndexPaths:nil
                                                                     insertedSections:nil
                                                                   insertedIndexPaths:nil
                                                                             userInfo:_userInfo];

  return [[CKTransactionalComponentDataSourceChange alloc] initWithState:newState
                                                          appliedChanges:appliedChanges];
}

@end
