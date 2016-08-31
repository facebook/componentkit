/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import <ComponentKit/CKSectionedArrayController.h>

using namespace CK::ArrayController;

@interface CKSectionedArrayControllerTests : XCTestCase
@end

@implementation CKSectionedArrayControllerTests
{
  CKSectionedArrayController *_controller;
}

- (void)setUp
{
  [super setUp];
  _controller = [[CKSectionedArrayController alloc] init];
}

- (void)tearDown
{
  _controller = nil;
  [super tearDown];
}

- (void)testInitialState
{
  XCTAssertNotNil(_controller, @"");
  XCTAssertEqual([_controller numberOfSections], 0, @"");
}

- (void)testOutOfBoundsSectionAccessForNumberOfObjectsInSectionThrowsWhenEmpty
{
  XCTAssertThrowsSpecificNamed([_controller numberOfObjectsInSection:0],
                              NSException, NSRangeException, @"");
}

- (void)testOutOfBoundsSectionAccessForNumberOfObjectsInSectionThrowsWhenNotEmpty
{
  Sections sections;
  sections.insert(0);
  (void)[_controller applyChangeset:{sections, {}}];

  XCTAssertThrowsSpecificNamed([_controller numberOfObjectsInSection:1],
                              NSException, NSRangeException, @"");
}

- (void)testNumberOfObjecsInSectionThrowsWithNegativeSection
{
  XCTAssertThrowsSpecificNamed([_controller numberOfObjectsInSection:-1],
                              NSException, NSInvalidArgumentException, @"");
}

- (void)testOutOfBoundsAccessForObjectAtIndexPathThrowsWhenEmpty
{
  XCTAssertThrowsSpecificNamed([_controller objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]],
                              NSException, NSRangeException, @"");
}

/**
 This is fun, NSIndexPath is typed as taking signed integers, but actually uses unsigned internally. There's a massive
 impedance mismatch between NSArray (unsigned) NSIndexPath and UITableView (signed). This test can't ever be made to
 pass when using NSIndexPath, despite it pretending to take signed ints.
 */
//- (void)testObjectAtIndexPathThrowsWithNegativeIndexPath
//{
//  XCTAssertThrowsSpecificNamed([_controller objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:-1]],
//                              NSException, NSInvalidArgumentException, @"");
//  XCTAssertThrowsSpecificNamed([_controller objectAtIndexPath:[NSIndexPath indexPathForItem:-1 inSection:0]],
//                              NSException, NSInvalidArgumentException, @"");
//}

- (void)testOutOfBoundsSectionAccessForObjectAtIndexPathThrowsWhenNotEmpty
{
  Sections sections;
  sections.insert(0);
  (void)[_controller applyChangeset:{sections, {}}];

  XCTAssertThrowsSpecificNamed([_controller objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:1]],
                              NSException, NSRangeException, @"");
}

- (void)testObjectAtIndexPathThrowsWithNilIndexPath
{
  XCTAssertThrowsSpecificNamed([_controller objectAtIndexPath:nil],
                              NSException, NSInvalidArgumentException, @"");
}

- (void)testOutOfBoundsInsertionOfObjectsThrowsWhenEmpty
{
  Input::Items items;
  items.insert({0, 0}, @0);

  Input::Changeset changeset = {{}, items};
  XCTAssertThrows([_controller applyChangeset:changeset]);
}

- (void)testOutOfBoundsInsertionOfObjectsThrowsWhenNotEmpty
{
  Sections sections;
  sections.insert(0);
  (void)[_controller applyChangeset:{sections, {}}];

  Input::Items items;
  items.insert({1, 0}, @0);

  Input::Changeset changeset = {{}, items};
  XCTAssertThrows([_controller applyChangeset:changeset]);
}

@end

@interface CKSectionedArrayControllerInsertionTests : XCTestCase
@end

@implementation CKSectionedArrayControllerInsertionTests
{
  CKSectionedArrayController *_controller;
}

- (void)setUp
{
  [super setUp];
  _controller = [[CKSectionedArrayController alloc] init];
}

- (void)tearDown
{
  _controller = nil;
  [super tearDown];
}

- (void)testInsertionOfSingleSection
{
  Sections sections;
  sections.insert(0);

  auto output = [_controller applyChangeset:{sections, {}}];

  XCTAssertEqual([_controller numberOfSections], 1, @"");
  XCTAssertEqual([_controller numberOfObjectsInSection:0], 0, @"");

  Sections expectedSections;
  expectedSections.insert(0);
  Output::Changeset expected = {expectedSections, {}};

  XCTAssertTrue(output == expected, @"");
}

