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

#import <ComponentKit/CKDataSourceAppliedChanges.h>
#import <ComponentKitTestHelpers/CKChangesetHelpers.h>

using namespace CK;

@interface CKDataSourceAppliedChangesTests : XCTestCase
@end

@implementation CKDataSourceAppliedChangesTests

- (void)testAppliedChangesEquality
{
  CKDataSourceAppliedChanges *firstAppliedChanges =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:0 inSection:0]]
                                              removedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:1 inSection:0]]
                                                removedSections:[NSIndexSet indexSetWithIndex:2]
                                                movedIndexPaths:@{ [NSIndexPath indexPathForItem:3 inSection:0] : [NSIndexPath indexPathForItem:4 inSection:0] }
                                               insertedSections:[NSIndexSet indexSetWithIndex:1]
                                             insertedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:5 inSection:0]]
                                                       userInfo:@{ @"key" : @"value"}];
  CKDataSourceAppliedChanges *secondAppliedChanges =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:0 inSection:0]]
                                              removedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:1 inSection:0]]
                                                removedSections:[NSIndexSet indexSetWithIndex:2]
                                                movedIndexPaths:@{ [NSIndexPath indexPathForItem:3 inSection:0] : [NSIndexPath indexPathForItem:4 inSection:0] }
                                               insertedSections:[NSIndexSet indexSetWithIndex:1]
                                             insertedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:5 inSection:0]]
                                                       userInfo:@{ @"key" : @"value"}];
  XCTAssertEqualObjects(firstAppliedChanges, secondAppliedChanges);
}

- (void)testNonEqualAppliedChanges
{
  CKDataSourceAppliedChanges *firstAppliedChanges =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:0 inSection:0]]
                                              removedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:1 inSection:0]]
                                                removedSections:[NSIndexSet indexSetWithIndex:2]
                                                movedIndexPaths:@{ [NSIndexPath indexPathForItem:3 inSection:0] : [NSIndexPath indexPathForItem:4 inSection:0] }
                                               insertedSections:[NSIndexSet indexSetWithIndex:1]
                                             insertedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:5 inSection:0]]
                                                       userInfo:@{ @"key" : @"value"}];
  CKDataSourceAppliedChanges *secondAppliedChanges =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:0 inSection:0]]
                                              removedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:1 inSection:0]]
                                                removedSections:[NSIndexSet indexSetWithIndex:2]
                                                movedIndexPaths:@{ [NSIndexPath indexPathForItem:3 inSection:0] : [NSIndexPath indexPathForItem:4 inSection:0] }
                                               insertedSections:[NSIndexSet indexSetWithIndex:1]
                                             insertedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:5 inSection:0]]
                                                       userInfo:@{ @"key2" : @"value2"}];
  XCTAssertNotEqualObjects(firstAppliedChanges, secondAppliedChanges);
}

#pragma mark - Empty changeset

- (void)testEmptyChangeset
{
  CKDataSourceAppliedChanges *changes =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:nil
                                              removedIndexPaths:nil
                                                removedSections:nil
                                                movedIndexPaths:nil
                                               insertedSections:nil
                                             insertedIndexPaths:nil
                                                       userInfo:nil];
  
  XCTAssertEqual([[changes finalUpdatedIndexPaths] count], 0);
}

#pragma mark - Unaffected updates

- (void)testUpdate_UnaffectedByInsertion_SameSection
{
  CKDataSourceAppliedChanges *changes =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:1 inSection:0]]
                                              removedIndexPaths:nil
                                                removedSections:nil
                                                movedIndexPaths:nil
                                               insertedSections:nil
                                             insertedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:2 inSection:0]]
                                                       userInfo:nil];
  
  NSDictionary *updateMapping = [changes finalUpdatedIndexPaths];
  XCTAssertEqual([updateMapping count], 1);
  XCTAssertEqualObjects(updateMapping[[NSIndexPath indexPathForItem:1 inSection:0]], [NSIndexPath indexPathForItem:1 inSection:0]);
}

- (void)testUpdate_UnaffectedByInsertion_DifferentSection
{
  CKDataSourceAppliedChanges *changes =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:1 inSection:0]]
                                              removedIndexPaths:nil
                                                removedSections:nil
                                                movedIndexPaths:nil
                                               insertedSections:nil
                                             insertedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:0 inSection:1]]
                                                       userInfo:nil];
  NSDictionary *updateMapping = [changes finalUpdatedIndexPaths];
  XCTAssertEqual([updateMapping count], 1);
  XCTAssertEqualObjects(updateMapping[[NSIndexPath indexPathForItem:1 inSection:0]], [NSIndexPath indexPathForItem:1 inSection:0]);
}

- (void)testUpdate_UnaffectedByInsertedSection
{
  CKDataSourceAppliedChanges *changes =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:1 inSection:0]]
                                              removedIndexPaths:nil
                                                removedSections:nil
                                                movedIndexPaths:nil
                                               insertedSections:[NSIndexSet indexSetWithIndex:1]
                                             insertedIndexPaths:nil
                                                       userInfo:nil];
  NSDictionary *updateMapping = [changes finalUpdatedIndexPaths];
  XCTAssertEqual([updateMapping count], 1);
  XCTAssertEqualObjects(updateMapping[[NSIndexPath indexPathForItem:1 inSection:0]], [NSIndexPath indexPathForItem:1 inSection:0]);
}

- (void)testUpdate_UnaffectedByRemoval_SameSection
{
  CKDataSourceAppliedChanges *changes =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:1 inSection:0]]
                                              removedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:2 inSection:0]]
                                                removedSections:nil
                                                movedIndexPaths:nil
                                               insertedSections:nil
                                             insertedIndexPaths:nil
                                                       userInfo:nil];
  NSDictionary *updateMapping = [changes finalUpdatedIndexPaths];
  XCTAssertEqual([updateMapping count], 1);
  XCTAssertEqualObjects(updateMapping[[NSIndexPath indexPathForItem:1 inSection:0]], [NSIndexPath indexPathForItem:1 inSection:0]);
}

