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

#include <stdlib.h>

#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKComponentLayout.h>
#import <ComponentKit/CKComponentProvider.h>
#import <ComponentKit/CKTransactionalComponentDataSourceAppliedChanges.h>
#import <ComponentKit/CKTransactionalComponentDataSourceChange.h>
#import <ComponentKit/CKDataSourceChangeset.h>
#import <ComponentKit/CKTransactionalComponentDataSourceItem.h>
#import <ComponentKit/CKTransactionalComponentDataSourceChangesetModification.h>
#import <ComponentKit/CKTransactionalComponentDataSourceState.h>

#import "CKTransactionalComponentDataSourceStateTestHelpers.h"

@interface CKModelExposingComponent : CKComponent
+ (instancetype)newWithModel:(id)model;
@property (nonatomic, strong, readonly) id model;
@end

@implementation CKModelExposingComponent

+ (instancetype)newWithModel:(id)model
{
  CKModelExposingComponent *c = [super new];
  if (c) {
    c->_model = model;
  }
  return c;
}

@end

@interface CKTransactionalComponentDataSourceChangesetModificationTests : XCTestCase <CKComponentProvider>
@end

@implementation CKTransactionalComponentDataSourceChangesetModificationTests

+ (CKComponent *)componentForModel:(id<NSObject>)model context:(id<NSObject>)context
{
  return [CKModelExposingComponent newWithModel:model];
}

- (void)testAppliedChangesIncludesUserInfo
{
  CKTransactionalComponentDataSourceState *originalState = CKTransactionalComponentDataSourceTestState([self class], nil, 1, 1);
  NSDictionary *userInfo = @{@"foo": @"bar"};
  CKTransactionalComponentDataSourceChangesetModification *changesetModification =
  [[CKTransactionalComponentDataSourceChangesetModification alloc] initWithChangeset:[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset] build]
                                                                       stateListener:nil
                                                                            userInfo:userInfo];
  CKTransactionalComponentDataSourceChange *change = [changesetModification changeFromState:originalState];
  XCTAssertEqualObjects([[change appliedChanges] userInfo], userInfo);
}

- (void)testInsertingSectionAndItemsInEmptyStateExposesNewItems
{
  CKTransactionalComponentDataSourceState *originalState = CKTransactionalComponentDataSourceTestState([self class], nil, 0, 0);
  CKDataSourceChangeset *changeset =
  [[[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
     withInsertedSections:[NSIndexSet indexSetWithIndex:0]]
    withInsertedItems:@{[NSIndexPath indexPathForItem:0 inSection:0]: @1, [NSIndexPath indexPathForItem:1 inSection:0]: @2}]
   build];
  CKTransactionalComponentDataSourceChangesetModification *changesetModification =
  [[CKTransactionalComponentDataSourceChangesetModification alloc] initWithChangeset:changeset
                                                                       stateListener:nil
                                                                            userInfo:nil];
  CKTransactionalComponentDataSourceChange *change = [changesetModification changeFromState:originalState];
  XCTAssertEqual([[change state] numberOfSections], (NSUInteger)1);
  XCTAssertEqual([[change state] numberOfObjectsInSection:0], (NSUInteger)2);
}

- (void)testAppliesRemovedItemsThenRemovedSections
{
  CKTransactionalComponentDataSourceState *originalState = CKTransactionalComponentDataSourceTestState([self class], nil, 2, 2);
  CKDataSourceChangeset *changeset =
  [[[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
     withRemovedItems:[NSSet setWithObject:[NSIndexPath indexPathForItem:0 inSection:1]]]
    withRemovedSections:[NSIndexSet indexSetWithIndex:0]]
   build];
  CKTransactionalComponentDataSourceChangesetModification *changesetModification =
  [[CKTransactionalComponentDataSourceChangesetModification alloc] initWithChangeset:changeset
                                                                       stateListener:nil
                                                                            userInfo:nil];
  CKTransactionalComponentDataSourceChange *change = [changesetModification changeFromState:originalState];

  // Initial state: [0, 1], [2, 3]
  // Remove section 0 and item 0 in section 1.
  // Result should be [3]
  // If items were removed *after* section removals instead of before, we'd have an out-of-range section.

  XCTAssertEqual([[change state] numberOfSections], (NSUInteger)1);
  XCTAssertEqual([[change state] numberOfObjectsInSection:0], (NSUInteger)1);
  auto c = (CKModelExposingComponent *)[[[change state] objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]] layout].component;
  XCTAssertEqualObjects(c.model, @3);
}

- (void)testUpdateGeneratesNewComponent
{
  CKTransactionalComponentDataSourceState *originalState = CKTransactionalComponentDataSourceTestState([self class], nil, 1, 1);
  CKDataSourceChangeset *changeset =
  [[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withUpdatedItems:@{[NSIndexPath indexPathForItem:0 inSection:0]: @"updated"}]
   build];
  CKTransactionalComponentDataSourceChangesetModification *changesetModification =
  [[CKTransactionalComponentDataSourceChangesetModification alloc] initWithChangeset:changeset
                                                                       stateListener:nil
                                                                            userInfo:nil];
  CKTransactionalComponentDataSourceChange *change = [changesetModification changeFromState:originalState];

  auto c = (CKModelExposingComponent *)[[[change state] objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]] layout].component;
  XCTAssertEqualObjects(c.model, @"updated");
}