- (void)testInsertionOfObject
{
  Sections sections;
  sections.insert(0);
  Input::Items items;
  items.insert({0, 0}, @0);

  auto output = [_controller applyChangeset:{sections, items}];

  XCTAssertEqual([_controller numberOfSections], 1, @"");
  XCTAssertEqual([_controller numberOfObjectsInSection:0], 1, @"");

  Sections expectedSections;
  expectedSections.insert(0);
  Output::Items expectedItems;
  expectedItems.insert({0, 0}, @0);
  Output::Changeset expected = {expectedSections, expectedItems};

  XCTAssertTrue(output == expected, @"");
}

- (void)testInsertionOfMultipleSections
{
  Sections sections;
  sections.insert(0);
  sections.insert(1);
  sections.insert(2);

  auto output = [_controller applyChangeset:{sections, {}}];

  XCTAssertEqual([_controller numberOfSections], 3, @"");

  Sections expectedSections;
  expectedSections.insert(0);
  expectedSections.insert(1);
  expectedSections.insert(2);
  Output::Changeset expected = {expectedSections, {}};

  XCTAssertTrue(output == expected, @"");
}

- (void)testInsertionOfMultipleObjectsInDifferentSections
{
  Sections sections;
  sections.insert(0);
  sections.insert(1);
  sections.insert(2);

  Input::Items items;
  items.insert({1, 0}, @0);
  items.insert({1, 1}, @1);
  items.insert({2, 0}, @2);
  items.insert({2, 1}, @3);

  auto output = [_controller applyChangeset:{sections, items}];

  XCTAssertEqual([_controller numberOfSections], 3, @"");
  XCTAssertEqual([_controller numberOfObjectsInSection:0], 0, @"");
  XCTAssertEqual([_controller numberOfObjectsInSection:1], 2, @"");
  XCTAssertEqual([_controller numberOfObjectsInSection:2], 2, @"");

  Sections expectedSections;
  expectedSections.insert(0);
  expectedSections.insert(1);
  expectedSections.insert(2);
  Output::Items expectedItems;
  expectedItems.insert({1, 0}, @0);
  expectedItems.insert({1, 1}, @1);
  expectedItems.insert({2, 0}, @2);
  expectedItems.insert({2, 1}, @3);
  Output::Changeset expected = {expectedSections, expectedItems};

  XCTAssertTrue(output == expected, @"");
}

@end

@interface CKSectionedArrayControllerRemovalTests : XCTestCase
@end

@implementation CKSectionedArrayControllerRemovalTests
{
  CKSectionedArrayController *_controller;
}

- (void)setUp
{
  [super setUp];
  _controller = [[CKSectionedArrayController alloc] init];

  Sections sections;
  sections.insert(0);

  Input::Items items;
  items.insert({0, 0}, @0);

  (void)[_controller applyChangeset:{sections, items}];
}

- (void)tearDown
{
  _controller = nil;
  [super tearDown];
}

- (void)testRemovalOfSingleSection
{
  Sections sections;
  sections.remove(0);

  auto output = [_controller applyChangeset:{sections, {}}];

  XCTAssertEqual([_controller numberOfSections], 0, @"");

  Sections expectedSections;
  expectedSections.remove(0);
  Output::Changeset expected = {expectedSections, {}};

  XCTAssertTrue(output == expected, @"");
}

- (void)testRemovalOfObject
{
  Input::Items items;
  items.remove({0, 0});

  auto output = [_controller applyChangeset:{{}, items}];

  XCTAssertEqual([_controller numberOfSections], 1, @"");
  XCTAssertEqual([_controller numberOfObjectsInSection:0], 0, @"");

  Output::Items expectedItems;
  expectedItems.remove({0, 0}, @0);
  Output::Changeset expected = {{}, expectedItems};

  XCTAssertTrue(output == expected, @"");
}

- (void)testRemovalOfMultipleSections
{
  { // Add some more sections (see -setUp)
    Sections sections;
    sections.insert(0);
    sections.insert(1);
    sections.insert(2);
    (void)[_controller applyChangeset:{sections, {}}];
  }

  Sections sections;
  sections.remove(0);
  sections.remove(1);
  sections.remove(2);

  auto output = [_controller applyChangeset:{sections, {}}];

  XCTAssertEqual([_controller numberOfSections], 1, @"");

  Sections expectedSections;
  expectedSections.remove(0);
  expectedSections.remove(1);
  expectedSections.remove(2);
  Output::Changeset expected = {expectedSections, {}};

  XCTAssertTrue(output == expected, @"");
}

