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
#import <ComponentKit/CKDataSourceAppliedChanges.h>
#import <ComponentKit/CKDataSourceChange.h>
#import <ComponentKit/CKDataSourceChangeset.h>
#import <ComponentKit/CKDataSourceItem.h>
#import <ComponentKit/CKDataSourceChangesetModification.h>
#import <ComponentKit/CKDataSourceState.h>
#import <ComponentKitTestHelpers/NSIndexSetExtensions.h>

#import "CKDataSourceStateTestHelpers.h"

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

@interface CKDataSourceChangesetModificationTests : XCTestCase <CKComponentProvider>
@end

@implementation CKDataSourceChangesetModificationTests

+ (CKComponent *)componentForModel:(id<NSObject>)model context:(id<NSObject>)context
{
  return [CKModelExposingComponent newWithModel:model];
}

- (void)testAppliedChangesIncludesUserInfo
{
  CKDataSourceState *originalState = CKDataSourceTestState([self class], nil, 1, 1);
  NSDictionary *userInfo = @{@"foo": @"bar"};
  CKDataSourceChangesetModification *changesetModification =
  [[CKDataSourceChangesetModification alloc] initWithChangeset:[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset] build]
                                                                       stateListener:nil
                                                                            userInfo:userInfo];
  CKDataSourceChange *change = [changesetModification changeFromState:originalState];
  XCTAssertEqualObjects([[change appliedChanges] userInfo], userInfo);
}

- (void)testInsertingSectionAndItemsInEmptyStateExposesNewItems
{
  CKDataSourceState *originalState = CKDataSourceTestState([self class], nil, 0, 0);
  CKDataSourceChangeset *changeset =
  [[[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
     withInsertedSections:[NSIndexSet indexSetWithIndex:0]]
    withInsertedItems:@{[NSIndexPath indexPathForItem:0 inSection:0]: @1, [NSIndexPath indexPathForItem:1 inSection:0]: @2}]
   build];
  CKDataSourceChangesetModification *changesetModification =
  [[CKDataSourceChangesetModification alloc] initWithChangeset:changeset
                                                                       stateListener:nil
                                                                            userInfo:nil];
  CKDataSourceChange *change = [changesetModification changeFromState:originalState];
  XCTAssertEqual([[change state] numberOfSections], (NSUInteger)1);
  XCTAssertEqual([[change state] numberOfObjectsInSection:0], (NSUInteger)2);
}

- (void)testAppliesRemovedItemsThenRemovedSections
{
  CKDataSourceState *originalState = CKDataSourceTestState([self class], nil, 2, 2);
  CKDataSourceChangeset *changeset =
  [[[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
     withRemovedItems:[NSSet setWithObject:[NSIndexPath indexPathForItem:0 inSection:1]]]
    withRemovedSections:[NSIndexSet indexSetWithIndex:0]]
   build];
  CKDataSourceChangesetModification *changesetModification =
  [[CKDataSourceChangesetModification alloc] initWithChangeset:changeset
                                                                       stateListener:nil
                                                                            userInfo:nil];
  CKDataSourceChange *change = [changesetModification changeFromState:originalState];

  // Initial state: [0, 1], [2, 3]
  // Remove section 0 and item 0 in section 1.
  // Result should be [3]
  // If items were removed *after* section removals instead of before, we'd have an out-of-range section.

  XCTAssertEqual([[change state] numberOfSections], (NSUInteger)1);
  XCTAssertEqual([[change state] numberOfObjectsInSection:0], (NSUInteger)1);
  auto c = (CKModelExposingComponent *)[[[change state] objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]] rootLayout].component();
  XCTAssertEqualObjects(c.model, @3);
}

- (void)testUpdateGeneratesNewComponent
{
  CKDataSourceState *originalState = CKDataSourceTestState([self class], nil, 1, 1);
  CKDataSourceChangeset *changeset =
  [[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withUpdatedItems:@{[NSIndexPath indexPathForItem:0 inSection:0]: @"updated"}]
   build];
  CKDataSourceChangesetModification *changesetModification =
  [[CKDataSourceChangesetModification alloc] initWithChangeset:changeset
                                                                       stateListener:nil
                                                                            userInfo:nil];
  CKDataSourceChange *change = [changesetModification changeFromState:originalState];

  auto c = (CKModelExposingComponent *)[[[change state] objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]] rootLayout].component();
  XCTAssertEqualObjects(c.model, @"updated");
}