- (void)testUpdate_UnaffectedByRemoval_DifferentSection
{
  CKDataSourceAppliedChanges *changes =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:1 inSection:0]]
                                              removedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:0 inSection:1]]
                                                removedSections:nil
                                                movedIndexPaths:nil
                                               insertedSections:nil
                                             insertedIndexPaths:nil
                                                       userInfo:nil];
  NSDictionary *updateMapping = [changes finalUpdatedIndexPaths];
  XCTAssertEqual([updateMapping count], 1);
  XCTAssertEqualObjects(updateMapping[[NSIndexPath indexPathForItem:1 inSection:0]], [NSIndexPath indexPathForItem:1 inSection:0]);
}

- (void)testUpdate_UnaffectedByRemovedSection
{
  CKDataSourceAppliedChanges *changes =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:1 inSection:0]]
                                              removedIndexPaths:nil
                                                removedSections:[NSIndexSet indexSetWithIndex:1]
                                                movedIndexPaths:nil
                                               insertedSections:nil
                                             insertedIndexPaths:nil
                                                       userInfo:nil];
  NSDictionary *updateMapping = [changes finalUpdatedIndexPaths];
  XCTAssertEqual([updateMapping count], 1);
  XCTAssertEqualObjects(updateMapping[[NSIndexPath indexPathForItem:1 inSection:0]], [NSIndexPath indexPathForItem:1 inSection:0]);
}

- (void)testUpdate_UnaffectedByOffsettingInsertionsAndRemovals
{
  CKDataSourceAppliedChanges *changes =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:2 inSection:0]]
                                              removedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:1 inSection:0]]
                                                removedSections:nil
                                                movedIndexPaths:nil
                                               insertedSections:nil
                                             insertedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:0 inSection:0]]
                                                       userInfo:nil];
  NSDictionary *updateMapping = [changes finalUpdatedIndexPaths];
  XCTAssertEqual([updateMapping count], 1);
  XCTAssertEqualObjects(updateMapping[[NSIndexPath indexPathForItem:2 inSection:0]], [NSIndexPath indexPathForItem:2 inSection:0]);
}

- (void)testUpdate_UnaffectedByMoveBefore_SameSection
{
  CKDataSourceAppliedChanges *changes =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:2 inSection:0]]
                                              removedIndexPaths:nil
                                                removedSections:nil
                                                movedIndexPaths:@{ [NSIndexPath indexPathForItem:0 inSection:0] : [NSIndexPath indexPathForItem:1 inSection:0] }
                                               insertedSections:nil
                                             insertedIndexPaths:nil
                                                       userInfo:nil];
  NSDictionary *updateMapping = [changes finalUpdatedIndexPaths];
  XCTAssertEqual([updateMapping count], 1);
  XCTAssertEqualObjects(updateMapping[[NSIndexPath indexPathForItem:2 inSection:0]], [NSIndexPath indexPathForItem:2 inSection:0]);
}


- (void)testUpdate_UnaffectedByMoveAfter_SameSection
{
  CKDataSourceAppliedChanges *changes =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:2 inSection:0]]
                                              removedIndexPaths:nil
                                                removedSections:nil
                                                movedIndexPaths:@{ [NSIndexPath indexPathForItem:3 inSection:0] : [NSIndexPath indexPathForItem:4 inSection:0] }
                                               insertedSections:nil
                                             insertedIndexPaths:nil
                                                       userInfo:nil];
  NSDictionary *updateMapping = [changes finalUpdatedIndexPaths];
  XCTAssertEqual([updateMapping count], 1);
  XCTAssertEqualObjects(updateMapping[[NSIndexPath indexPathForItem:2 inSection:0]], [NSIndexPath indexPathForItem:2 inSection:0]);
}

- (void)testUpdate_UnaffectedByMoveAfter_FromDifferentSection
{
  CKDataSourceAppliedChanges *changes =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:2 inSection:0]]
                                              removedIndexPaths:nil
                                                removedSections:nil
                                                movedIndexPaths:@{ [NSIndexPath indexPathForItem:1 inSection:1] : [NSIndexPath indexPathForItem:4 inSection:0] }
                                               insertedSections:nil
                                             insertedIndexPaths:nil
                                                       userInfo:nil];
  NSDictionary *updateMapping = [changes finalUpdatedIndexPaths];
  XCTAssertEqual([updateMapping count], 1);
  XCTAssertEqualObjects(updateMapping[[NSIndexPath indexPathForItem:2 inSection:0]], [NSIndexPath indexPathForItem:2 inSection:0]);
}

- (void)testUpdate_UnaffectedByMoveAfter_ToDifferentSection
{
  CKDataSourceAppliedChanges *changes =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:2 inSection:0]]
                                              removedIndexPaths:nil
                                                removedSections:nil
                                                movedIndexPaths:@{ [NSIndexPath indexPathForItem:3 inSection:0] : [NSIndexPath indexPathForItem:1 inSection:1] }
                                               insertedSections:nil
                                             insertedIndexPaths:nil
                                                       userInfo:nil];
  NSDictionary *updateMapping = [changes finalUpdatedIndexPaths];
  XCTAssertEqual([updateMapping count], 1);
  XCTAssertEqualObjects(updateMapping[[NSIndexPath indexPathForItem:2 inSection:0]], [NSIndexPath indexPathForItem:2 inSection:0]);
}

- (void)testUpdate_UnaffectedByTwoOffsettingMoves_SameSection
{
  NSDictionary *moves = @{ [NSIndexPath indexPathForItem:0 inSection:0] : [NSIndexPath indexPathForItem:4 inSection:0],
                           [NSIndexPath indexPathForItem:3 inSection:0] : [NSIndexPath indexPathForItem:1 inSection:0]};
  
  CKDataSourceAppliedChanges *changes =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:2 inSection:0]]
                                              removedIndexPaths:nil
                                                removedSections:nil
                                                movedIndexPaths:moves
                                               insertedSections:nil
                                             insertedIndexPaths:nil
                                                       userInfo:nil];
  NSDictionary *updateMapping = [changes finalUpdatedIndexPaths];
  XCTAssertEqual([updateMapping count], 1);
  XCTAssertEqualObjects(updateMapping[[NSIndexPath indexPathForItem:2 inSection:0]], [NSIndexPath indexPathForItem:2 inSection:0]);
}

