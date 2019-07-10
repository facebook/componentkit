/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <XCTest/XCTest.h>

#import <UIKit/UIKit.h>

#import <ComponentKit/CKDataSourceChangesetInternal.h>
#import <ComponentKitTestHelpers/CKChangesetHelpers.h>

@interface CKDataSourceChangesetTests : XCTestCase
@end

@implementation CKDataSourceChangesetTests

- (void)testChangesetEquality
{
  CKDataSourceChangeset *firstChangeset =
  [[CKDataSourceChangeset alloc] initWithUpdatedItems:@{[NSIndexPath indexPathForItem:0 inSection:0] : @"A"}
                                                               removedItems:[NSSet setWithObject:[NSIndexPath indexPathForItem:1 inSection:0]]
                                                            removedSections:[NSIndexSet indexSetWithIndex:2]
                                                                 movedItems:@{[NSIndexPath indexPathForItem:2 inSection:0] : [NSIndexPath indexPathForItem:3 inSection:0]}
                                                           insertedSections:[NSIndexSet indexSetWithIndex:1]
                                                              insertedItems:@{[NSIndexPath indexPathForItem:0 inSection:1] : @"B"}];
  CKDataSourceChangeset *secondChangeset =
  [[CKDataSourceChangeset alloc] initWithUpdatedItems:@{[NSIndexPath indexPathForItem:0 inSection:0] : @"A"}
                                                               removedItems:[NSSet setWithObject:[NSIndexPath indexPathForItem:1 inSection:0]]
                                                            removedSections:[NSIndexSet indexSetWithIndex:2]
                                                                 movedItems:@{[NSIndexPath indexPathForItem:2 inSection:0] : [NSIndexPath indexPathForItem:3 inSection:0]}
                                                           insertedSections:[NSIndexSet indexSetWithIndex:1]
                                                              insertedItems:@{[NSIndexPath indexPathForItem:0 inSection:1] : @"B"}];
  XCTAssertEqualObjects(firstChangeset, secondChangeset);
}

- (void)testChangesetsNotEqual
{
  CKDataSourceChangeset *firstChangeset =
  [[CKDataSourceChangeset alloc] initWithUpdatedItems:@{[NSIndexPath indexPathForItem:0 inSection:0] : @"A"}
                                                               removedItems:[NSSet setWithObject:[NSIndexPath indexPathForItem:1 inSection:0]]
                                                            removedSections:[NSIndexSet indexSetWithIndex:2]
                                                                 movedItems:@{[NSIndexPath indexPathForItem:2 inSection:0] : [NSIndexPath indexPathForItem:3 inSection:0]}
                                                           insertedSections:[NSIndexSet indexSetWithIndex:1]
                                                              insertedItems:@{[NSIndexPath indexPathForItem:0 inSection:1] : @"B"}];
  CKDataSourceChangeset *secondChangeset =
  [[CKDataSourceChangeset alloc] initWithUpdatedItems:@{[NSIndexPath indexPathForItem:0 inSection:0] : @"A"}
                                                               removedItems:[NSSet setWithObject:[NSIndexPath indexPathForItem:1 inSection:0]]
                                                            removedSections:[NSIndexSet indexSetWithIndex:2]
                                                                 movedItems:@{[NSIndexPath indexPathForItem:2 inSection:0] : [NSIndexPath indexPathForItem:3 inSection:0]}
                                                           insertedSections:[NSIndexSet indexSetWithIndex:1]
                                                              insertedItems:@{[NSIndexPath indexPathForItem:0 inSection:1] : @"C"}];
  XCTAssertNotEqualObjects(firstChangeset, secondChangeset);
}