- (void)testAppliesRemovedItemsThenInsertedItems
{
  CKTransactionalComponentDataSourceState *originalState = CKTransactionalComponentDataSourceTestState([self class], nil, 1, 2);
  CKDataSourceChangeset *changeset =
  [[[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
     withInsertedItems:@{[NSIndexPath indexPathForItem:1 inSection:0]: @2}]
    withRemovedItems:[NSSet setWithObject:[NSIndexPath indexPathForItem:0 inSection:0]]]
   build];
  CKTransactionalComponentDataSourceChangesetModification *changesetModification =
  [[CKTransactionalComponentDataSourceChangesetModification alloc] initWithChangeset:changeset
                                                                       stateListener:nil
                                                                            userInfo:nil];
  CKTransactionalComponentDataSourceChange *change = [changesetModification changeFromState:originalState];

  // Initial state: [0, 1]
  // Remove 0, insert @2 at index 1.
  // Result should be [1, 2]
  // If removals were applied after insertions, we'd end up with [2, 1] instead.

  auto c = (CKModelExposingComponent *)[[[change state] objectAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]] layout].component;
  XCTAssertEqualObjects(c.model, @2);
}

- (void)testMoveItem
{
  CKTransactionalComponentDataSourceState *originalState = CKTransactionalComponentDataSourceTestState([self class], nil, 1, 3);
  CKDataSourceChangeset *changeset =
  [[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withMovedItems:@{[NSIndexPath indexPathForItem:0 inSection:0]: [NSIndexPath indexPathForItem:2 inSection:0]}]
   build];
  CKTransactionalComponentDataSourceChangesetModification *changesetModification =
  [[CKTransactionalComponentDataSourceChangesetModification alloc] initWithChangeset:changeset
                                                                       stateListener:nil
                                                                            userInfo:nil];
  CKTransactionalComponentDataSourceChange *change = [changesetModification changeFromState:originalState];

  // Initial state: [0, 1, 2]
  // We move the first element to the last position
  // Result should be [1, 2, 0]

  auto c = (CKModelExposingComponent *)[[[change state] objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]] layout].component;
  XCTAssertEqualObjects(c.model, @1);

  c = (CKModelExposingComponent *)[[[change state] objectAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]] layout].component;
  XCTAssertEqualObjects(c.model, @2);

  c = (CKModelExposingComponent *)[[[change state] objectAtIndexPath:[NSIndexPath indexPathForItem:2 inSection:0]] layout].component;
  XCTAssertEqualObjects(c.model, @0);
}

- (void)testSwapItemsWithMoves
{
  CKTransactionalComponentDataSourceState *originalState = CKTransactionalComponentDataSourceTestState([self class], nil, 2, 2);
  CKDataSourceChangeset *changeset =
  [[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withMovedItems:@{[NSIndexPath indexPathForItem:0 inSection:0]: [NSIndexPath indexPathForItem:0 inSection:1],
                     [NSIndexPath indexPathForItem:0 inSection:1]: [NSIndexPath indexPathForItem:0 inSection:0]}]
   build];
  CKTransactionalComponentDataSourceChangesetModification *changesetModification =
  [[CKTransactionalComponentDataSourceChangesetModification alloc] initWithChangeset:changeset
                                                                       stateListener:nil
                                                                            userInfo:nil];
  CKTransactionalComponentDataSourceChange *change = [changesetModification changeFromState:originalState];

  // Initial state: [0, 1], [2, 3]
  // We should basically swap the first elements in each section;
  // Result should be [2, 1], [0, 3]
  // If moves were applied immediately one-by-one instead of being modeled as batched removals + inserts,
  // then we'd basically just move 0 into section 1 and then back, ending with the same state.

  auto c = (CKModelExposingComponent *)[[[change state] objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]] layout].component;
  XCTAssertEqualObjects(c.model, @2);

  c = (CKModelExposingComponent *)[[[change state] objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:1]] layout].component;
  XCTAssertEqualObjects(c.model, @0);
}

- (void)testMoveWithRemovals
{
  CKTransactionalComponentDataSourceState *originalState = CKTransactionalComponentDataSourceTestState([self class], nil, 1, 4);
  CKDataSourceChangeset *changeset =
  [[[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
     withMovedItems:@{[NSIndexPath indexPathForItem:3 inSection:0] : [NSIndexPath indexPathForItem:0 inSection:0] }]
    withRemovedItems:[NSSet setWithArray:@[[NSIndexPath indexPathForItem:1 inSection:0], [NSIndexPath indexPathForItem:2 inSection:0]]]]
   build];
  CKTransactionalComponentDataSourceChangesetModification *changesetModification =
  [[CKTransactionalComponentDataSourceChangesetModification alloc] initWithChangeset:changeset
                                                                       stateListener:nil
                                                                            userInfo:nil];
  CKTransactionalComponentDataSourceChange *change = [changesetModification changeFromState:originalState];

  // Initial state: [0, 1, 2, 3], Final state: [3, 0]
  auto c0 = (CKModelExposingComponent *)[[[change state] objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]] layout].component;
  auto c1 = (CKModelExposingComponent *)[[[change state] objectAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]] layout].component;
  XCTAssertEqualObjects(c0.model, @3);
  XCTAssertEqualObjects(c1.model, @0);
}

@end