- (void)testUpdate_UnaffectedByTwoOffsettingMoves_DifferentSections
{
  NSDictionary *moves = @{ [NSIndexPath indexPathForItem:0 inSection:1] : [NSIndexPath indexPathForItem:0 inSection:0],
                           [NSIndexPath indexPathForItem:1 inSection:0] : [NSIndexPath indexPathForItem:1 inSection:1]};
  
  CKDataSourceAppliedChanges *changes =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:2 inSection:0]]
                                              removedIndexPaths:nil
                                                removedSections:nil
                                                movedIndexPaths:moves
                                               insertedSections:nil
                                             insertedIndexPaths:nil
                                                       userInfo:nil];
  NSDictionary *updateMapping = [changes finalUpdatedIndexPaths];
  XCTAssertEqual([updateMapping count], 1);
  XCTAssertEqualObjects(updateMapping[[NSIndexPath indexPathForItem:2 inSection:0]], [NSIndexPath indexPathForItem:2 inSection:0]);
}

- (void)testUpdate_UnaffectedByOffsettingInsertionAndMove
{
  CKDataSourceAppliedChanges *changes =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:3 inSection:0]]
                                              removedIndexPaths:nil
                                                removedSections:nil
                                                movedIndexPaths:@{ [NSIndexPath indexPathForItem:0 inSection:0] : [NSIndexPath indexPathForItem:6 inSection:0] }
                                               insertedSections:nil
                                             insertedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:2 inSection:0]]
                                                       userInfo:nil];
  NSDictionary *updateMapping = [changes finalUpdatedIndexPaths];
  XCTAssertEqual([updateMapping count], 1);
  XCTAssertEqualObjects(updateMapping[[NSIndexPath indexPathForItem:3 inSection:0]], [NSIndexPath indexPathForItem:3 inSection:0]);
}

- (void)testUpdate_UnaffectedByOffsettingRemovalAndMove
{
  CKDataSourceAppliedChanges *changes =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:3 inSection:0]]
                                              removedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:2 inSection:0]]
                                                removedSections:nil
                                                movedIndexPaths:@{ [NSIndexPath indexPathForItem:6 inSection:0] : [NSIndexPath indexPathForItem:0 inSection:0] }
                                               insertedSections:nil
                                             insertedIndexPaths:nil
                                                       userInfo:nil];
  NSDictionary *updateMapping = [changes finalUpdatedIndexPaths];
  XCTAssertEqual([updateMapping count], 1);
  XCTAssertEqualObjects(updateMapping[[NSIndexPath indexPathForItem:3 inSection:0]], [NSIndexPath indexPathForItem:3 inSection:0]);
}

#pragma mark - Affected updates by single operation (with potentially multiple pieces, i.e. two insertions, but not an insertion and a removal)

- (void)testUpdate_AffectedBySingleInsert
{
  CKDataSourceAppliedChanges *changes =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:1 inSection:0]]
                                              removedIndexPaths:nil
                                                removedSections:nil
                                                movedIndexPaths:nil
                                               insertedSections:nil
                                             insertedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:0 inSection:0]]
                                                       userInfo:nil];
  NSDictionary *updateMapping = [changes finalUpdatedIndexPaths];
  XCTAssertEqual([updateMapping count], 1);
  XCTAssertEqualObjects(updateMapping[[NSIndexPath indexPathForItem:1 inSection:0]], [NSIndexPath indexPathForItem:2 inSection:0]);
}

- (void)testUpdate_AffectedByMultipleDistinctInsertions
{
  NSSet *insertions = [NSSet setWithArray:@[[NSIndexPath indexPathForItem:0 inSection:0],
                                            [NSIndexPath indexPathForItem:1 inSection:0]]];
  CKDataSourceAppliedChanges *changes =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:1 inSection:0]]
                                              removedIndexPaths:nil
                                                removedSections:nil
                                                movedIndexPaths:nil
                                               insertedSections:nil
                                             insertedIndexPaths:insertions
                                                       userInfo:nil];
  NSDictionary *updateMapping = [changes finalUpdatedIndexPaths];
  XCTAssertEqual([updateMapping count], 1);
  XCTAssertEqualObjects(updateMapping[[NSIndexPath indexPathForItem:1 inSection:0]], [NSIndexPath indexPathForItem:3 inSection:0]);
}

- (void)testUpdate_AffectedByMultipleIdenticalInsertions
{
  NSSet *insertions = [NSSet setWithArray:@[[NSIndexPath indexPathForItem:0 inSection:0],
                                            [NSIndexPath indexPathForItem:0 inSection:0],
                                            [NSIndexPath indexPathForItem:0 inSection:0],
                                            [NSIndexPath indexPathForItem:0 inSection:0],
                                            [NSIndexPath indexPathForItem:0 inSection:0]]];
  CKDataSourceAppliedChanges *changes =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:1 inSection:0]]
                                              removedIndexPaths:nil
                                                removedSections:nil
                                                movedIndexPaths:nil
                                               insertedSections:nil
                                             insertedIndexPaths:insertions
                                                       userInfo:nil];
  NSDictionary *updateMapping = [changes finalUpdatedIndexPaths];
  XCTAssertEqual([updateMapping count], 1);
  // NOTE: the indexpath's row is only increased by 1 because changesets deduplicate identical inserts
  XCTAssertEqualObjects(updateMapping[[NSIndexPath indexPathForItem:1 inSection:0]], [NSIndexPath indexPathForItem:2 inSection:0]);
}

- (void)testUpdate_AffectedBySingleInsertedSection
{
  CKDataSourceAppliedChanges *changes =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:1 inSection:0]]
                                              removedIndexPaths:nil
                                                removedSections:nil
                                                movedIndexPaths:nil
                                               insertedSections:[NSIndexSet indexSetWithIndex:0]
                                             insertedIndexPaths:nil
                                                       userInfo:nil];
  NSDictionary *updateMapping = [changes finalUpdatedIndexPaths];
  XCTAssertEqual([updateMapping count], 1);
  XCTAssertEqualObjects(updateMapping[[NSIndexPath indexPathForItem:1 inSection:0]], [NSIndexPath indexPathForItem:1 inSection:1]);
}

- (void)testUpdate_AffectedByMultipleInsertedSections
{
  CKDataSourceAppliedChanges *changes =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:1 inSection:1]]
                                              removedIndexPaths:nil
                                                removedSections:nil
                                                movedIndexPaths:nil
                                               insertedSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)]
                                             insertedIndexPaths:nil
                                                       userInfo:nil];
  NSDictionary *updateMapping = [changes finalUpdatedIndexPaths];
  XCTAssertEqual([updateMapping count], 1);
  XCTAssertEqualObjects(updateMapping[[NSIndexPath indexPathForItem:1 inSection:1]], [NSIndexPath indexPathForItem:1 inSection:3]);
}

