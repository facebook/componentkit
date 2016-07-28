/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <Foundation/Foundation.h>

#import <XCTest/XCTest.h>

#import <ComponentKit/CKArrayControllerChangesetVerification.h>

@interface CKArrayControllerChangesetVerificationTests : XCTestCase
@end

@implementation CKArrayControllerChangesetVerificationTests

#pragma mark - Valid changesets

- (void)test_emptyChangesetEmptySections
{
  CKBadChangesetOperationType result = CKIsValidChangesetForSections(CKArrayControllerInputChangeset(CKArrayControllerSections()), @[]);
  XCTAssertEqual(result, CKBadChangesetOperationTypeNone);
}

- (void)test_emptyChangesetNonEmptySections
{
  CKBadChangesetOperationType result = CKIsValidChangesetForSections(CKArrayControllerInputChangeset(CKArrayControllerSections()), @[@[@"A", @"B"], @[@"C", @"D"]]);
  XCTAssertEqual(result, CKBadChangesetOperationTypeNone);
}

- (void)test_nonEmptyChangesetEmptySections
{
  CKArrayControllerSections sections;
  sections.insert(0);
  CKArrayControllerInputItems items;
  items.insert({0,0}, @"A");
  items.insert({0,1}, @"B");
  CKArrayControllerInputChangeset changeset = {sections, items};

  CKBadChangesetOperationType result = CKIsValidChangesetForSections(changeset, @[]);
  XCTAssertEqual(result, CKBadChangesetOperationTypeNone);
}

- (void)test_validInsertionIntoEmptySection
{
  CKArrayControllerInputItems items;
  items.insert({0,0}, @"A");
  items.insert({0,1}, @"B");
  CKArrayControllerInputChangeset changeset = {items};

  CKBadChangesetOperationType result = CKIsValidChangesetForSections(changeset, @[@[]]);
  XCTAssertEqual(result, CKBadChangesetOperationTypeNone);
}

- (void)test_validInsertionIntoBeginningOfNonEmptySection
{
  CKArrayControllerInputItems items;
  items.insert({0,0}, @"A");
  items.insert({0,1}, @"B");
  CKArrayControllerInputChangeset changeset = {items};

  CKBadChangesetOperationType result = CKIsValidChangesetForSections(changeset, @[@[@"C", @"D"]]);
  XCTAssertEqual(result, CKBadChangesetOperationTypeNone);
}

- (void)test_validInsertionIntoMiddleOfNonEmptySection
{
  CKArrayControllerInputItems items;
  items.insert({0,1}, @"A");
  items.insert({0,2}, @"B");
  CKArrayControllerInputChangeset changeset = {items};

  CKBadChangesetOperationType result = CKIsValidChangesetForSections(changeset, @[@[@"C", @"D"]]);
  XCTAssertEqual(result, CKBadChangesetOperationTypeNone);
}

- (void)test_validInsertionAtEndOfNonEmptySection
{
  CKArrayControllerInputItems items;
  items.insert({0,2}, @"A");
  items.insert({0,3}, @"B");
  CKArrayControllerInputChangeset changeset = {items};

  CKBadChangesetOperationType result = CKIsValidChangesetForSections(changeset, @[@[@"C", @"D"]]);
  XCTAssertEqual(result, CKBadChangesetOperationTypeNone);
}

- (void)test_validRemovalAtBeginningOfSection
{
  CKArrayControllerInputItems items;
  items.remove({0,0});
  CKArrayControllerInputChangeset changeset = {items};

  CKBadChangesetOperationType result = CKIsValidChangesetForSections(changeset, @[@[@"C", @"D"]]);
  XCTAssertEqual(result, CKBadChangesetOperationTypeNone);
}

- (void)test_validRemovalAtMiddleOfSection
{
  CKArrayControllerInputItems items;
  items.remove({0,1});
  CKArrayControllerInputChangeset changeset = {items};

  CKBadChangesetOperationType result = CKIsValidChangesetForSections(changeset, @[@[@"C", @"D", @"E"]]);
  XCTAssertEqual(result, CKBadChangesetOperationTypeNone);
}

