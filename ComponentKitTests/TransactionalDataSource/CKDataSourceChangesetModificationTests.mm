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
#import <ComponentKit/CKCompositeComponent.h>
#import <ComponentKit/CKComponentLayout.h>
#import <ComponentKit/CKComponentProvider.h>
#import <ComponentKit/CKDataSourceAppliedChanges.h>
#import <ComponentKit/CKDataSourceChange.h>
#import <ComponentKit/CKDataSourceChangeset.h>
#import <ComponentKit/CKDataSourceItem.h>
#import <ComponentKit/CKDataSourceChangesetModification.h>
#import <ComponentKit/CKDataSourceState.h>
#import <ComponentKitTestHelpers/CKLifecycleTestComponent.h>
#import <ComponentKitTestHelpers/NSIndexSetExtensions.h>

#import "CKDataSourceStateTestHelpers.h"

static NSString *const kTestModelForLifecycleComponent = @"kTestModelForLifecycleComponent";

@interface CKModelExposingComponent : CKCompositeComponent
+ (instancetype)newWithModel:(id)model;
@property (nonatomic, strong, readonly) id model;
@property (nonatomic, strong, readonly) CKLifecycleTestComponent *lifecycleComponent;
@end

@implementation CKModelExposingComponent

+ (instancetype)newWithModel:(id)model
{
  CKLifecycleTestComponent *lifecycleComponent = [model isEqual:kTestModelForLifecycleComponent]
  ? [CKLifecycleTestComponent newWithView:{} size:{}]
  : nil;
  const auto c = [super newWithComponent:lifecycleComponent ?: CK::ComponentBuilder()
                                                                   .build()];
  if (c) {
    c->_model = model;
    c->_lifecycleComponent = lifecycleComponent;
  }
  return c;
}

@end

@interface CKDataSourceChangesetModificationTests : XCTestCase
@end

@implementation CKDataSourceChangesetModificationTests

static CKComponent *ComponentProvider(id<NSObject> model, id<NSObject>)
{
  return [CKModelExposingComponent newWithModel:model];
}

- (void)testAppliedChangesIncludesUserInfo
{
  CKDataSourceState *originalState = CKDataSourceTestState(ComponentProvider, nil, 1, 1);
  NSDictionary *userInfo = @{@"foo": @"bar"};
  CKDataSourceChangesetModification *changesetModification =
  [[CKDataSourceChangesetModification alloc] initWithChangeset:[[CKDataSourceChangesetBuilder dataSourceChangeset] build]
                                                                       stateListener:nil
                                                                            userInfo:userInfo
                                                           qos:CKDataSourceQOSDefault
                                       shouldValidateChangeset:NO];
  CKDataSourceChange *change = [changesetModification changeFromState:originalState];
  XCTAssertEqualObjects([[change appliedChanges] userInfo], userInfo);
}

- (void)testInsertingSectionAndItemsInEmptyStateExposesNewItems
{
  CKDataSourceState *originalState = CKDataSourceTestState(ComponentProvider, nil, 0, 0);
  CKDataSourceChangeset *changeset =
  [[[[CKDataSourceChangesetBuilder dataSourceChangeset]
     withInsertedSections:[NSIndexSet indexSetWithIndex:0]]
    withInsertedItems:@{[NSIndexPath indexPathForItem:0 inSection:0]: @1, [NSIndexPath indexPathForItem:1 inSection:0]: @2}]
   build];
  CKDataSourceChangesetModification *changesetModification =
  [[CKDataSourceChangesetModification alloc] initWithChangeset:changeset
                                                                       stateListener:nil
                                                                            userInfo:nil
                                                           qos:CKDataSourceQOSDefault
                                       shouldValidateChangeset:NO];
  CKDataSourceChange *change = [changesetModification changeFromState:originalState];
  XCTAssertEqual([[change state] numberOfSections], (NSUInteger)1);
  XCTAssertEqual([[change state] numberOfObjectsInSection:0], (NSUInteger)2);
}

- (void)testAppliesRemovedItemsThenRemovedSections
{
  CKDataSourceState *originalState = CKDataSourceTestState(ComponentProvider, nil, 2, 2);
  CKDataSourceChangeset *changeset =
  [[[[CKDataSourceChangesetBuilder dataSourceChangeset]
     withRemovedItems:[NSSet setWithObject:[NSIndexPath indexPathForItem:0 inSection:1]]]
    withRemovedSections:[NSIndexSet indexSetWithIndex:0]]
   build];
  CKDataSourceChangesetModification *changesetModification =
  [[CKDataSourceChangesetModification alloc] initWithChangeset:changeset
                                                                       stateListener:nil
                                                                            userInfo:nil
                                                           qos:CKDataSourceQOSDefault
                                       shouldValidateChangeset:NO];
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
  CKDataSourceState *originalState = CKDataSourceTestState(ComponentProvider, nil, 1, 1);
  CKDataSourceChangeset *changeset =
  [[[CKDataSourceChangesetBuilder dataSourceChangeset]
    withUpdatedItems:@{[NSIndexPath indexPathForItem:0 inSection:0]: @"updated"}]
   build];
  CKDataSourceChangesetModification *changesetModification =
  [[CKDataSourceChangesetModification alloc] initWithChangeset:changeset
                                                                       stateListener:nil
                                                                            userInfo:nil
                                                           qos:CKDataSourceQOSDefault
                                       shouldValidateChangeset:NO];
  CKDataSourceChange *change = [changesetModification changeFromState:originalState];

  auto c = (CKModelExposingComponent *)[[[change state] objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]] rootLayout].component();
  XCTAssertEqualObjects(c.model, @"updated");
}

