/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKSectionedArrayController.h>

#import <ComponentKit/CKPlatform.h>

#import <ComponentKit/CKArgumentPrecondition.h>

using namespace CK::ArrayController;

@implementation CKSectionedArrayController
{
  NSMutableArray *_sections;
}

- (instancetype)init
{
  if (self = [super init]) {
    _sections = [NSMutableArray array];
  }
  return self;
}

#pragma mark -

- (NSString *)description
{
  const NSInteger numberOfSections = [self numberOfSections];
  NSMutableString *sectionSummaries = [[NSMutableString alloc] init];
  for (NSInteger section = 0; section < numberOfSections; ++section) {
    [sectionSummaries appendFormat:@"{section:%zd, objects:%tu}", section, [self numberOfObjectsInSection:section]];
    if (section != (numberOfSections - 1)) {
      [sectionSummaries appendFormat:@"\n"];
    }
  }
  return [NSString stringWithFormat:@"<%@: %p; summary = %@; contents = %@>",
          [self class],
          self,
          [NSString stringWithFormat:@"sections:%zd, %@", numberOfSections, sectionSummaries],
          _sections];
}

- (NSInteger)numberOfSections
{
  return (NSInteger)[_sections count];
}

- (NSInteger)numberOfObjectsInSection:(NSInteger)section
{
  CKArgumentPreconditionCheckIf(section >= 0, @"");
  return (NSInteger)[_sections[(NSUInteger)section] count];
}

- (id<NSObject>)objectAtIndexPath:(NSIndexPath *)indexPath
{
  CKArgumentPreconditionCheckIf(indexPath != nil, @"");
  return (id<NSObject>)_sections[(NSUInteger)[indexPath section]][(NSUInteger)[indexPath item]];
}

typedef void (^SectionEnumerator)(NSInteger sectionIndex, NSArray *section, CKSectionedArrayControllerEnumerator enumerator, BOOL *stop);

NS_INLINE SectionEnumerator _sectionEnumeratorBlock(void)
{
  return ^(NSInteger sectionIndex, NSArray *section, CKSectionedArrayControllerEnumerator enumerator, BOOL *stop) {
    NSInteger i = 0;
    for (id<NSObject> object in section) {
      const NSUInteger indexes[] = {(NSUInteger)sectionIndex, (NSUInteger)i++};
      NSIndexPath *indexPath = [[NSIndexPath alloc] initWithIndexes:indexes length:CK_ARRAY_COUNT(indexes)];
      enumerator(object, indexPath, stop);
      if (stop) {
        if (*stop) { break; }
      }
    }
  };
}

- (void)enumerateObjectsUsingBlock:(CKSectionedArrayControllerEnumerator)enumerator
{
  if (enumerator) {
    NSInteger s = 0;
    BOOL stop = NO;
    for (NSMutableArray *section in _sections) {
      _sectionEnumeratorBlock()(s, section, enumerator, &stop);
      if (stop) { break; }
      s++;
    }
  }
}

- (void)enumerateObjectsInSectionAtIndex:(NSInteger)sectionIndex usingBlock:(CKSectionedArrayControllerEnumerator)enumerator
{
  if (enumerator) {
    BOOL stop = NO;
    _sectionEnumeratorBlock()(sectionIndex, _sections[(NSUInteger)sectionIndex], enumerator, &stop);
  }
}

- (std::pair<id<NSObject>, NSIndexPath *>)firstObjectPassingTest:(CKSectionedArrayControllerPredicate)predicate
{
  __block id<NSObject> object;
  __block NSIndexPath *indexPath;
  if (predicate) {
    [self enumerateObjectsUsingBlock:^(id<NSObject> o, NSIndexPath *iP, BOOL *stop) {
      if (predicate(o, iP, stop)) {
        object = o;
        indexPath = iP;
        *stop = YES;
      }
    }];
  }
  return {object, indexPath};
}

NS_INLINE NSArray *_createEmptySections(NSUInteger count)
{
  NSMutableArray *emptySections = [[NSMutableArray alloc] init];
  for (NSUInteger i = 0 ; i < count ; ++i) {
    [emptySections addObject:[[NSMutableArray alloc] init]];
  }
  return emptySections;
}

- (CKArrayControllerOutputChangeset)applyChangeset:(CKArrayControllerInputChangeset)changeset
{
  Sections outputSections;
  __block Output::Items outputItems;

  // we have to process changes in this specific order (which is how TV/CV will execute them)

  { // 1. item updates
    changeset.items.enumerateItems(^(NSInteger section, NSInteger index, id<NSObject> object, BOOL *stop) {
      outputItems.update(
        {section, index},
        _sections[section][index],
        object
      );
      [_sections[section] replaceObjectAtIndex:index withObject:object];
    }, nil, nil);
  }

  { // 2. item removals
    __block std::map<NSInteger, NSMutableIndexSet *> removedItemIndexesBucketizedBySection;
    changeset.items.enumerateItems(nil, ^(NSInteger section, NSInteger index, BOOL *stop) {
      outputItems.remove(
        {section, index},
        _sections[section][index]
      );
      if (!removedItemIndexesBucketizedBySection.count(section)) {
        removedItemIndexesBucketizedBySection[section] = [NSMutableIndexSet indexSet];
      }
      [removedItemIndexesBucketizedBySection[section] addIndex:index];
    }, nil);

    for (const auto &removalsInSection : removedItemIndexesBucketizedBySection) {
      [_sections[removalsInSection.first] removeObjectsAtIndexes:removalsInSection.second];
    }
  }

  { // 3. section removals
    NSMutableIndexSet *sectionRemovalIndexes = [NSMutableIndexSet indexSet];
    for (NSInteger removal : changeset.sections.removals()) {
      outputSections.remove(removal);
      [sectionRemovalIndexes addIndex:removal];
    }
    [_sections removeObjectsAtIndexes:sectionRemovalIndexes];
  }

  { // 4. section insertions
    const std::set<NSInteger> &insertions = changeset.sections.insertions();
    NSMutableIndexSet *sectionInsertionIndexes = [NSMutableIndexSet indexSet];
    for (NSInteger insertion : insertions) {
      outputSections.insert(insertion);
      [sectionInsertionIndexes addIndex:insertion];
    }

    NSArray *emptySections = _createEmptySections(insertions.size());
    [_sections insertObjects:emptySections atIndexes:sectionInsertionIndexes];
  }

  { // 5. item insertions
    __block std::map<NSInteger, std::pair<NSMutableIndexSet *, NSMutableArray *>> insertedObjectBucketizedBySection;
    changeset.items.enumerateItems(nil, nil, ^(NSInteger section, NSInteger index, id<NSObject> object, BOOL *stop) {
      outputItems.insert(
        {section, index},
        object
      );
      if (!insertedObjectBucketizedBySection.count(section)) {
        insertedObjectBucketizedBySection[section] = std::make_pair([NSMutableIndexSet indexSet], [NSMutableArray array]);
      }
      [insertedObjectBucketizedBySection[section].first addIndex:index];
      [insertedObjectBucketizedBySection[section].second addObject:object];
    });

    for (const auto &insertionsInSection : insertedObjectBucketizedBySection) {
      [_sections[insertionsInSection.first] insertObjects:insertionsInSection.second.second atIndexes:insertionsInSection.second.first];
    }
  }

  return {outputSections, outputItems};
}

@end