- (void)test_validRemovalAtEndOfSection
{
  CKArrayControllerInputItems items;
  items.remove({0,2});
  items.remove({0,1});
  CKArrayControllerInputChangeset changeset = {items};

  CKBadChangesetOperationType result = CKIsValidChangesetForSections(changeset, @[@[@"C", @"D", @"E"]]);
  XCTAssertEqual(result, CKBadChangesetOperationTypeNone);
}

- (void)test_validRemovalOfAllItems
{
  CKArrayControllerInputItems items;
  items.remove({0,2});
  items.remove({0,1});
  items.remove({0,0});
  CKArrayControllerInputChangeset changeset = {items};

  CKBadChangesetOperationType result = CKIsValidChangesetForSections(changeset, @[@[@"C", @"D", @"E"]]);
  XCTAssertEqual(result, CKBadChangesetOperationTypeNone);
}

- (void)test_validInsertionOfSectionInEmptySections
{
  CKArrayControllerSections sections;
  sections.insert(0);
  CKArrayControllerInputChangeset changeset = {sections};

  CKBadChangesetOperationType result = CKIsValidChangesetForSections(changeset, @[]);
  XCTAssertEqual(result, CKBadChangesetOperationTypeNone);
}

- (void)test_validInsertionOfSectionAtBeginningOfNonEmptySections
{
  CKArrayControllerSections sections;
  sections.insert(0);
  CKArrayControllerInputChangeset changeset = {sections};

  CKBadChangesetOperationType result = CKIsValidChangesetForSections(changeset, @[@[@"C", @"D", @"E"]]);
  XCTAssertEqual(result, CKBadChangesetOperationTypeNone);
}

- (void)test_validInsertionOfSectionInMiddleOfNonEmptySections
{
  CKArrayControllerSections sections;
  sections.insert(1);
  CKArrayControllerInputChangeset changeset = {sections};

  CKBadChangesetOperationType result = CKIsValidChangesetForSections(changeset, @[@[@"C", @"D"], @[@"E", @"F"]]);
  XCTAssertEqual(result, CKBadChangesetOperationTypeNone);
}

- (void)test_validInsertionOfSectionAtEndOfNonEmptySections
{
  CKArrayControllerSections sections;
  sections.insert(1);
  CKArrayControllerInputChangeset changeset = {sections};

  CKBadChangesetOperationType result = CKIsValidChangesetForSections(changeset, @[@[@"C", @"D", @"E"]]);
  XCTAssertEqual(result, CKBadChangesetOperationTypeNone);
}

- (void)test_validInsertionOfMultipleSections
{
  CKArrayControllerSections sections;
  sections.insert(1);
  sections.insert(3);
  CKArrayControllerInputChangeset changeset = {sections};

  CKBadChangesetOperationType result = CKIsValidChangesetForSections(changeset, @[@[@"C", @"D"], @[@"E", @"F"]]);
  XCTAssertEqual(result, CKBadChangesetOperationTypeNone);
}

- (void)test_moveSectionFromBeginningToEnd
{
  CKArrayControllerSections sections;
  sections.move(0, 2);
  CKArrayControllerInputChangeset changeset = {sections};

  CKBadChangesetOperationType result = CKIsValidChangesetForSections(changeset, @[@[@"C", @"D"], @[@"E", @"F"], @[@"G", @"H"]]);
  XCTAssertEqual(result, CKBadChangesetOperationTypeNone);
}

- (void)test_moveSectionFromEndToBeginning
{
  CKArrayControllerSections sections;
  sections.move(2, 0);
  CKArrayControllerInputChangeset changeset = {sections};

  CKBadChangesetOperationType result = CKIsValidChangesetForSections(changeset, @[@[@"C", @"D"], @[@"E", @"F"], @[@"G", @"H"]]);
  XCTAssertEqual(result, CKBadChangesetOperationTypeNone);
}

