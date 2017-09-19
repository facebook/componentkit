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

#import <ComponentKit/CKTransactionalComponentDataSourceChangesetInternal.h>

@interface CKTransactionalComponentDataSourceChangesetTests : XCTestCase
@end

@implementation CKTransactionalComponentDataSourceChangesetTests

- (void)testChangesetEquality
{
  CKTransactionalComponentDataSourceChangeset *firstChangeset =
  [[CKTransactionalComponentDataSourceChangeset alloc] initWithUpdatedItems:@{[NSIndexPath indexPathForItem:0 inSection:0] : @"A"}
                                                               removedItems:[NSSet setWithObject:[NSIndexPath indexPathForItem:1 inSection:0]]
                                                            removedSections:[NSIndexSet indexSetWithIndex:2]
                                                                 movedItems:@{[NSIndexPath indexPathForItem:2 inSection:0] : [NSIndexPath indexPathForItem:3 inSection:0]}
                                                           insertedSections:[NSIndexSet indexSetWithIndex:1]
                                                              insertedItems:@{[NSIndexPath indexPathForItem:0 inSection:1] : @"B"}];
  CKTransactionalComponentDataSourceChangeset *secondChangeset =
  [[CKTransactionalComponentDataSourceChangeset alloc] initWithUpdatedItems:@{[NSIndexPath indexPathForItem:0 inSection:0] : @"A"}
                                                               removedItems:[NSSet setWithObject:[NSIndexPath indexPathForItem:1 inSection:0]]
                                                            removedSections:[NSIndexSet indexSetWithIndex:2]
                                                                 movedItems:@{[NSIndexPath indexPathForItem:2 inSection:0] : [NSIndexPath indexPathForItem:3 inSection:0]}
                                                           insertedSections:[NSIndexSet indexSetWithIndex:1]
                                                              insertedItems:@{[NSIndexPath indexPathForItem:0 inSection:1] : @"B"}];
  XCTAssertEqualObjects(firstChangeset, secondChangeset);
}

- (void)testChangesetsNotEqual
{
  CKTransactionalComponentDataSourceChangeset *firstChangeset =
  [[CKTransactionalComponentDataSourceChangeset alloc] initWithUpdatedItems:@{[NSIndexPath indexPathForItem:0 inSection:0] : @"A"}
                                                               removedItems:[NSSet setWithObject:[NSIndexPath indexPathForItem:1 inSection:0]]
                                                            removedSections:[NSIndexSet indexSetWithIndex:2]
                                                                 movedItems:@{[NSIndexPath indexPathForItem:2 inSection:0] : [NSIndexPath indexPathForItem:3 inSection:0]}
                                                           insertedSections:[NSIndexSet indexSetWithIndex:1]
                                                              insertedItems:@{[NSIndexPath indexPathForItem:0 inSection:1] : @"B"}];
  CKTransactionalComponentDataSourceChangeset *secondChangeset =
  [[CKTransactionalComponentDataSourceChangeset alloc] initWithUpdatedItems:@{[NSIndexPath indexPathForItem:0 inSection:0] : @"A"}
                                                               removedItems:[NSSet setWithObject:[NSIndexPath indexPathForItem:1 inSection:0]]
                                                            removedSections:[NSIndexSet indexSetWithIndex:2]
                                                                 movedItems:@{[NSIndexPath indexPathForItem:2 inSection:0] : [NSIndexPath indexPathForItem:3 inSection:0]}
                                                           insertedSections:[NSIndexSet indexSetWithIndex:1]
                                                              insertedItems:@{[NSIndexPath indexPathForItem:0 inSection:1] : @"C"}];
  XCTAssertNotEqualObjects(firstChangeset, secondChangeset);
}

- (void)testChangesetIsEmpty
{
  XCTAssertTrue([[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset] build].isEmpty);

  XCTAssertFalse([[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
                   withInsertedItems:@{[NSIndexPath indexPathForItem:0 inSection:0] : @"A"}] build].isEmpty);
  XCTAssertFalse([[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
                   withRemovedItems:[NSSet setWithObject:[NSIndexPath indexPathForItem:1 inSection:0]]] build].isEmpty);
  XCTAssertFalse([[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
                   withRemovedSections:[NSIndexSet indexSetWithIndex:2]] build].isEmpty);
  XCTAssertFalse([[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
                   withUpdatedItems:@{[NSIndexPath indexPathForItem:2 inSection:0] : [NSIndexPath indexPathForItem:3 inSection:0]}] build].isEmpty);
  XCTAssertFalse([[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
                   withInsertedSections:[NSIndexSet indexSetWithIndex:1]] build].isEmpty);
  XCTAssertFalse([[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
                   withInsertedItems:@{[NSIndexPath indexPathForItem:0 inSection:1] : @"C"}] build].isEmpty);
}

@end
