/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKDataSourceStateInternal.h"

#import "CKEqualityHashHelpers.h"
#import "CKMacros.h"
#import "CKDataSourceConfiguration.h"
#import "CKDataSourceItem.h"

@implementation CKDataSourceState

- (instancetype)initWithConfiguration:(CKDataSourceConfiguration *)configuration
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
  // This is done to mimic UICollectionView behavior, which returns 0 objects even if there are 0 sections
  return ([self numberOfSections] == 0 ? 0 : [[_sections objectAtIndex:section] count]);
}

- (CKDataSourceItem *)objectAtIndexPath:(NSIndexPath *)indexPath
{
  return [[_sections objectAtIndex:[indexPath section]] objectAtIndex:[indexPath item]];
}

- (void)enumerateObjectsUsingBlock:(CKDataSourceEnumerator)block
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

- (void)enumerateObjectsInSectionAtIndex:(NSInteger)section usingBlock:(CKDataSourceEnumerator)block
{
  if (block) {
    [[_sections objectAtIndex:section] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      block(obj, [NSIndexPath indexPathForItem:idx inSection:section], stop);
    }];
  }
}

#pragma mark - NSObject methods

- (NSString *)description
{
  if (self.numberOfSections == 0) { return @"{}"; }

  const auto itemStrs = static_cast<NSMutableArray<NSString *> *>([NSMutableArray new]);
  [self enumerateObjectsUsingBlock:^(CKDataSourceItem *item, NSIndexPath *ip, BOOL *) {
    const auto itemStr = [NSString stringWithFormat:@"  (%ld, %ld): %@", (long)ip.section, (long)ip.item, item.model];
    [itemStrs addObject:itemStr];
  }];
  return [NSString stringWithFormat:@"{\n%@\n}", [itemStrs componentsJoinedByString:@",\n"]];;
}

- (BOOL)isEqual:(id)object
{
  if (![object isKindOfClass:[CKDataSourceState class]]) {
    return NO;
  } else {
    CKDataSourceState *obj = ((CKDataSourceState *)object);
    return [_configuration isEqual:obj.configuration] && [flattenedModelsFromSections(_sections) isEqualToArray:flattenedModelsFromSections(obj.sections)];
  }
}

- (NSUInteger)hash
{
  NSUInteger hashes[2] = {
    [_configuration hash],
    [_sections hash]
  };
  return CKIntegerArrayHash(hashes, CK_ARRAY_COUNT(hashes));
}

static NSArray *flattenedModelsFromSections(NSArray *sections)
{
  NSMutableArray *modelSections = [NSMutableArray new];
  for (NSArray *section in sections) {
    NSMutableArray *modelSection = [NSMutableArray new];
    for (CKDataSourceItem *item in section) {
      [modelSection addObject:item.model];
    }
    [modelSections addObject:modelSection];
  }
  return modelSections;
}

@end