- (void)test_moveSectionFromBeginningToMiddle
{
  CKArrayControllerSections sections;
  sections.move(0, 1);
  CKArrayControllerInputChangeset changeset = {sections};

  CKBadChangesetOperationType result = CKIsValidChangesetForSections(changeset, @[@[@"C", @"D"], @[@"E", @"F"], @[@"G", @"H"]]);
  XCTAssertEqual(result, CKBadChangesetOperationTypeNone);
}

- (void)test_moveSectionFromEndToMiddle
{
  CKArrayControllerSections sections;
  sections.move(2, 1);
  CKArrayControllerInputChangeset changeset = {sections};

  CKBadChangesetOperationType result = CKIsValidChangesetForSections(changeset, @[@[@"C", @"D"], @[@"E", @"F"], @[@"G", @"H"]]);
  XCTAssertEqual(result, CKBadChangesetOperationTypeNone);
}

- (void)test_removalOfSectionAtBeginningOfSections
{
  CKArrayControllerSections sections;
  sections.remove(0);
  CKArrayControllerInputChangeset changeset = {sections};

  CKBadChangesetOperationType result = CKIsValidChangesetForSections(changeset, @[@[@"C", @"D"], @[@"E", @"F"]]);
  XCTAssertEqual(result, CKBadChangesetOperationTypeNone);
}

- (void)test_removalOfSectionAtMiddleOfSections
{
  CKArrayControllerSections sections;
  sections.remove(1);
  CKArrayControllerInputChangeset changeset = {sections};

  CKBadChangesetOperationType result = CKIsValidChangesetForSections(changeset, @[@[@"C", @"D"], @[@"E", @"F"], @[@"G", @"H"]]);
  XCTAssertEqual(result, CKBadChangesetOperationTypeNone);
}

- (void)test_removalOfSectionAtEndOfSections
{
  CKArrayControllerSections sections;
  sections.remove(1);
  CKArrayControllerInputChangeset changeset = {sections};

  CKBadChangesetOperationType result = CKIsValidChangesetForSections(changeset, @[@[@"C", @"D"], @[@"E", @"F"]]);
  XCTAssertEqual(result, CKBadChangesetOperationTypeNone);
}

- (void)test_removeMultipleSectionsAtBeginningOfSections
{
  CKArrayControllerSections sections;
  sections.remove(1);
  sections.remove(0);
  CKArrayControllerInputChangeset changeset = {sections};

  CKBadChangesetOperationType result = CKIsValidChangesetForSections(changeset, @[@[@"C", @"D"], @[@"E", @"F"], @[@"G", @"H"]]);
  XCTAssertEqual(result, CKBadChangesetOperationTypeNone);
}

- (void)test_removeMultipleSectionsAtEndOfSections
{
  CKArrayControllerSections sections;
  sections.remove(2);
  sections.remove(1);
  CKArrayControllerInputChangeset changeset = {sections};

  CKBadChangesetOperationType result = CKIsValidChangesetForSections(changeset, @[@[@"C", @"D"], @[@"E", @"F"], @[@"G", @"H"]]);
  XCTAssertEqual(result, CKBadChangesetOperationTypeNone);
}

- (void)test_validUpdate
{
  CKArrayControllerInputItems items;
  items.update({0,0}, @"A");
  CKArrayControllerInputChangeset changeset = {items};

  CKBadChangesetOperationType result = CKIsValidChangesetForSections(changeset, @[@[@"C", @"D"]]);
  XCTAssertEqual(result, CKBadChangesetOperationTypeNone);
}

- (void)test_validMoveForwardInsideOneSection
{
  CKArrayControllerInputItems items;
  items.move({0,0}, {0,1});
  CKArrayControllerInputChangeset changeset = {items};

  CKBadChangesetOperationType result = CKIsValidChangesetForSections(changeset, @[@[@"C", @"D"]]);
  XCTAssertEqual(result, CKBadChangesetOperationTypeNone);
}