- (void)testRemovalOfMultipleObjectsInDifferentSections
{
  { // Add more sections/items so we can delete a subset of them.
    Sections sections;
    sections.insert(1);
    sections.insert(2);

    Input::Items items;
    items.insert({1, 0}, @0);
    items.insert({1, 1}, @1);
    items.insert({1, 2}, @2);
    items.insert({2, 0}, @3);
    items.insert({2, 1}, @4);
    items.insert({2, 2}, @5);

    (void)[_controller applyChangeset:{sections, items}];
  }

  Input::Items items;
  items.remove({1, 1});
  items.remove({1, 2});
  items.remove({2, 0});
  items.remove({2, 1});
  items.remove({2, 2});

  auto output = [_controller applyChangeset:{{}, items}];

  XCTAssertEqual([_controller numberOfSections], 3, @"");
  XCTAssertEqual([_controller numberOfObjectsInSection:0], 1, @"");
  XCTAssertEqual([_controller numberOfObjectsInSection:1], 1, @"");
  XCTAssertEqual([_controller numberOfObjectsInSection:2], 0, @"");

  Output::Items expectedItems;
  expectedItems.remove({1, 1}, @1);
  expectedItems.remove({1, 2}, @2);
  expectedItems.remove({2, 0}, @3);
  expectedItems.remove({2, 1}, @4);
  expectedItems.remove({2, 2}, @5);
  Output::Changeset expected = {{}, expectedItems};

  XCTAssertTrue(output == expected, @"");
}

@end

@interface CKSectionedArrayControllerUpdateTests : XCTestCase
@end

@implementation CKSectionedArrayControllerUpdateTests
{
  CKSectionedArrayController *_controller;
}

- (void)setUp
{
  [super setUp];
  _controller = [[CKSectionedArrayController alloc] init];

  Sections sections;
  sections.insert(0);

  Input::Items items;
  items.insert({0, 0}, @0);

  (void)[_controller applyChangeset:{sections, items}];
}

- (void)tearDown
{
  _controller = nil;
  [super tearDown];
}


- (void)testUpdateOfObject
{
  Input::Items items;
  items.update({0, 0}, @1);

  auto output = [_controller applyChangeset:{{}, items}];

  XCTAssertEqual([_controller numberOfSections], 1, @"");
  XCTAssertEqual([_controller numberOfObjectsInSection:0], 1, @"");

  Output::Items expectedItems;
  expectedItems.update({0, 0}, @0, @1);
  Output::Changeset expected = {{}, expectedItems};

  XCTAssertTrue(output == expected, @"");
}

@end

@interface CKSectionedArrayControllerMoveTests : XCTestCase
@end

@implementation CKSectionedArrayControllerMoveTests
{
  CKSectionedArrayController *_controller;
}

- (void)setUp
{
  [super setUp];
  _controller = [[CKSectionedArrayController alloc] init];

  Sections sections;
  sections.insert(0);
  sections.insert(1);

  Input::Items items;
  items.insert({0, 0}, @0);
  items.insert({0, 1}, @1);

  (void)[_controller applyChangeset:{sections, items}];
}

- (void)tearDown
{
  _controller = nil;
  [super tearDown];
}

- (void)testMoveOfSection
{
  Sections sections;
  sections.move(0, 1);

  auto output = [_controller applyChangeset:{sections, {}}];

  XCTAssertEqual([_controller numberOfObjectsInSection:0], 0, @"");
  XCTAssertEqual([_controller numberOfObjectsInSection:1], 2, @"");

  Sections expectedSections;
  expectedSections.move(0, 1);
  Output::Changeset expected = {expectedSections, {}};

  XCTAssertTrue(output == expected, @"");
}

- (void)testMoveOfItem
{
  Input::Items items;
  items.move({0, 0}, {0, 1});

  auto output = [_controller applyChangeset:{{}, items}];

  XCTAssertEqual([_controller numberOfObjectsInSection:0], 2, @"");
  XCTAssertEqual([_controller objectAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]], @0, @"");

  Output::Items expectedItems;
  expectedItems.move({0, 0}, {0, 1}, @0);
  Output::Changeset expected = {{}, expectedItems};

  XCTAssertTrue(output == expected, @"");
}

@end

@interface CKSectionedArrayControllerEnumerationTest : XCTestCase
@end

@implementation CKSectionedArrayControllerEnumerationTest
{
  CKSectionedArrayController *_controller;
}

- (void)setUp
{
  [super setUp];
  _controller = [[CKSectionedArrayController alloc] init];
}

