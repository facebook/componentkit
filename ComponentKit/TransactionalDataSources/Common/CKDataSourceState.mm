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

#import <ComponentKit/CKEqualityHelpers.h>
#import <ComponentKit/CKFunctionalHelpers.h>
#import <ComponentKit/CKMacros.h>

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

- (NSString *)contentsFingerprint
{
  __block auto itemTypes = std::vector<NSString *>{};
  [self enumerateObjectsUsingBlock:^(CKDataSourceItem *item, NSIndexPath *, BOOL *) {
    id const model = item.model;
    if ([model respondsToSelector:@selector(model)] && [model respondsToSelector:@selector(context)]) {
      itemTypes.push_back(NSStringFromClass([[model model] class]));
      itemTypes.push_back(NSStringFromClass([[model context] class]));
    } else {
      itemTypes.push_back(NSStringFromClass([model class]));
    }
  }];
  return fingerprintFromItemTypes(itemTypes);
}

static auto fingerprintFromItemTypes(const std::vector<NSString *> &types) -> NSString *
{
  auto const uniqueTypes = [NSMutableArray<NSString *> arrayWithCapacity:types.size()];
  for (auto const &t : types) {
    auto const typeOrNil = t ?: @"Nil";
    if (![uniqueTypes containsObject:typeOrNil]) {
      [uniqueTypes addObject:typeOrNil];
    }
  }
  if ([uniqueTypes count] == 0) {
    return @"";
  }
  auto const hashes = CK::map(uniqueTypes, [](NSString *t) { return [t hash]; });
  auto const hash = CKIntegerArrayHash(hashes.data(), hashes.size());
  return [NSString stringWithFormat:@"%lu", static_cast<unsigned long>(hash)];
}

@end