- (void)test_validMoveBackwardInsideOneSection
{
  CKArrayControllerInputItems items;
  items.move({0,1}, {0,0});
  CKArrayControllerInputChangeset changeset = {items};

  CKBadChangesetOperationType result = CKIsValidChangesetForSections(changeset, @[@[@"C", @"D"]]);
  XCTAssertEqual(result, CKBadChangesetOperationTypeNone);
}

- (void)test_validMoveForwardBetweenSections
{
  CKArrayControllerInputItems items;
  items.move({0,0}, {2,1});
  CKArrayControllerInputChangeset changeset = {items};

  CKBadChangesetOperationType result = CKIsValidChangesetForSections(changeset, @[@[@"C", @"D"], @[@"E", @"F"], @[@"G", @"H"]]);
  XCTAssertEqual(result, CKBadChangesetOperationTypeNone);
}

- (void)test_validMoveBackwardBetweenSections
{
  CKArrayControllerInputItems items;
  items.move({1,0}, {0,2});
  CKArrayControllerInputChangeset changeset = {items};

  CKBadChangesetOperationType result = CKIsValidChangesetForSections(changeset, @[@[@"C", @"D"], @[@"E", @"F"], @[@"G", @"H"]]);
  XCTAssertEqual(result, CKBadChangesetOperationTypeNone);
}

#pragma mark - Invalid changesets

- (void)test_invalidUpdateInNegativeSection
{
  CKArrayControllerInputItems items;
  items.update({-1,1}, @"A");
  CKArrayControllerInputChangeset changeset = {items};

  CKBadChangesetOperationType result = CKIsValidChangesetForSections(changeset, @[@[@"C", @"D"]]);
  XCTAssertEqual(result, CKBadChangesetOperationTypeUpdate);
}

- (void)test_invalidUpdateInNegativeRow
{
  CKArrayControllerInputItems items;
  items.update({0,-1}, @"A");
  CKArrayControllerInputChangeset changeset = {items};

  CKBadChangesetOperationType result = CKIsValidChangesetForSections(changeset, @[@[@"C", @"D"]]);
  XCTAssertEqual(result, CKBadChangesetOperationTypeUpdate);
}

- (void)test_invalidInsertionAtEndOfSection
{
  CKArrayControllerInputItems items;
  items.insert({0,3}, @"A");
  items.insert({0,4}, @"B");
  CKArrayControllerInputChangeset changeset = {items};

  CKBadChangesetOperationType result = CKIsValidChangesetForSections(changeset, @[@[@"C", @"D"]]);
  XCTAssertEqual(result, CKBadChangesetOperationTypeInsertRow);
}

- (void)test_invalidInsertionInNonExistentSection
{
  CKArrayControllerInputItems items;
  items.insert({1,0}, @"A");
  CKArrayControllerInputChangeset changeset = {items};

  CKBadChangesetOperationType result = CKIsValidChangesetForSections(changeset, @[@[@"C", @"D"]]);
  XCTAssertEqual(result, CKBadChangesetOperationTypeInsertRow);
}

- (void)test_invalidRemovalInValidSection
{
  CKArrayControllerInputItems items;
  items.remove({0,2});
  CKArrayControllerInputChangeset changeset = {items};

  CKBadChangesetOperationType result = CKIsValidChangesetForSections(changeset, @[@[@"C", @"D"]]);
  XCTAssertEqual(result, CKBadChangesetOperationTypeRemoveRow);
}

- (void)test_invalidRemovalInNonExistentSection
{
  CKArrayControllerInputItems items;
  items.remove({1,0});
  CKArrayControllerInputChangeset changeset = {items};

  CKBadChangesetOperationType result = CKIsValidChangesetForSections(changeset, @[@[@"C", @"D"]]);
  XCTAssertEqual(result, CKBadChangesetOperationTypeRemoveRow);
}

- (void)test_invalidInsertionOfSection
{
  CKArrayControllerSections sections;
  sections.insert(2);
  CKArrayControllerInputChangeset changeset = {sections};

  CKBadChangesetOperationType result = CKIsValidChangesetForSections(changeset, @[@[@"C", @"D"]]);
  XCTAssertEqual(result, CKBadChangesetOperationTypeInsertSection);
}