- (void)testUpdate_AffectedBySingleRemoval
{
  CKDataSourceAppliedChanges *changes =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:1 inSection:0]]
                                              removedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:0 inSection:0]]
                                                removedSections:nil
                                                movedIndexPaths:nil
                                               insertedSections:nil
                                             insertedIndexPaths:nil
                                                       userInfo:nil];
  NSDictionary *updateMapping = [changes finalUpdatedIndexPaths];
  XCTAssertEqual([updateMapping count], 1);
  XCTAssertEqualObjects(updateMapping[[NSIndexPath indexPathForItem:1 inSection:0]], [NSIndexPath indexPathForItem:0 inSection:0]);
}

- (void)testUpdate_AffectedByMultipleDistinctRemovals
{
  NSSet *removedIndexPaths = [NSSet setWithArray:@[[NSIndexPath indexPathForItem:0 inSection:0],
                                                   [NSIndexPath indexPathForItem:1 inSection:0]]];
  
  CKDataSourceAppliedChanges *changes =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:2 inSection:0]]
                                              removedIndexPaths:removedIndexPaths
                                                removedSections:nil
                                                movedIndexPaths:nil
                                               insertedSections:nil
                                             insertedIndexPaths:nil
                                                       userInfo:nil];
  NSDictionary *updateMapping = [changes finalUpdatedIndexPaths];
  XCTAssertEqual([updateMapping count], 1);
  XCTAssertEqualObjects(updateMapping[[NSIndexPath indexPathForItem:2 inSection:0]], [NSIndexPath indexPathForItem:0 inSection:0]);
}

- (void)testUpdate_AffectedByRemovingSingleSection
{
  CKDataSourceAppliedChanges *changes =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:1 inSection:1]]
                                              removedIndexPaths:nil
                                                removedSections:[NSIndexSet indexSetWithIndex:0]
                                                movedIndexPaths:nil
                                               insertedSections:nil
                                             insertedIndexPaths:nil
                                                       userInfo:nil];
  NSDictionary *updateMapping = [changes finalUpdatedIndexPaths];
  XCTAssertEqual([updateMapping count], 1);
  XCTAssertEqualObjects(updateMapping[[NSIndexPath indexPathForItem:1 inSection:1]], [NSIndexPath indexPathForItem:1 inSection:0]);
}

- (void)testUpdate_AffectedByRemovingMultipleSections
{
  CKDataSourceAppliedChanges *changes =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:1 inSection:2]]
                                              removedIndexPaths:nil
                                                removedSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)]
                                                movedIndexPaths:nil
                                               insertedSections:nil
                                             insertedIndexPaths:nil
                                                       userInfo:nil];
  NSDictionary *updateMapping = [changes finalUpdatedIndexPaths];
  XCTAssertEqual([updateMapping count], 1);
  XCTAssertEqualObjects(updateMapping[[NSIndexPath indexPathForItem:1 inSection:2]], [NSIndexPath indexPathForItem:1 inSection:0]);
}

- (void)testUpdate_AffectedByMultipleIdenticalRemovals
{
  NSSet *removedIndexPaths = [NSSet setWithArray:@[[NSIndexPath indexPathForItem:0 inSection:0],
                                                   [NSIndexPath indexPathForItem:0 inSection:0],
                                                   [NSIndexPath indexPathForItem:0 inSection:0],
                                                   [NSIndexPath indexPathForItem:0 inSection:0],
                                                   [NSIndexPath indexPathForItem:0 inSection:0]]];
  
  CKDataSourceAppliedChanges *changes =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:2 inSection:0]]
                                              removedIndexPaths:removedIndexPaths
                                                removedSections:nil
                                                movedIndexPaths:nil
                                               insertedSections:nil
                                             insertedIndexPaths:nil
                                                       userInfo:nil];
  NSDictionary *updateMapping = [changes finalUpdatedIndexPaths];
  XCTAssertEqual([updateMapping count], 1);
  XCTAssertEqualObjects(updateMapping[[NSIndexPath indexPathForItem:2 inSection:0]], [NSIndexPath indexPathForItem:1 inSection:0]);
}

- (void)testUpdate_AffectedBySingleMove_SameSection_FromBeforeToAfter
{
  CKDataSourceAppliedChanges *changes =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:1 inSection:0]]
                                              removedIndexPaths:nil
                                                removedSections:nil
                                                movedIndexPaths:@{ [NSIndexPath indexPathForItem:0 inSection:0] : [NSIndexPath indexPathForItem:2 inSection:0] }
                                               insertedSections:nil
                                             insertedIndexPaths:nil
                                                       userInfo:nil];
  NSDictionary *updateMapping = [changes finalUpdatedIndexPaths];
  XCTAssertEqual([updateMapping count], 1);
  XCTAssertEqualObjects(updateMapping[[NSIndexPath indexPathForItem:1 inSection:0]], [NSIndexPath indexPathForItem:0 inSection:0]);
}

- (void)testUpdate_AffectedBySingleMove_SameSection_FromAfterToBefore
{
  CKDataSourceAppliedChanges *changes =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:1 inSection:0]]
                                              removedIndexPaths:nil
                                                removedSections:nil
                                                movedIndexPaths:@{ [NSIndexPath indexPathForItem:2 inSection:0] : [NSIndexPath indexPathForItem:0 inSection:0] }
                                               insertedSections:nil
                                             insertedIndexPaths:nil
                                                       userInfo:nil];
  NSDictionary *updateMapping = [changes finalUpdatedIndexPaths];
  XCTAssertEqual([updateMapping count], 1);
  XCTAssertEqualObjects(updateMapping[[NSIndexPath indexPathForItem:1 inSection:0]], [NSIndexPath indexPathForItem:2 inSection:0]);
}

