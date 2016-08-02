/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKTransactionalComponentDataSourceUpdateConfigurationModification.h"

#import "CKTransactionalComponentDataSourceConfiguration.h"
#import "CKTransactionalComponentDataSourceStateInternal.h"
#import "CKTransactionalComponentDataSourceChange.h"
#import "CKTransactionalComponentDataSourceItemInternal.h"
#import "CKTransactionalComponentDataSourceAppliedChanges.h"
#import "CKComponentLayout.h"
#import "CKComponentProvider.h"
#import "CKComponentScopeFrame.h"
#import "CKComponentScopeRoot.h"

@implementation CKTransactionalComponentDataSourceUpdateConfigurationModification
{
  CKTransactionalComponentDataSourceConfiguration *_configuration;
  NSDictionary *_userInfo;
}

- (instancetype)initWithConfiguration:(CKTransactionalComponentDataSourceConfiguration *)configuration
                             userInfo:(NSDictionary *)userInfo
{
  if (self = [super init]) {
    _configuration = configuration;
    _userInfo = [userInfo copy];
  }
  return self;
}

- (CKTransactionalComponentDataSourceChange *)changeFromState:(CKTransactionalComponentDataSourceState *)oldState
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
    [items enumerateObjectsUsingBlock:^(CKTransactionalComponentDataSourceItem *item, NSUInteger itemIdx, BOOL *itemStop) {
      [updatedIndexPaths addObject:[NSIndexPath indexPathForItem:itemIdx inSection:sectionIdx]];

      CKTransactionalComponentDataSourceItem *newItem;
      if (onlySizeRangeChanged) {
        const CKComponentLayout layout = CKComputeRootComponentLayout(item.layout.component, sizeRange);
        newItem = [[CKTransactionalComponentDataSourceItem alloc] initWithLayout:layout
                                                                           model:[item model]
                                                                       scopeRoot:[item scopeRoot]];
      } else {
        const CKBuildComponentResult result = CKBuildComponent([item scopeRoot], {}, ^{
          return [componentProvider componentForModel:[item model] context:context];
        });
        const CKComponentLayout layout = CKComputeRootComponentLayout(result.component, sizeRange);
        newItem = [[CKTransactionalComponentDataSourceItem alloc] initWithLayout:layout
                                                                           model:[item model]
                                                                       scopeRoot:result.scopeRoot];
      }

      [newItems addObject:newItem];
    }];
    [newSections addObject:newItems];
  }];

  CKTransactionalComponentDataSourceState *newState =
  [[CKTransactionalComponentDataSourceState alloc] initWithConfiguration:_configuration
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