- (void)test_invalidRemovalOfSection
{
  CKArrayControllerSections sections;
  sections.remove(2);
  CKArrayControllerInputChangeset changeset = {sections};

  CKBadChangesetOperationType result = CKIsValidChangesetForSections(changeset, @[@[@"C", @"D"]]);
  XCTAssertEqual(result, CKBadChangesetOperationTypeRemoveSection);
}

- (void)test_invalidMoveOfSection
{
  CKArrayControllerSections sections;
  sections.move(0, 2);
  CKArrayControllerInputChangeset changeset = {sections};

  CKBadChangesetOperationType result = CKIsValidChangesetForSections(changeset, @[@[@"C", @"D"]]);
  XCTAssertEqual(result, CKBadChangesetOperationTypeMoveSection);
}

- (void)test_invalidUpdateWithinExistingSection
{
  CKArrayControllerInputItems items;
  items.update({0,2}, @"A");
  CKArrayControllerInputChangeset changeset = {items};

  CKBadChangesetOperationType result = CKIsValidChangesetForSections(changeset, @[@[@"C", @"D"]]);
  XCTAssertEqual(result, CKBadChangesetOperationTypeUpdate);
}

- (void)test_invalidUpdateWithinNonexistentSection
{
  CKArrayControllerInputItems items;
  items.update({1,0}, @"A");
  CKArrayControllerInputChangeset changeset = {items};

  CKBadChangesetOperationType result = CKIsValidChangesetForSections(changeset, @[@[@"C", @"D"]]);
  XCTAssertEqual(result, CKBadChangesetOperationTypeUpdate);
}

- (void)test_moveWithInvalidOriginIndexPathInExistingSection
{
  CKArrayControllerInputItems items;
  items.move({0,2}, {0,0});
  CKArrayControllerInputChangeset changeset = {items};

  CKBadChangesetOperationType result = CKIsValidChangesetForSections(changeset, @[@[@"C", @"D"]]);
  XCTAssertEqual(result, CKBadChangesetOperationTypeMoveRow);
}

- (void)test_moveWithInvalidDestinationIndexPathInExistingSection
{
  CKArrayControllerInputItems items;
  items.move({0,0}, {0,2});
  CKArrayControllerInputChangeset changeset = {items};

  CKBadChangesetOperationType result = CKIsValidChangesetForSections(changeset, @[@[@"C", @"D"]]);
  XCTAssertEqual(result, CKBadChangesetOperationTypeMoveRow);
}

- (void)test_moveWithInvalidOriginSection
{
  CKArrayControllerInputItems items;
  items.move({1,0}, {0,0});
  CKArrayControllerInputChangeset changeset = {items};

  CKBadChangesetOperationType result = CKIsValidChangesetForSections(changeset, @[@[@"C", @"D"]]);
  XCTAssertEqual(result, CKBadChangesetOperationTypeMoveRow);
}

- (void)test_moveWithInvalidDestinationSection
{
  CKArrayControllerInputItems items;
  items.move({0,0}, {1,0});
  CKArrayControllerInputChangeset changeset = {items};

  CKBadChangesetOperationType result = CKIsValidChangesetForSections(changeset, @[@[@"C", @"D"]]);
  XCTAssertEqual(result, CKBadChangesetOperationTypeMoveRow);
}

#pragma mark - More complicated situations

- (void)test_validSampleInitialInsertions
{
  CKArrayControllerSections sections;
  sections.insert(0);
  sections.insert(1);

  CKArrayControllerInputItems items;
  items.insert({0,0}, @"A1");
  items.insert({0,1}, @"B1");
  items.insert({1,0}, @"A2");
  items.insert({1,1}, @"B2");

  CKArrayControllerInputChangeset changeset = {sections, items};
  
  CKBadChangesetOperationType result = CKIsValidChangesetForSections(changeset, @[]);
  XCTAssertEqual(result, CKBadChangesetOperationTypeNone);
}

@end