- (void)testUpdate_AffectedBySingleMove_IntoSection
{
  CKDataSourceAppliedChanges *changes =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:1 inSection:0]]
                                              removedIndexPaths:nil
                                                removedSections:nil
                                                movedIndexPaths:@{ [NSIndexPath indexPathForItem:2 inSection:1] : [NSIndexPath indexPathForItem:0 inSection:0] }
                                               insertedSections:nil
                                             insertedIndexPaths:nil
                                                       userInfo:nil];
  NSDictionary *updateMapping = [changes finalUpdatedIndexPaths];
  XCTAssertEqual([updateMapping count], 1);
  XCTAssertEqualObjects(updateMapping[[NSIndexPath indexPathForItem:1 inSection:0]], [NSIndexPath indexPathForItem:2 inSection:0]);
}

- (void)testUpdate_AffectedBySingleMove_OutOfSection
{
  CKDataSourceAppliedChanges *changes =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:1 inSection:0]]
                                              removedIndexPaths:nil
                                                removedSections:nil
                                                movedIndexPaths:@{ [NSIndexPath indexPathForItem:0 inSection:0] : [NSIndexPath indexPathForItem:0 inSection:1] }
                                               insertedSections:nil
                                             insertedIndexPaths:nil
                                                       userInfo:nil];
  NSDictionary *updateMapping = [changes finalUpdatedIndexPaths];
  XCTAssertEqual([updateMapping count], 1);
  XCTAssertEqualObjects(updateMapping[[NSIndexPath indexPathForItem:1 inSection:0]], [NSIndexPath indexPathForItem:0 inSection:0]);
}

- (void)testUpdate_AffectedByMultipleMoves_SameSection_FromBeforeToAfter
{
  NSDictionary *moves = @{ [NSIndexPath indexPathForItem:0 inSection:0] : [NSIndexPath indexPathForItem:3 inSection:0],
                           [NSIndexPath indexPathForItem:1 inSection:0] : [NSIndexPath indexPathForItem:4 inSection:0] };
  
  CKDataSourceAppliedChanges *changes =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:2 inSection:0]]
                                              removedIndexPaths:nil
                                                removedSections:nil
                                                movedIndexPaths:moves
                                               insertedSections:nil
                                             insertedIndexPaths:nil
                                                       userInfo:nil];
  NSDictionary *updateMapping = [changes finalUpdatedIndexPaths];
  XCTAssertEqual([updateMapping count], 1);
  XCTAssertEqualObjects(updateMapping[[NSIndexPath indexPathForItem:2 inSection:0]], [NSIndexPath indexPathForItem:0 inSection:0]);
}

- (void)testUpdate_AffectedByMultipleMoves_SameSection_FromAfterToBefore
{
  NSDictionary *moves = @{ [NSIndexPath indexPathForItem:3 inSection:0] : [NSIndexPath indexPathForItem:0 inSection:0],
                           [NSIndexPath indexPathForItem:4 inSection:0] : [NSIndexPath indexPathForItem:1 inSection:0] };
  
  CKDataSourceAppliedChanges *changes =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:2 inSection:0]]
                                              removedIndexPaths:nil
                                                removedSections:nil
                                                movedIndexPaths:moves
                                               insertedSections:nil
                                             insertedIndexPaths:nil
                                                       userInfo:nil];
  NSDictionary *updateMapping = [changes finalUpdatedIndexPaths];
  XCTAssertEqual([updateMapping count], 1);
  XCTAssertEqualObjects(updateMapping[[NSIndexPath indexPathForItem:2 inSection:0]], [NSIndexPath indexPathForItem:4 inSection:0]);
}

- (void)testUpdate_AffectedByMultipleMoves_IntoSection
{
  NSDictionary *moves = @{ [NSIndexPath indexPathForItem:0 inSection:1] : [NSIndexPath indexPathForItem:0 inSection:0],
                           [NSIndexPath indexPathForItem:1 inSection:1] : [NSIndexPath indexPathForItem:1 inSection:0]};
  
  CKDataSourceAppliedChanges *changes =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:2 inSection:0]]
                                              removedIndexPaths:nil
                                                removedSections:nil
                                                movedIndexPaths:moves
                                               insertedSections:nil
                                             insertedIndexPaths:nil
                                                       userInfo:nil];
  NSDictionary *updateMapping = [changes finalUpdatedIndexPaths];
  XCTAssertEqual([updateMapping count], 1);
  XCTAssertEqualObjects(updateMapping[[NSIndexPath indexPathForItem:2 inSection:0]], [NSIndexPath indexPathForItem:4 inSection:0]);
}

- (void)testUpdate_AffectedByMultipleMoves_OutOfSection
{
  NSDictionary *moves = @{ [NSIndexPath indexPathForItem:0 inSection:0] : [NSIndexPath indexPathForItem:0 inSection:1],
                           [NSIndexPath indexPathForItem:1 inSection:0] : [NSIndexPath indexPathForItem:1 inSection:1]};
  
  CKDataSourceAppliedChanges *changes =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:2 inSection:0]]
                                              removedIndexPaths:nil
                                                removedSections:nil
                                                movedIndexPaths:moves
                                               insertedSections:nil
                                             insertedIndexPaths:nil
                                                       userInfo:nil];
  NSDictionary *updateMapping = [changes finalUpdatedIndexPaths];
  XCTAssertEqual([updateMapping count], 1);
  XCTAssertEqualObjects(updateMapping[[NSIndexPath indexPathForItem:2 inSection:0]], [NSIndexPath indexPathForItem:0 inSection:0]);
}

#pragma mark - Affected updates by multiple operations

- (void)testUpdate_AffectedByInsertionAndMove
{
  CKDataSourceAppliedChanges *changes =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:2 inSection:0]]
                                              removedIndexPaths:nil
                                                removedSections:nil
                                                movedIndexPaths:@{ [NSIndexPath indexPathForItem:5 inSection:0] : [NSIndexPath indexPathForItem:0 inSection:0] }
                                               insertedSections:nil
                                             insertedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:1 inSection:0]]
                                                       userInfo:nil];
  NSDictionary *updateMapping = [changes finalUpdatedIndexPaths];
  XCTAssertEqual([updateMapping count], 1);
  XCTAssertEqualObjects(updateMapping[[NSIndexPath indexPathForItem:2 inSection:0]], [NSIndexPath indexPathForItem:4 inSection:0]);
}