- (void)tearDown
{
  _controller = nil;
  [super tearDown];
}

- (void)testSingleSectionEnumerationWhenEmptyThrows
{
  XCTAssertThrowsSpecificNamed([_controller enumerateObjectsInSectionAtIndex:0
                                                          usingBlock:^(id<NSObject> object, NSIndexPath *indexPath, BOOL *stop) {}],
                              NSException, NSRangeException, @"");
}

NS_INLINE Input::Changeset _singleSectionInput(void)
{
  Sections sections;
  sections.insert(0);
  Input::Items items;
  items.insert({0, 0}, @0);
  items.insert({0, 1}, @1);
  return {sections, items};
}

- (void)testSingleSectionEnumerationWithSingleSection
{
  [_controller applyChangeset:_singleSectionInput()];

  typedef std::vector<std::pair<IndexPath, id<NSObject>>> Enumerated;

  __block Enumerated enumerated;
  [_controller enumerateObjectsInSectionAtIndex:0 usingBlock:^(id<NSObject> object, NSIndexPath *indexPath, BOOL *stop) {
    enumerated.push_back({{[indexPath section], [indexPath item]}, object});
  }];

  Enumerated expected;
  expected.push_back({{0, 0}, @0});
  expected.push_back({{0, 1}, @1});

  XCTAssertTrue(enumerated == expected, @"");
}

- (void)testSingleSectionEnumerationStop
{
  [_controller applyChangeset:_singleSectionInput()];

  typedef std::vector<std::pair<IndexPath, id<NSObject>>> Enumerated;

  __block Enumerated enumerated;
  [_controller enumerateObjectsInSectionAtIndex:0 usingBlock:^(id<NSObject> object, NSIndexPath *indexPath, BOOL *stop) {
    enumerated.push_back({{[indexPath section], [indexPath item]}, object});
    *stop = YES;
  }];

  Enumerated expected;
  expected.push_back({{0, 0}, @0});

  XCTAssertTrue(enumerated == expected, @"");
}

NS_INLINE Input::Changeset _multipleSectionInput(void)
{
  Sections sections;
  sections.insert(0);
  sections.insert(1);
  Input::Items items;
  items.insert({0, 0}, @0);
  items.insert({0, 1}, @1);
  items.insert({1, 0}, @2);
  items.insert({1, 1}, @3);
  return {sections, items};
}

- (void)testSingleSectionEnumerationWithMultipleSections
{
  [_controller applyChangeset:_multipleSectionInput()];

  typedef std::vector<std::pair<IndexPath, id<NSObject>>> Enumerated;

  __block Enumerated enumerated;
  [_controller enumerateObjectsInSectionAtIndex:1 usingBlock:^(id<NSObject> object, NSIndexPath *indexPath, BOOL *stop) {
    enumerated.push_back({{[indexPath section], [indexPath item]}, object});
  }];

  Enumerated expected;
  expected.push_back({{1, 0}, @2});
  expected.push_back({{1, 1}, @3});

  XCTAssertTrue(enumerated == expected, @"");
}

- (void)testFullEnumerationWithMultipleSections
{
  [_controller applyChangeset:_multipleSectionInput()];

  typedef std::vector<std::pair<IndexPath, id<NSObject>>> Enumerated;

  __block Enumerated enumerated;
  [_controller enumerateObjectsUsingBlock:^(id<NSObject> object, NSIndexPath *indexPath, BOOL *stop) {
    enumerated.push_back({{[indexPath section], [indexPath item]}, object});
  }];

  Enumerated expected;
  expected.push_back({{0, 0}, @0});
  expected.push_back({{0, 1}, @1});
  expected.push_back({{1, 0}, @2});
  expected.push_back({{1, 1}, @3});

  XCTAssertTrue(enumerated == expected, @"");
}

- (void)testFullEnumerationStop
{
  [_controller applyChangeset:_multipleSectionInput()];

  typedef std::vector<std::pair<IndexPath, id<NSObject>>> Enumerated;

  __block Enumerated enumerated;
  [_controller enumerateObjectsUsingBlock:^(id<NSObject> object, NSIndexPath *indexPath, BOOL *stop) {
    enumerated.push_back({{[indexPath section], [indexPath item]}, object});
    if ([indexPath section] == 1) {
      *stop = YES;
    }
  }];

  Enumerated expected;
  expected.push_back({{0, 0}, @0});
  expected.push_back({{0, 1}, @1});
  expected.push_back({{1, 0}, @2});

  XCTAssertTrue(enumerated == expected, @"");
}

@end
