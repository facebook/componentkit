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
#import <ComponentKit/CKComponentProvider.h>
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
    return [configuration.componentProvider componentForModel:model context:configuration.context];
  });
  const auto layout = CKComponentRootLayout {[result.component layoutThatFits:configuration.sizeRange parentSize:configuration.sizeRange.max]};
  return [[CKDataSourceItem alloc] initWithRootLayout:layout model:model scopeRoot:result.scopeRoot boundsAnimation:result.boundsAnimation];
}

CKDataSourceState *CKDataSourceTestState(Class<CKComponentProvider> provider,
                                         id<CKComponentStateListener> listener,
                                         NSUInteger numberOfSections,
                                         NSUInteger numberOfItemsPerSection,
                                         BOOL parallelBuildAndLayout)
{
  CKDataSourceConfiguration *configuration =
  [[CKDataSourceConfiguration alloc]
   initWithComponentProvider:provider
   context:@"context"
   sizeRange:{{100, 100}, {100, 100}}
   buildComponentConfig:{}
   qosOptions:{}
   unifyBuildAndLayout:NO
   parallelInsertBuildAndLayout:parallelBuildAndLayout
   parallelInsertBuildAndLayoutThreshold:0
   parallelUpdateBuildAndLayout:parallelBuildAndLayout
   parallelUpdateBuildAndLayoutThreshold:0
   animationOptions:{}
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

CKDataSource *CKComponentTestDataSource(Class<CKComponentProvider> provider)
{
  CKDataSource *ds =
  [[CKDataSource alloc] initWithConfiguration:
   [[CKDataSourceConfiguration alloc] initWithComponentProvider:provider
                                                                              context:nil
                                                                            sizeRange:{}]];

  CKDataSourceChangeset *insertion =
  [[[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
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
