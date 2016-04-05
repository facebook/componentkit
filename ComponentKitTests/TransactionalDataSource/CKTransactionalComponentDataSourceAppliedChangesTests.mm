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

@end