// NOTE: In the transactional data source, rows are updated before insertions happen, and inserted sections happen before inserted rows (see comment at top of file). In this test case, the row insertion (section 0, row 0) does not affect the updated row (section 0, row 0) because the updated row would have been pushed to section 1 (because of the newly inserted section) before the new row is inserted.
- (void)testUpdate_AffectedBySectionInsertionAndRowInsertion
{
  CKDataSourceAppliedChanges *changes =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:0 inSection:0]]
                                              removedIndexPaths:nil
                                                removedSections:nil
                                                movedIndexPaths:nil
                                               insertedSections:[NSIndexSet indexSetWithIndex:0]
                                             insertedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:0 inSection:0]]
                                                       userInfo:nil];
  NSDictionary *updateMapping = [changes finalUpdatedIndexPaths];
  XCTAssertEqual([updateMapping count], 1);
  XCTAssertEqualObjects(updateMapping[[NSIndexPath indexPathForItem:0 inSection:0]], [NSIndexPath indexPathForItem:0 inSection:1]);
}

- (void)testUpdate_AffectedBySectionInsertionAndRowRemoval
{
  CKDataSourceAppliedChanges *changes =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:1 inSection:0]]
                                              removedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:0 inSection:0]]
                                                removedSections:nil
                                                movedIndexPaths:nil
                                               insertedSections:[NSIndexSet indexSetWithIndex:0]
                                             insertedIndexPaths:nil
                                                       userInfo:nil];
  NSDictionary *updateMapping = [changes finalUpdatedIndexPaths];
  XCTAssertEqual([updateMapping count], 1);
  XCTAssertEqualObjects(updateMapping[[NSIndexPath indexPathForItem:1 inSection:0]], [NSIndexPath indexPathForItem:0 inSection:1]);
}

- (void)testUpdate_AffectedBySectionRemovalAndRowInsertion
{
  CKDataSourceAppliedChanges *changes =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:0 inSection:1]]
                                              removedIndexPaths:nil
                                                removedSections:[NSIndexSet indexSetWithIndex:0]
                                                movedIndexPaths:nil
                                               insertedSections:nil
                                             insertedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:0 inSection:1]]
                                                       userInfo:nil];
  NSDictionary *updateMapping = [changes finalUpdatedIndexPaths];
  XCTAssertEqual([updateMapping count], 1);
  XCTAssertEqualObjects(updateMapping[[NSIndexPath indexPathForItem:0 inSection:1]], [NSIndexPath indexPathForItem:0 inSection:0]);
}

- (void)testUpdate_AffectedBySectionRemovalAndRowRemoval
{
  CKDataSourceAppliedChanges *changes =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:1 inSection:1]]
                                              removedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:0 inSection:1]]
                                                removedSections:[NSIndexSet indexSetWithIndex:0]
                                                movedIndexPaths:nil
                                               insertedSections:nil
                                             insertedIndexPaths:nil
                                                       userInfo:nil];
  NSDictionary *updateMapping = [changes finalUpdatedIndexPaths];
  XCTAssertEqual([updateMapping count], 1);
  XCTAssertEqualObjects(updateMapping[[NSIndexPath indexPathForItem:1 inSection:1]], [NSIndexPath indexPathForItem:0 inSection:0]);
}

// NOTE: Because of the order of operations (see comment at the top of this file), the inserted row doesn't affect the updated row, so the inserted section increments the update's section and the moved rows increment the update's row ( {0,3} -> {1,4} )
- (void)testUpdate_AffectedByMoveAndInsertedSection_UnaffectedByInsertedRows
{
  CKDataSourceAppliedChanges *changes =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:3 inSection:0]]
                                              removedIndexPaths:nil
                                                removedSections:nil
                                                movedIndexPaths:@{ [NSIndexPath indexPathForItem:4 inSection:0] : [NSIndexPath indexPathForItem:1 inSection:1] }
                                               insertedSections:[NSIndexSet indexSetWithIndex:0]
                                             insertedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:0 inSection:0]]
                                                       userInfo:nil];
  NSDictionary *updateMapping = [changes finalUpdatedIndexPaths];
  XCTAssertEqual([updateMapping count], 1);
  XCTAssertEqualObjects(updateMapping[[NSIndexPath indexPathForItem:3 inSection:0]], [NSIndexPath indexPathForItem:4 inSection:1]);
}

- (void)testUpdate_UnaffectedByOffsettingInsertionAndRemoval_AffectedByRemovedSection
{
  CKDataSourceAppliedChanges *changes =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:5 inSection:1]]
                                              removedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:2 inSection:1]]
                                                removedSections:[NSIndexSet indexSetWithIndex:0]
                                                movedIndexPaths:nil
                                               insertedSections:nil
                                             insertedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:1 inSection:1]]
                                                       userInfo:nil];
  NSDictionary *updateMapping = [changes finalUpdatedIndexPaths];
  XCTAssertEqual([updateMapping count], 1);
  XCTAssertEqualObjects(updateMapping[[NSIndexPath indexPathForItem:5 inSection:1]], [NSIndexPath indexPathForItem:4 inSection:0]);
}

- (void)testUpdate_AffectedByInsertedRowAfterBeingMovedToNewSection
{
  CKDataSourceAppliedChanges *changes =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:0 inSection:1]]
                                              removedIndexPaths:nil
                                                removedSections:nil
                                                movedIndexPaths:nil
                                               insertedSections:[NSIndexSet indexSetWithIndex:1]
                                             insertedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:0 inSection:2]]
                                                       userInfo:nil];
  NSDictionary *updateMapping = [changes finalUpdatedIndexPaths];
  XCTAssertEqual([updateMapping count], 1);
  XCTAssertEqualObjects(updateMapping[[NSIndexPath indexPathForItem:0 inSection:1]], [NSIndexPath indexPathForItem:1 inSection:2]);
}