- (void)testAppliesRemovedItemsThenInsertedItems
{
  CKDataSourceState *originalState = CKDataSourceTestState([self class], nil, 1, 2);
  CKDataSourceChangeset *changeset =
  [[[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
     withInsertedItems:@{[NSIndexPath indexPathForItem:1 inSection:0]: @2}]
    withRemovedItems:[NSSet setWithObject:[NSIndexPath indexPathForItem:0 inSection:0]]]
   build];
  CKDataSourceChangesetModification *changesetModification =
  [[CKDataSourceChangesetModification alloc] initWithChangeset:changeset
                                                                       stateListener:nil
                                                                            userInfo:nil];
  CKDataSourceChange *change = [changesetModification changeFromState:originalState];

  // Initial state: [0, 1]
  // Remove 0, insert @2 at index 1.
  // Result should be [1, 2]
  // If removals were applied after insertions, we'd end up with [2, 1] instead.

  auto c = (CKModelExposingComponent *)[[[change state] objectAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]] rootLayout].component();
  XCTAssertEqualObjects(c.model, @2);
}

- (void)testMoveItem
{
  CKDataSourceState *originalState = CKDataSourceTestState([self class], nil, 1, 3);
  CKDataSourceChangeset *changeset =
  [[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withMovedItems:@{[NSIndexPath indexPathForItem:0 inSection:0]: [NSIndexPath indexPathForItem:2 inSection:0]}]
   build];
  CKDataSourceChangesetModification *changesetModification =
  [[CKDataSourceChangesetModification alloc] initWithChangeset:changeset
                                                                       stateListener:nil
                                                                            userInfo:nil];
  CKDataSourceChange *change = [changesetModification changeFromState:originalState];

  // Initial state: [0, 1, 2]
  // We move the first element to the last position
  // Result should be [1, 2, 0]

  auto c = (CKModelExposingComponent *)[[[change state] objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]] rootLayout].component();
  XCTAssertEqualObjects(c.model, @1);

  c = (CKModelExposingComponent *)[[[change state] objectAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]] rootLayout].component();
  XCTAssertEqualObjects(c.model, @2);

  c = (CKModelExposingComponent *)[[[change state] objectAtIndexPath:[NSIndexPath indexPathForItem:2 inSection:0]] rootLayout].component();
  XCTAssertEqualObjects(c.model, @0);
}

- (void)testSwapItemsWithMoves
{
  CKDataSourceState *originalState = CKDataSourceTestState([self class], nil, 2, 2);
  CKDataSourceChangeset *changeset =
  [[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withMovedItems:@{[NSIndexPath indexPathForItem:0 inSection:0]: [NSIndexPath indexPathForItem:0 inSection:1],
                     [NSIndexPath indexPathForItem:0 inSection:1]: [NSIndexPath indexPathForItem:0 inSection:0]}]
   build];
  CKDataSourceChangesetModification *changesetModification =
  [[CKDataSourceChangesetModification alloc] initWithChangeset:changeset
                                                                       stateListener:nil
                                                                            userInfo:nil];
  CKDataSourceChange *change = [changesetModification changeFromState:originalState];

  // Initial state: [0, 1], [2, 3]
  // We should basically swap the first elements in each section;
  // Result should be [2, 1], [0, 3]
  // If moves were applied immediately one-by-one instead of being modeled as batched removals + inserts,
  // then we'd basically just move 0 into section 1 and then back, ending with the same state.

  auto c = (CKModelExposingComponent *)[[[change state] objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]] rootLayout].component();
  XCTAssertEqualObjects(c.model, @2);

  c = (CKModelExposingComponent *)[[[change state] objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:1]] rootLayout].component();
  XCTAssertEqualObjects(c.model, @0);
}

- (void)testMoveWithRemovals
{
  CKDataSourceState *originalState = CKDataSourceTestState([self class], nil, 1, 4);
  CKDataSourceChangeset *changeset =
  [[[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
     withMovedItems:@{[NSIndexPath indexPathForItem:3 inSection:0] : [NSIndexPath indexPathForItem:0 inSection:0] }]
    withRemovedItems:[NSSet setWithArray:@[[NSIndexPath indexPathForItem:1 inSection:0], [NSIndexPath indexPathForItem:2 inSection:0]]]]
   build];
  CKDataSourceChangesetModification *changesetModification =
  [[CKDataSourceChangesetModification alloc] initWithChangeset:changeset
                                                                       stateListener:nil
                                                                            userInfo:nil];
  CKDataSourceChange *change = [changesetModification changeFromState:originalState];

  // Initial state: [0, 1, 2, 3], Final state: [3, 0]
  auto c0 = (CKModelExposingComponent *)[[[change state] objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]] rootLayout].component();
  auto c1 = (CKModelExposingComponent *)[[[change state] objectAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]] rootLayout].component();
  XCTAssertEqualObjects(c0.model, @3);
  XCTAssertEqualObjects(c1.model, @0);
}

