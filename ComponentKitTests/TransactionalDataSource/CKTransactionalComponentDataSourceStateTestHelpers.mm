/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKTransactionalComponentDataSourceStateTestHelpers.h"

#import "CKTransactionalComponentDataSourceConfiguration.h"
#import "CKComponentProvider.h"
#import "CKComponentLayout.h"
#import "CKComponentScopeRoot.h"
#import "CKComponentSubclass.h"
#import "CKTransactionalComponentDataSourceItemInternal.h"
#import "CKTransactionalComponentDataSourceStateInternal.h"

static CKTransactionalComponentDataSourceItem *item(CKTransactionalComponentDataSourceConfiguration *configuration, id model)
{
  const CKBuildComponentResult result = CKBuildComponent(nil, {}, ^CKComponent *{
    return [configuration.componentProvider componentForModel:model context:configuration.context];
  });
  const CKComponentLayout layout = [result.component layoutThatFits:configuration.sizeRange parentSize:configuration.sizeRange.max];
  return [[CKTransactionalComponentDataSourceItem alloc] initWithLayout:layout model:model scopeRoot:result.scopeRoot];
}

CKTransactionalComponentDataSourceState *CKTransactionalComponentDataSourceTestState(Class<CKComponentProvider> provider,
                                                                                     NSUInteger numberOfSections,
                                                                                     NSUInteger numberOfItemsPerSection)
{
  CKTransactionalComponentDataSourceConfiguration *configuration =
  [[CKTransactionalComponentDataSourceConfiguration alloc] initWithComponentProvider:provider
                                                                             context:@"context"
                                                                           sizeRange:{{100, 100}, {100, 100}}];

  NSMutableArray *sections = [NSMutableArray array];
  for (NSUInteger sectionIndex = 0; sectionIndex < numberOfSections; sectionIndex++) {
    NSMutableArray *items = [NSMutableArray array];
    for (NSUInteger itemIndex = 0; itemIndex < numberOfItemsPerSection; itemIndex++) {
      [items addObject:item(configuration, @(sectionIndex * numberOfItemsPerSection + itemIndex))];
    }
    [sections addObject:items];
  }

  return [[CKTransactionalComponentDataSourceState alloc] initWithConfiguration:configuration sections:sections];
}