- (void)testUpdate_AffectedByMoveAndUpdateAtSameIndexPath
{
  // [0, 1, 2] -> [2', 1', 0']
  CKDataSourceAppliedChanges *changes =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObjects:[NSIndexPath indexPathForItem:0 inSection:0], [NSIndexPath indexPathForItem:1 inSection:0], [NSIndexPath indexPathForItem:2 inSection:0], nil]
                                              removedIndexPaths:nil
                                                removedSections:nil
                                                movedIndexPaths:@{ [NSIndexPath indexPathForItem:2 inSection:0] : [NSIndexPath indexPathForItem:0 inSection:0], [NSIndexPath indexPathForItem:1 inSection:0] : [NSIndexPath indexPathForItem:1 inSection:0] }
                                               insertedSections:nil
                                             insertedIndexPaths:nil
                                                       userInfo:nil];
  NSDictionary *updateMapping = [changes finalUpdatedIndexPaths];
  XCTAssertEqualObjects(updateMapping,
                        (@{
                           [NSIndexPath indexPathForItem:0 inSection:0] : [NSIndexPath indexPathForItem:2 inSection:0],
                           [NSIndexPath indexPathForItem:1 inSection:0] : [NSIndexPath indexPathForItem:1 inSection:0],
                           [NSIndexPath indexPathForItem:2 inSection:0] : [NSIndexPath indexPathForItem:0 inSection:0]
                           }));
}

- (void)testUpdate_AffectedByAllOthers
{
  // [1, 2, 3] -> [0, 1', 4, 3', 2']
  CKDataSourceAppliedChanges *changes =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObjects:[NSIndexPath indexPathForItem:0 inSection:0], [NSIndexPath indexPathForItem:1 inSection:0], [NSIndexPath indexPathForItem:2 inSection:0], nil]
                                              removedIndexPaths:nil
                                                removedSections:nil
                                                movedIndexPaths:@{ [NSIndexPath indexPathForItem:2 inSection:0] : [NSIndexPath indexPathForItem:3 inSection:0] }
                                               insertedSections:nil
                                             insertedIndexPaths:[NSSet setWithObjects:[NSIndexPath indexPathForItem:0 inSection:0], [NSIndexPath indexPathForItem:2 inSection:0], nil]
                                                       userInfo:nil];
  NSDictionary *updateMapping = [changes finalUpdatedIndexPaths];
  XCTAssertEqualObjects(updateMapping,
                        (@{
                           [NSIndexPath indexPathForItem:0 inSection:0] : [NSIndexPath indexPathForItem:1 inSection:0],
                           [NSIndexPath indexPathForItem:1 inSection:0] : [NSIndexPath indexPathForItem:4 inSection:0],
                           [NSIndexPath indexPathForItem:2 inSection:0] : [NSIndexPath indexPathForItem:3 inSection:0]
                           }));
}

#pragma mark - Special cases

- (void)testUpdate_UpdatedRowBeingMoved_withoutAffectedDestination
{
  CKDataSourceAppliedChanges *changes =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:2 inSection:0]]
                                              removedIndexPaths:nil
                                                removedSections:nil
                                                movedIndexPaths:@{ [NSIndexPath indexPathForItem:2 inSection:0] : [NSIndexPath indexPathForItem:5 inSection:0] }
                                               insertedSections:nil
                                             insertedIndexPaths:nil
                                                       userInfo:nil];
  NSDictionary *updateMapping = [changes finalUpdatedIndexPaths];
  XCTAssertEqual([updateMapping count], 1);
  XCTAssertEqualObjects(updateMapping[[NSIndexPath indexPathForItem:2 inSection:0]], [NSIndexPath indexPathForItem:5 inSection:0]);
}

- (void)testUpdate_UpdatedRowBeingMoved_withAffectedDestination
{
  CKDataSourceAppliedChanges *changes =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:2 inSection:0]]
                                              removedIndexPaths:nil
                                                removedSections:nil
                                                movedIndexPaths:@{ [NSIndexPath indexPathForItem:2 inSection:0] : [NSIndexPath indexPathForItem:5 inSection:0] }
                                               insertedSections:nil
                                             insertedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:4 inSection:0]]
                                                       userInfo:nil];
  NSDictionary *updateMapping = [changes finalUpdatedIndexPaths];
  XCTAssertEqual([updateMapping count], 1);
  XCTAssertEqualObjects(updateMapping[[NSIndexPath indexPathForItem:2 inSection:0]], [NSIndexPath indexPathForItem:5 inSection:0]);
}

- (void)testUpdate_insertingThreeSectionsBefore
{
  CKDataSourceAppliedChanges *changes =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:0 inSection:0]]
                                              removedIndexPaths:nil
                                                removedSections:nil
                                                movedIndexPaths:nil
                                               insertedSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 3)]
                                             insertedIndexPaths:nil
                                                       userInfo:nil];
  NSDictionary *updateMapping = [changes finalUpdatedIndexPaths];
  XCTAssertEqual([updateMapping count], 1);
  XCTAssertEqualObjects(updateMapping[[NSIndexPath indexPathForItem:0 inSection:0]], [NSIndexPath indexPathForItem:0 inSection:3]);
}

- (void)testUpdate_insertingThreeRowsBefore
{
  CKDataSourceAppliedChanges *changes =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:0 inSection:0]]
                                              removedIndexPaths:nil
                                                removedSections:nil
                                                movedIndexPaths:nil
                                               insertedSections:nil
                                             insertedIndexPaths:[NSSet setWithArray:@[[NSIndexPath indexPathForRow:0 inSection:0], [NSIndexPath indexPathForRow:1 inSection:0], [NSIndexPath indexPathForRow:2 inSection:0]]]
                                                       userInfo:nil];
  NSDictionary *updateMapping = [changes finalUpdatedIndexPaths];
  XCTAssertEqual([updateMapping count], 1);
  XCTAssertEqualObjects(updateMapping[[NSIndexPath indexPathForItem:0 inSection:0]], [NSIndexPath indexPathForItem:3 inSection:0]);
}

- (void)testUpdate_insertingThreeSectionsAndThreeRowsBefore
{
  CKDataSourceAppliedChanges *changes =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:0 inSection:0]]
                                              removedIndexPaths:nil
                                                removedSections:nil
                                                movedIndexPaths:nil
                                               insertedSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 3)]
                                             insertedIndexPaths:[NSSet setWithArray:@[[NSIndexPath indexPathForRow:0 inSection:3], [NSIndexPath indexPathForRow:1 inSection:3], [NSIndexPath indexPathForRow:2 inSection:3]]]
                                                       userInfo:nil];
  NSDictionary *updateMapping = [changes finalUpdatedIndexPaths];
  XCTAssertEqual([updateMapping count], 1);
  XCTAssertEqualObjects(updateMapping[[NSIndexPath indexPathForItem:0 inSection:0]], [NSIndexPath indexPathForItem:3 inSection:3]);
}

