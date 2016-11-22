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
#import <ComponentKit/CKComponentMemoizer.h>
#import <ComponentKit/CKTransactionalComponentDataSourceAppliedChanges.h>
#import <ComponentKit/CKTransactionalComponentDataSourceChange.h>
#import <ComponentKit/CKTransactionalComponentDataSourceChangeset.h>
#import <ComponentKit/CKTransactionalComponentDataSourceItem.h>
#import <ComponentKit/CKTransactionalComponentDataSourceChangesetModification.h>
#import <ComponentKit/CKTransactionalComponentDataSourceState.h>

#import "CKTransactionalComponentDataSourceStateTestHelpers.h"

@interface CKMemoizableComponent : CKComponent
+ (instancetype)newWithModel:(id)model;
@end

@implementation CKMemoizableComponent {
  id _model;
}

+ (instancetype)newWithModel:(id)model
{
  CKMemoizationKey key = CKMakeTupleMemoizationKey(model);
  return CKMemoize(key, ^id{
    CKMemoizableComponent *c = [super new];
    if (c) {
      c->_model = model;
    }
    return c;
  });
}

@end


@interface CKTransactionalComponentDataSourceChangesetMemoizationTests : XCTestCase <CKComponentProvider>
@end

@implementation CKTransactionalComponentDataSourceChangesetMemoizationTests

+ (CKComponent *)componentForModel:(id<NSObject>)model context:(id<NSObject>)context
{
  return [CKMemoizableComponent newWithModel:model];
}

- (void)testThatMemoizableComponentsAreMemoizedDuringUpdates
{
  CKTransactionalComponentDataSourceState *originalState = CKTransactionalComponentDataSourceTestState([self class], nil, 2, 2);
  CKTransactionalComponentDataSourceChangeset *changeset =
  [[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withUpdatedItems:@{[NSIndexPath indexPathForItem:0 inSection:0]: @0}]
   build];
  CKTransactionalComponentDataSourceChangesetModification *changesetModification =
  [[CKTransactionalComponentDataSourceChangesetModification alloc] initWithChangeset:changeset
                                                                       stateListener:nil
                                                                            userInfo:nil];
  CKTransactionalComponentDataSourceChange *change = [changesetModification changeFromState:originalState];
  
  const CKComponentLayout original = [[originalState objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]] layout];
  const CKComponentLayout memoized = [[[change state] objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]] layout];
  XCTAssertEqualObjects(original.component, memoized.component, @"Should return the original component the second time");
}

- (void)testThatMemoizableComponentsAreMemoizedThroughMoves
{
  CKTransactionalComponentDataSourceState *originalState = CKTransactionalComponentDataSourceTestState([self class], nil, 2, 2);
  CKTransactionalComponentDataSourceChangeset *changeset =
  [[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withMovedItems:@{[NSIndexPath indexPathForItem:0 inSection:0]: [NSIndexPath indexPathForItem:0 inSection:1]}]
   build];
  CKTransactionalComponentDataSourceChangesetModification *changesetModification =
  [[CKTransactionalComponentDataSourceChangesetModification alloc] initWithChangeset:changeset
                                                                       stateListener:nil
                                                                            userInfo:nil];
  CKTransactionalComponentDataSourceChange *change = [changesetModification changeFromState:originalState];
  
  const CKComponentLayout original = [[originalState objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]] layout];
  const CKComponentLayout memoized = [[[change state] objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:1]] layout];
  XCTAssertEqualObjects(original.component, memoized.component, @"Should return the original component the second time");
}

- (void)testThatMemoizableComponentsAreNotMemoizedIfDeletedAndInserted
{
  CKTransactionalComponentDataSourceState *originalState = CKTransactionalComponentDataSourceTestState([self class], nil, 2, 2);
  CKTransactionalComponentDataSourceChangeset *changeset =
  [[[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
     withRemovedItems:[NSSet setWithObject:[NSIndexPath indexPathForItem:0 inSection:0]]]
    withInsertedItems:@{[NSIndexPath indexPathForItem:0 inSection:0]: @0}]
   build];
  CKTransactionalComponentDataSourceChangesetModification *changesetModification =
  [[CKTransactionalComponentDataSourceChangesetModification alloc] initWithChangeset:changeset
                                                                       stateListener:nil
                                                                            userInfo:nil];
  CKTransactionalComponentDataSourceChange *change = [changesetModification changeFromState:originalState];
  
  const CKComponentLayout original = [[originalState objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]] layout];
  const CKComponentLayout modified = [[[change state] objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]] layout];
  XCTAssertNotEqualObjects(original.component, modified.component, @"Should return the original component the second time");
}

- (void)testThatMemoizableComponentsAreNotMemoizedWithDifferentKeys
{
  CKTransactionalComponentDataSourceState *originalState = CKTransactionalComponentDataSourceTestState([self class], nil, 2, 2);
  CKTransactionalComponentDataSourceChangeset *changeset =
  [[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withUpdatedItems:@{[NSIndexPath indexPathForItem:0 inSection:0]: @20}]
   build];
  CKTransactionalComponentDataSourceChangesetModification *changesetModification =
  [[CKTransactionalComponentDataSourceChangesetModification alloc] initWithChangeset:changeset
                                                                       stateListener:nil
                                                                            userInfo:nil];
  CKTransactionalComponentDataSourceChange *change = [changesetModification changeFromState:originalState];
  
  const CKComponentLayout original = [[originalState objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]] layout];
  const CKComponentLayout modified = [[[change state] objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]] layout];
  XCTAssertNotEqualObjects(original.component, modified.component, @"Should return a new component the second time");
}

- (void)testThatMemoizerStateIsCopied
{
  CKTransactionalComponentDataSourceState *originalState = CKTransactionalComponentDataSourceTestState([self class], nil, 1, 1);
  CKTransactionalComponentDataSourceChangeset *changeset =
  [[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withUpdatedItems:@{[NSIndexPath indexPathForItem:0 inSection:0]: @20}]
   build];
  CKTransactionalComponentDataSourceChangesetModification *changesetModification =
  [[CKTransactionalComponentDataSourceChangesetModification alloc] initWithChangeset:changeset
                                                                       stateListener:nil
                                                                            userInfo:nil];
  
  CKTransactionalComponentDataSourceChange *discardedChange = [changesetModification changeFromState:originalState];
  
  CKTransactionalComponentDataSourceChange *firstChange = [changesetModification changeFromState:originalState];
  CKTransactionalComponentDataSourceChange *secondChange = [changesetModification changeFromState:[firstChange state]];
  
  const CKComponentLayout discarded = [[[discardedChange state] objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]] layout];
  const CKComponentLayout second = [[[secondChange state] objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]] layout];
  XCTAssertNotEqualObjects(second.component, discarded.component, @"The second change should not have any knowledge of the discarded change because changes can occur concurrently");
}

@end
