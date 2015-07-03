/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKTransactionalComponentDataSourceState.h"
#import "CKTransactionalComponentDataSourceStateInternal.h"

#import <UIKit/UIKit.h>

@implementation CKTransactionalComponentDataSourceState

- (instancetype)initWithConfiguration:(CKTransactionalComponentDataSourceConfiguration *)configuration
                             sections:(NSArray *)sections
{
  if (self = [super init]) {
    _configuration = configuration;
    _sections = [[NSArray alloc] initWithArray:sections copyItems:YES]; // Deep copy for safety
  }
  return self;
}

- (NSInteger)numberOfSections
{
  return [_sections count];
}

- (NSInteger)numberOfObjectsInSection:(NSInteger)section
{
  return [[_sections objectAtIndex:section] count];
}

- (CKTransactionalComponentDataSourceItem *)objectAtIndexPath:(NSIndexPath *)indexPath
{
  return [[_sections objectAtIndex:[indexPath section]] objectAtIndex:[indexPath item]];
}

- (void)enumerateObjectsUsingBlock:(CKTransactionalComponentDataSourceEnumerator)block
{
  if (block) {
    [_sections enumerateObjectsUsingBlock:^(NSArray *items, NSUInteger sectionIdx, BOOL *sectionStop) {
      [items enumerateObjectsUsingBlock:^(id obj, NSUInteger itemIdx, BOOL *itemStop) {
        block(obj, [NSIndexPath indexPathForItem:itemIdx inSection:sectionIdx], itemStop);
        *sectionStop = *itemStop;
      }];
    }];
  }
}

- (void)enumerateObjectsInSectionAtIndex:(NSInteger)section usingBlock:(CKTransactionalComponentDataSourceEnumerator)block
{
  if (block) {
    [[_sections objectAtIndex:section] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      block(obj, [NSIndexPath indexPathForItem:idx inSection:section], stop);
    }];
  }
}

@end