- (void)testParallelism
{
  CKDataSourceState *originalState = CKDataSourceTestState([self class], nil, 5, 5, YES);
  CKDataSourceChangeset *changeset =
  [[[[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
      withInsertedSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 5)]]
     withInsertedItems:@{[NSIndexPath indexPathForItem:0 inSection:0]: @1,
                         [NSIndexPath indexPathForItem:1 inSection:0]: @2,
                         [NSIndexPath indexPathForItem:0 inSection:1]: @1,
                         [NSIndexPath indexPathForItem:1 inSection:1]: @2,
                         [NSIndexPath indexPathForItem:0 inSection:2]: @1,
                         [NSIndexPath indexPathForItem:1 inSection:2]: @2,
                         [NSIndexPath indexPathForItem:0 inSection:3]: @1,
                         [NSIndexPath indexPathForItem:1 inSection:3]: @2,
                         [NSIndexPath indexPathForItem:0 inSection:4]: @1,
                         [NSIndexPath indexPathForItem:1 inSection:4]: @2,
                         }]
    withUpdatedItems:@{[NSIndexPath indexPathForRow:0 inSection:0]: @1,
                       [NSIndexPath indexPathForRow:0 inSection:1]: @1,
                       [NSIndexPath indexPathForRow:0 inSection:2]: @1,
                       [NSIndexPath indexPathForRow:0 inSection:3]: @1,
                       [NSIndexPath indexPathForRow:0 inSection:4]: @1,
                       }]
   build];
  dispatch_queue_t queue = dispatch_queue_create("org.componentkit.tests.queue", DISPATCH_QUEUE_CONCURRENT);
  CKDataSourceChangesetModification *changesetModification =
  [[CKDataSourceChangesetModification alloc] initWithChangeset:changeset
                                                 stateListener:nil
                                                      userInfo:nil
                                                         queue:queue];
  CKDataSourceChange *change = [changesetModification changeFromState:originalState];
  XCTAssertEqual([[change state] numberOfSections], (NSUInteger)10);
  XCTAssertEqual([[change state] numberOfObjectsInSection:0], (NSUInteger)2);
}


@end

// Based on https://developer.apple.com/documentation/foundation/nsmutablearray/1416482-insertobjects?language=objc
@interface CKArrayInsertionValidation: XCTestCase
@end

@implementation CKArrayInsertionValidation

- (void)test_WhenInsertionLocationIsCount_IsValid
{
  const auto array = @[];
  const auto indexes = [NSIndexSet indexSetWithIndex:array.count];

  XCTAssertEqual(CK::invalidIndexesForInsertionInArray(array, indexes).count, 0);
}

- (void)test_WhenFirstInsertionLocationIsGreaterThanCount_IsNotValid
{
  const auto array = @[@"one"];
  const auto indexes = [NSIndexSet indexSetWithIndex:array.count + 1];

  XCTAssertEqualObjects(CK::invalidIndexesForInsertionInArray(array, indexes), indexes);
}

- (void)test_WhenOtherInsertionLocationIsGreaterThanCount_IsNotValid
{
  const auto array = @[@"one"];
  const auto indexes = CK::makeIndexSet({1, 3});

  XCTAssertEqualObjects(CK::invalidIndexesForInsertionInArray(array, indexes), CK::makeIndexSet({3}));
}

@end

@interface CKArrayRemovalValidation: XCTestCase
@end

@implementation CKArrayRemovalValidation

- (void)test_WhenRemovalLocationIsEqualToCount_IsNotValid
{
  const auto array = @[];
  const auto indexes = [NSIndexSet indexSetWithIndex:array.count];

  XCTAssertEqualObjects(CK::invalidIndexesForRemovalFromArray(array, indexes), CK::makeIndexSet({0}));
}

- (void)test_WhenFirstRemovalLocationIsWithinBounds_IsValid
{
  const auto array = @[@"one"];
  const auto indexes = CK::makeIndexSet({0});

  XCTAssertEqual(CK::invalidIndexesForRemovalFromArray(array, indexes).count, 0);
}

- (void)test_WhenOtherRemovalLocationIsGreaterThanCount_IsNotValid
{
  const auto array = @[@"one"];
  const auto indexes = CK::makeIndexSet({0, 1});

  XCTAssertEqualObjects(CK::invalidIndexesForRemovalFromArray(array, indexes), CK::makeIndexSet({1}));
}

@end