- (void)testUpdate_mirroringGroupsCrash
{
  NSArray *updatedIndexPaths = @[[NSIndexPath indexPathForItem:0 inSection:0],
                                 [NSIndexPath indexPathForItem:0 inSection:1],
                                 [NSIndexPath indexPathForItem:0 inSection:4]];
  NSMutableIndexSet *insertedSections = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 4)];
  [insertedSections addIndex:5];
  NSArray *insertedIndexPaths = @[[NSIndexPath indexPathForItem:0 inSection:0],
                                  [NSIndexPath indexPathForItem:0 inSection:1],
                                  [NSIndexPath indexPathForItem:0 inSection:2],
                                  [NSIndexPath indexPathForItem:0 inSection:3],
                                  [NSIndexPath indexPathForItem:0 inSection:5]];
  CKDataSourceAppliedChanges *changes =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithArray:updatedIndexPaths]
                                              removedIndexPaths:nil
                                                removedSections:nil
                                                movedIndexPaths:nil
                                               insertedSections:insertedSections
                                             insertedIndexPaths:[NSSet setWithArray:insertedIndexPaths]
                                                       userInfo:nil];
  NSDictionary *updateMapping = [changes finalUpdatedIndexPaths];
  XCTAssertEqual([updateMapping count], [updatedIndexPaths count]);
  XCTAssertEqualObjects(updateMapping[[NSIndexPath indexPathForItem:0 inSection:0]], [NSIndexPath indexPathForItem:0 inSection:4]);
  XCTAssertEqualObjects(updateMapping[[NSIndexPath indexPathForItem:0 inSection:1]], [NSIndexPath indexPathForItem:0 inSection:6]);
  XCTAssertEqualObjects(updateMapping[[NSIndexPath indexPathForItem:0 inSection:4]], [NSIndexPath indexPathForItem:0 inSection:9]);
}

@end

@interface CKDataSourceAppliedChangesTests_Description : XCTestCase
@end

@implementation CKDataSourceAppliedChangesTests_Description

- (void)test_WhenEmpty_DescriptionIsEmpty
{
  auto const changes = [CKDataSourceAppliedChanges new];

  auto const description = [changes description];

  XCTAssertEqualObjects(description, @"");
}

- (void)test_WhenHasSectionChanges_IncludesThemInDescription
{
  auto const changes = [[CKDataSourceAppliedChanges alloc]
                        initWithUpdatedIndexPaths:nil
                        removedIndexPaths:nil
                        removedSections:[NSIndexSet indexSetWithIndexesInRange:{0, 2}]
                        movedIndexPaths:nil
                        insertedSections:[NSIndexSet indexSetWithIndex:0]
                        insertedIndexPaths:nil
                        userInfo:nil];;

  auto const description = [changes description];

  auto const expectedDescription =
  @"\
{\n\
  Removed Sections: 0–1\n\
  Inserted Sections: 0\n\
}";
  XCTAssertEqualObjects(description, expectedDescription);
}

- (void)test_WhenHasRemovedItems_IncludesThemInDescriptionSorted
{
  auto const changes = [[CKDataSourceAppliedChanges alloc]
                        initWithUpdatedIndexPaths:nil
                        removedIndexPaths:[NSSet setWithArray:@[
                          IndexPath{1, 1}.toCocoa(),
                          IndexPath{0, 2}.toCocoa(),
                        ]]
                        removedSections:nil
                        movedIndexPaths:nil
                        insertedSections:nil
                        insertedIndexPaths:nil
                        userInfo:nil];;

  auto const description = [changes description];

  auto const expectedDescription =
  @"\
{\n\
  Removed Items: {\n\
    (0-2),\n\
    (1-1)\n\
  }\n\
}";
  XCTAssertEqualObjects(description, expectedDescription);
}

- (void)test_WhenHasUpdatedItems_IncludesThemInDescriptionSorted
{
  auto const changes = [[CKDataSourceAppliedChanges alloc]
                        initWithUpdatedIndexPaths:[NSSet setWithArray:@[
                          IndexPath{1, 1}.toCocoa(),
                          IndexPath{0, 2}.toCocoa(),
                        ]]
                        removedIndexPaths:nil
                        removedSections:nil
                        movedIndexPaths:nil
                        insertedSections:nil
                        insertedIndexPaths:nil
                        userInfo:nil];;

  auto const description = [changes description];

  auto const expectedDescription =
  @"\
{\n\
  Updated Items: {\n\
    (0-2),\n\
    (1-1)\n\
  }\n\
}";
  XCTAssertEqualObjects(description, expectedDescription);
}

- (void)test_WhenHasInsertedItems_IncludesThemInDescriptionSorted
{
  auto const changes = [[CKDataSourceAppliedChanges alloc]
                        initWithUpdatedIndexPaths:nil
                        removedIndexPaths:nil
                        removedSections:nil
                        movedIndexPaths:nil
                        insertedSections:nil
                        insertedIndexPaths:[NSSet setWithArray:@[
                          IndexPath{1, 1}.toCocoa(),
                          IndexPath{0, 2}.toCocoa(),
                        ]]
                        userInfo:nil];;

  auto const description = [changes description];

  auto const expectedDescription =
  @"\
{\n\
  Inserted Items: {\n\
    (0-2),\n\
    (1-1)\n\
  }\n\
}";
  XCTAssertEqualObjects(description, expectedDescription);
}

- (void)test_WhenHasMovedItems_IncludesThemInDescriptionSortedByFromIndexPath
{
  auto const changes = [[CKDataSourceAppliedChanges alloc]
                        initWithUpdatedIndexPaths:nil
                        removedIndexPaths:nil
                        removedSections:nil
                        movedIndexPaths:@{
                          IndexPath{1, 1}.toCocoa() : IndexPath{1, 2}.toCocoa(),
                          IndexPath{0, 2}.toCocoa() : IndexPath{0, 0}.toCocoa(),
                        }
                        insertedSections:nil
                        insertedIndexPaths:nil
                        userInfo:nil];;

  auto const description = [changes description];

  auto const expectedDescription =
  @"\
{\n\
  Moved Items: {\n\
    (0-2) -> (0-0),\n\
    (1-1) -> (1-2)\n\
  }\n\
}";
  XCTAssertEqualObjects(description, expectedDescription);
}
@end