- (void)testUpdateReturnsInvalidComponentControllers
{
  const auto originalState = CKDataSourceTestState(ComponentProvider, nil, 1, 0);
  const auto ip = [NSIndexPath indexPathForItem:0 inSection:0];
  auto changeset =
  [[[CKDataSourceChangesetBuilder dataSourceChangeset]
    withInsertedItems:@{ip: kTestModelForLifecycleComponent}]
   build];
  auto change =
  [[[CKDataSourceChangesetModification alloc]
    initWithChangeset:changeset
    stateListener:nil
    userInfo:nil
    qos:CKDataSourceQOSDefault
    shouldValidateChangeset:NO]
   changeFromState:originalState];

  const auto componentController =
  ((CKModelExposingComponent *)[[change.state objectAtIndexPath:ip] rootLayout].component()).lifecycleComponent.controller;

  changeset =
  [[[CKDataSourceChangesetBuilder dataSourceChangeset]
    withUpdatedItems:@{ip: @""}]
   build];
  change =
  [[[CKDataSourceChangesetModification alloc]
    initWithChangeset:changeset
    stateListener:nil
    userInfo:nil
    qos:CKDataSourceQOSDefault
    shouldValidateChangeset:NO]
   changeFromState:change.state];

  XCTAssertEqual(change.invalidComponentControllers.firstObject, componentController,
                 @"Invalid component controller should be returned because component is removed from hierarchy.");
}

- (void)testAppliesRemovedItemsThenInsertedItems
{
  CKDataSourceState *originalState = CKDataSourceTestState(ComponentProvider, nil, 1, 2);
  CKDataSourceChangeset *changeset =
  [[[[CKDataSourceChangesetBuilder dataSourceChangeset]
     withInsertedItems:@{[NSIndexPath indexPathForItem:1 inSection:0]: @2}]
    withRemovedItems:[NSSet setWithObject:[NSIndexPath indexPathForItem:0 inSection:0]]]
   build];
  CKDataSourceChangesetModification *changesetModification =
  [[CKDataSourceChangesetModification alloc] initWithChangeset:changeset
                                                 stateListener:nil
                                                      userInfo:nil
                                                           qos:CKDataSourceQOSDefault
                                       shouldValidateChangeset:NO];
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
  CKDataSourceState *originalState = CKDataSourceTestState(ComponentProvider, nil, 1, 3);
  CKDataSourceChangeset *changeset =
  [[[CKDataSourceChangesetBuilder dataSourceChangeset]
    withMovedItems:@{[NSIndexPath indexPathForItem:0 inSection:0]: [NSIndexPath indexPathForItem:2 inSection:0]}]
   build];
  CKDataSourceChangesetModification *changesetModification =
  [[CKDataSourceChangesetModification alloc] initWithChangeset:changeset
                                                 stateListener:nil
                                                      userInfo:nil
                                                           qos:CKDataSourceQOSDefault
                                       shouldValidateChangeset:NO];
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
  CKDataSourceState *originalState = CKDataSourceTestState(ComponentProvider, nil, 2, 2);
  CKDataSourceChangeset *changeset =
  [[[CKDataSourceChangesetBuilder dataSourceChangeset]
    withMovedItems:@{[NSIndexPath indexPathForItem:0 inSection:0]: [NSIndexPath indexPathForItem:0 inSection:1],
                     [NSIndexPath indexPathForItem:0 inSection:1]: [NSIndexPath indexPathForItem:0 inSection:0]}]
   build];
  CKDataSourceChangesetModification *changesetModification =
  [[CKDataSourceChangesetModification alloc] initWithChangeset:changeset
                                                 stateListener:nil
                                                      userInfo:nil
                                                           qos:CKDataSourceQOSDefault
                                       shouldValidateChangeset:NO];
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
  CKDataSourceState *originalState = CKDataSourceTestState(ComponentProvider, nil, 1, 4);
  CKDataSourceChangeset *changeset =
  [[[[CKDataSourceChangesetBuilder dataSourceChangeset]
     withMovedItems:@{[NSIndexPath indexPathForItem:3 inSection:0] : [NSIndexPath indexPathForItem:0 inSection:0] }]
    withRemovedItems:[NSSet setWithArray:@[[NSIndexPath indexPathForItem:1 inSection:0], [NSIndexPath indexPathForItem:2 inSection:0]]]]
   build];
  CKDataSourceChangesetModification *changesetModification =
  [[CKDataSourceChangesetModification alloc] initWithChangeset:changeset
                                                 stateListener:nil
                                                      userInfo:nil
                                                           qos:CKDataSourceQOSDefault
                                       shouldValidateChangeset:NO];
  CKDataSourceChange *change = [changesetModification changeFromState:originalState];

  // Initial state: [0, 1, 2, 3], Final state: [3, 0]
  auto c0 = (CKModelExposingComponent *)[[[change state] objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]] rootLayout].component();
  auto c1 = (CKModelExposingComponent *)[[[change state] objectAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]] rootLayout].component();
  XCTAssertEqualObjects(c0.model, @3);
  XCTAssertEqualObjects(c1.model, @0);
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
