/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKDataSourceStateTestHelpers.h"

#import <ComponentKit/CKBuildComponent.h>
#import <ComponentKit/CKDataSourceConfiguration.h>
#import <ComponentKit/CKComponentLayout.h>
#import <ComponentKit/CKComponentScopeRoot.h>
#import <ComponentKit/CKComponentScopeRootFactory.h>
#import <ComponentKit/CKComponentSubclass.h>
#import <ComponentKit/CKDataSource.h>
#import <ComponentKit/CKDataSourceChangeset.h>
#import <ComponentKit/CKDataSourceConfigurationInternal.h>
#import <ComponentKit/CKDataSourceItemInternal.h>
#import <ComponentKit/CKDataSourceStateInternal.h>

static CKDataSourceItem *item(CKDataSourceConfiguration *configuration, id<CKComponentStateListener> listener, id model)
{
  const CKBuildComponentResult result = CKBuildComponent(CKComponentScopeRootWithDefaultPredicates(listener, nil), {}, ^CKComponent *{
    return configuration.componentProvider(model, configuration.context);
  });
  const auto layout = CKComponentRootLayout {[result.component layoutThatFits:configuration.sizeRange parentSize:configuration.sizeRange.max]};
  return [[CKDataSourceItem alloc] initWithRootLayout:layout model:model scopeRoot:result.scopeRoot boundsAnimation:result.boundsAnimation];
}

CKDataSourceState *CKDataSourceTestState(CKComponentProviderFunc provider,
                                         id<CKComponentStateListener> listener,
                                         NSUInteger numberOfSections,
                                         NSUInteger numberOfItemsPerSection)
{
  CKDataSourceConfiguration *configuration =
  [[CKDataSourceConfiguration alloc]
   initWithComponentProviderFunc:provider
   context:@"context"
   sizeRange:{{100, 100}, {100, 100}}
   options:{}
   componentPredicates:{}
   componentControllerPredicates:{}
   analyticsListener:nil];

  NSMutableArray *sections = [NSMutableArray array];
  for (NSUInteger sectionIndex = 0; sectionIndex < numberOfSections; sectionIndex++) {
    NSMutableArray *items = [NSMutableArray array];
    for (NSUInteger itemIndex = 0; itemIndex < numberOfItemsPerSection; itemIndex++) {
      [items addObject:item(configuration, listener, @(sectionIndex * numberOfItemsPerSection + itemIndex))];
    }
    [sections addObject:items];
  }

  return [[CKDataSourceState alloc] initWithConfiguration:configuration sections:sections];
}

CKDataSource *CKComponentTestDataSource(CKComponentProviderFunc provider,
                                        id<CKDataSourceListener> listener,
                                        CKDataSourceOptions options)
{
  const auto configuration =
  [[CKDataSourceConfiguration alloc]
   initWithComponentProviderFunc:provider
   context:nil
   sizeRange:{}
   options:options
   componentPredicates:{}
   componentControllerPredicates:{}
   analyticsListener:nil];
  const auto ds = [[CKDataSource alloc] initWithConfiguration:configuration];
  [ds addListener:listener];

  CKDataSourceChangeset *insertion =
  [[[[CKDataSourceChangesetBuilder dataSourceChangeset]
     withInsertedSections:[NSIndexSet indexSetWithIndex:0]]
    withInsertedItems:@{[NSIndexPath indexPathForItem:0 inSection:0]: @1}]
   build];
  [ds applyChangeset:insertion mode:CKUpdateModeSynchronous userInfo:nil];
  return ds;
}

NSSet *CKTestIndexPaths(NSUInteger numberOfSections, NSUInteger numberOfItemsPerSection)
{
  NSMutableSet *ips = [NSMutableSet set];
  for (NSUInteger i = 0; i < numberOfSections; i++) {
    for (NSUInteger j = 0; j < numberOfItemsPerSection; j++) {
      [ips addObject:[NSIndexPath indexPathForItem:j inSection:i]];
    }
  }
  return ips;
}