- (void)testChangesetIsEmpty
{
  XCTAssertTrue([[CKDataSourceChangesetBuilder dataSourceChangeset] build].isEmpty);

  XCTAssertFalse([[[CKDataSourceChangesetBuilder dataSourceChangeset]
                   withInsertedItems:@{[NSIndexPath indexPathForItem:0 inSection:0] : @"A"}] build].isEmpty);
  XCTAssertFalse([[[CKDataSourceChangesetBuilder dataSourceChangeset]
                   withRemovedItems:[NSSet setWithObject:[NSIndexPath indexPathForItem:1 inSection:0]]] build].isEmpty);
  XCTAssertFalse([[[CKDataSourceChangesetBuilder dataSourceChangeset]
                   withRemovedSections:[NSIndexSet indexSetWithIndex:2]] build].isEmpty);
  XCTAssertFalse([[[CKDataSourceChangesetBuilder dataSourceChangeset]
                   withUpdatedItems:@{[NSIndexPath indexPathForItem:2 inSection:0] : [NSIndexPath indexPathForItem:3 inSection:0]}] build].isEmpty);
  XCTAssertFalse([[[CKDataSourceChangesetBuilder dataSourceChangeset]
                   withInsertedSections:[NSIndexSet indexSetWithIndex:1]] build].isEmpty);
  XCTAssertFalse([[[CKDataSourceChangesetBuilder dataSourceChangeset]
                   withInsertedItems:@{[NSIndexPath indexPathForItem:0 inSection:1] : @"C"}] build].isEmpty);
}

@end

@interface CKDataSourceChangesetTests_Description: XCTestCase
@end

@implementation CKDataSourceChangesetTests_Description

- (void)test_WhenChangesetIsEmpty_DescriptionIsEmpty
{
  const auto cs = CK::makeChangeset({});

  XCTAssertEqualObjects(CK::changesetDescription(cs), @"");
}

- (void)test_WhenChangesetHasSectionChanges_IncludesThemInDescription
{
  const auto cs = CK::makeChangeset({
    .removedSections = {0, 1},
    .insertedSections = {0},
  });

  const auto expectedDescription =
  @"\
{\n\
  Removed Sections: 0–1\n\
  Inserted Sections: 0\n\
}";
  XCTAssertEqualObjects(CK::changesetDescription(cs), expectedDescription);
}

- (void)test_WhenChangesetIncludesOnlyOneTypeOfSectionChange_IncludesOnlyItInDescription
{
  const auto cs = CK::makeChangeset({
    .removedSections = {0, 1},
  });

  const auto expectedDescription =
  @"\
{\n\
  Removed Sections: 0–1\n\
}";
  XCTAssertEqualObjects(CK::changesetDescription(cs), expectedDescription);
}

- (void)test_WhenChangesetHasRemovedItems_IncludesThemInDescriptionSorted
{
  const auto cs = CK::makeChangeset({
    .removedItems = {{1, 1}, {0, 2}},
  });

  const auto expectedDescription =
  @"\
{\n\
  Removed Items: {\n\
    (0-2),\n\
    (1-1)\n\
  }\n\
}";
  XCTAssertEqualObjects(CK::changesetDescription(cs), expectedDescription);
}

- (void)test_WhenChangesetHasUpdatedItems_IncludesThemInDescriptionSorted
{
  const auto cs = CK::makeChangeset({
    .updatedItems = {
      {{1, 1}, @"A"},
      {{0, 2}, @"B"},
    },
  });

  const auto expectedDescription =
  @"\
{\n\
  Updated Items: {\n\
    (0-2): B,\n\
    (1-1): A\n\
  }\n\
}";
  XCTAssertEqualObjects(CK::changesetDescription(cs), expectedDescription);
}

- (void)test_WhenChangesetHasInsertedItems_IncludesThemInDescriptionSorted
{
  const auto cs = CK::makeChangeset({
    .insertedItems = {
      {{1, 1}, @"A"},
      {{0, 2}, @"B"},
    },
  });

  const auto expectedDescription =
  @"\
{\n\
  Inserted Items: {\n\
    (0-2): B,\n\
    (1-1): A\n\
  }\n\
}";
  XCTAssertEqualObjects(CK::changesetDescription(cs), expectedDescription);
}

- (void)test_WhenChangesetHasMovedItems_IncludesThemInDescriptionSortedByFromIndexPath
{
  const auto cs = CK::makeChangeset({
    .movedItems = {
      {{1, 1}, {1, 2}},
      {{0, 2}, {0, 0}},
    },
  });

  const auto expectedDescription =
  @"\
{\n\
  Moved Items: {\n\
    (0-2) → (0-0),\n\
    (1-1) → (1-2)\n\
  }\n\
}";
  XCTAssertEqualObjects(CK::changesetDescription(cs), expectedDescription);
}

@end
