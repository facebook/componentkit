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

#import <ComponentKit/CKTransactionalComponentDataSourceAppliedChanges.h>

@interface CKTransactionalComponentDataSourceAppliedChangesTests : XCTestCase
@end

@implementation CKTransactionalComponentDataSourceAppliedChangesTests

- (void)testAppliedChangesEquality
{
  CKTransactionalComponentDataSourceAppliedChanges *firstAppliedChanges =
  [[CKTransactionalComponentDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:0 inSection:0]]
                                                                    removedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:1 inSection:0]]
                                                                      removedSections:[NSIndexSet indexSetWithIndex:2]
                                                                      movedIndexPaths:@{ [NSIndexPath indexPathForItem:3 inSection:0] : [NSIndexPath indexPathForItem:4 inSection:0] }
                                                                     insertedSections:[NSIndexSet indexSetWithIndex:1]
                                                                   insertedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:5 inSection:0]]
                                                                             userInfo:@{ @"key" : @"value"}];
  CKTransactionalComponentDataSourceAppliedChanges *secondAppliedChanges =
  [[CKTransactionalComponentDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:0 inSection:0]]
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
  CKTransactionalComponentDataSourceAppliedChanges *firstAppliedChanges =
  [[CKTransactionalComponentDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:0 inSection:0]]
                                                                    removedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:1 inSection:0]]
                                                                      removedSections:[NSIndexSet indexSetWithIndex:2]
                                                                      movedIndexPaths:@{ [NSIndexPath indexPathForItem:3 inSection:0] : [NSIndexPath indexPathForItem:4 inSection:0] }
                                                                     insertedSections:[NSIndexSet indexSetWithIndex:1]
                                                                   insertedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:5 inSection:0]]
                                                                             userInfo:@{ @"key" : @"value"}];
  CKTransactionalComponentDataSourceAppliedChanges *secondAppliedChanges =
  [[CKTransactionalComponentDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:0 inSection:0]]
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
  CKTransactionalComponentDataSourceAppliedChanges *changes =
  [[CKTransactionalComponentDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:nil
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
  CKTransactionalComponentDataSourceAppliedChanges *changes =
  [[CKTransactionalComponentDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:1 inSection:0]]
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
  CKTransactionalComponentDataSourceAppliedChanges *changes =
  [[CKTransactionalComponentDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:1 inSection:0]]
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
  CKTransactionalComponentDataSourceAppliedChanges *changes =
  [[CKTransactionalComponentDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:1 inSection:0]]
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
  CKTransactionalComponentDataSourceAppliedChanges *changes =
  [[CKTransactionalComponentDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:1 inSection:0]]
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
  CKTransactionalComponentDataSourceAppliedChanges *changes =
  [[CKTransactionalComponentDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:1 inSection:0]]
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
  CKTransactionalComponentDataSourceAppliedChanges *changes =
  [[CKTransactionalComponentDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:1 inSection:0]]
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
  CKTransactionalComponentDataSourceAppliedChanges *changes =
  [[CKTransactionalComponentDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:2 inSection:0]]
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
  CKTransactionalComponentDataSourceAppliedChanges *changes =
  [[CKTransactionalComponentDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:2 inSection:0]]
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
  CKTransactionalComponentDataSourceAppliedChanges *changes =
  [[CKTransactionalComponentDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:2 inSection:0]]
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
  CKTransactionalComponentDataSourceAppliedChanges *changes =
  [[CKTransactionalComponentDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:2 inSection:0]]
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
  CKTransactionalComponentDataSourceAppliedChanges *changes =
  [[CKTransactionalComponentDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:2 inSection:0]]
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
  
  CKTransactionalComponentDataSourceAppliedChanges *changes =
  [[CKTransactionalComponentDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:2 inSection:0]]
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
  
  CKTransactionalComponentDataSourceAppliedChanges *changes =
  [[CKTransactionalComponentDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:2 inSection:0]]
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
  CKTransactionalComponentDataSourceAppliedChanges *changes =
  [[CKTransactionalComponentDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:3 inSection:0]]
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
  CKTransactionalComponentDataSourceAppliedChanges *changes =
  [[CKTransactionalComponentDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:3 inSection:0]]
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
  CKTransactionalComponentDataSourceAppliedChanges *changes =
  [[CKTransactionalComponentDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:1 inSection:0]]
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
  CKTransactionalComponentDataSourceAppliedChanges *changes =
  [[CKTransactionalComponentDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:1 inSection:0]]
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
  CKTransactionalComponentDataSourceAppliedChanges *changes =
  [[CKTransactionalComponentDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:1 inSection:0]]
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
  CKTransactionalComponentDataSourceAppliedChanges *changes =
  [[CKTransactionalComponentDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:1 inSection:0]]
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
  CKTransactionalComponentDataSourceAppliedChanges *changes =
  [[CKTransactionalComponentDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:1 inSection:1]]
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
  CKTransactionalComponentDataSourceAppliedChanges *changes =
  [[CKTransactionalComponentDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:1 inSection:0]]
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
  
  CKTransactionalComponentDataSourceAppliedChanges *changes =
  [[CKTransactionalComponentDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:2 inSection:0]]
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
  CKTransactionalComponentDataSourceAppliedChanges *changes =
  [[CKTransactionalComponentDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:1 inSection:1]]
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
  CKTransactionalComponentDataSourceAppliedChanges *changes =
  [[CKTransactionalComponentDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:1 inSection:2]]
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
  
  CKTransactionalComponentDataSourceAppliedChanges *changes =
  [[CKTransactionalComponentDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:2 inSection:0]]
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
  CKTransactionalComponentDataSourceAppliedChanges *changes =
  [[CKTransactionalComponentDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:1 inSection:0]]
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
  CKTransactionalComponentDataSourceAppliedChanges *changes =
  [[CKTransactionalComponentDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:1 inSection:0]]
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
  CKTransactionalComponentDataSourceAppliedChanges *changes =
  [[CKTransactionalComponentDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:1 inSection:0]]
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
  CKTransactionalComponentDataSourceAppliedChanges *changes =
  [[CKTransactionalComponentDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:1 inSection:0]]
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
  
  CKTransactionalComponentDataSourceAppliedChanges *changes =
  [[CKTransactionalComponentDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:2 inSection:0]]
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
  
  CKTransactionalComponentDataSourceAppliedChanges *changes =
  [[CKTransactionalComponentDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:2 inSection:0]]
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
  
  CKTransactionalComponentDataSourceAppliedChanges *changes =
  [[CKTransactionalComponentDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:2 inSection:0]]
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
  
  CKTransactionalComponentDataSourceAppliedChanges *changes =
  [[CKTransactionalComponentDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:2 inSection:0]]
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
  CKTransactionalComponentDataSourceAppliedChanges *changes =
  [[CKTransactionalComponentDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:2 inSection:0]]
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
  CKTransactionalComponentDataSourceAppliedChanges *changes =
  [[CKTransactionalComponentDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:0 inSection:0]]
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
  CKTransactionalComponentDataSourceAppliedChanges *changes =
  [[CKTransactionalComponentDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:1 inSection:0]]
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
  CKTransactionalComponentDataSourceAppliedChanges *changes =
  [[CKTransactionalComponentDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:0 inSection:1]]
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
  CKTransactionalComponentDataSourceAppliedChanges *changes =
  [[CKTransactionalComponentDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:1 inSection:1]]
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
  CKTransactionalComponentDataSourceAppliedChanges *changes =
  [[CKTransactionalComponentDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:3 inSection:0]]
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
  CKTransactionalComponentDataSourceAppliedChanges *changes =
  [[CKTransactionalComponentDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:5 inSection:1]]
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
  CKTransactionalComponentDataSourceAppliedChanges *changes =
  [[CKTransactionalComponentDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:0 inSection:1]]
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
  CKTransactionalComponentDataSourceAppliedChanges *changes =
  [[CKTransactionalComponentDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObjects:[NSIndexPath indexPathForItem:0 inSection:0], [NSIndexPath indexPathForItem:1 inSection:0], [NSIndexPath indexPathForItem:2 inSection:0], nil]
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
  CKTransactionalComponentDataSourceAppliedChanges *changes =
  [[CKTransactionalComponentDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObjects:[NSIndexPath indexPathForItem:0 inSection:0], [NSIndexPath indexPathForItem:1 inSection:0], [NSIndexPath indexPathForItem:2 inSection:0], nil]
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
  CKTransactionalComponentDataSourceAppliedChanges *changes =
  [[CKTransactionalComponentDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:2 inSection:0]]
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
  CKTransactionalComponentDataSourceAppliedChanges *changes =
  [[CKTransactionalComponentDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:2 inSection:0]]
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
  CKTransactionalComponentDataSourceAppliedChanges *changes =
  [[CKTransactionalComponentDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:0 inSection:0]]
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
  CKTransactionalComponentDataSourceAppliedChanges *changes =
  [[CKTransactionalComponentDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:0 inSection:0]]
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
  CKTransactionalComponentDataSourceAppliedChanges *changes =
  [[CKTransactionalComponentDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:0 inSection:0]]
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
  CKTransactionalComponentDataSourceAppliedChanges *changes =
  [[CKTransactionalComponentDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithArray:updatedIndexPaths]
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
