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

#import "CKComponentLayout.h"
#import "CKComponentProvider.h"
#import "CKComponentScope.h"
#import "CKComponentScopeRoot.h"
#import "CKComponentSubclass.h"
#import "CKTransactionalComponentDataSourceAppliedChangesInternal.h"
#import "CKTransactionalComponentDataSourceChange.h"
#import "CKTransactionalComponentDataSourceItem.h"
#import "CKTransactionalComponentDataSourceState.h"
#import "CKTransactionalComponentDataSourceStateTestHelpers.h"
#import "CKTransactionalComponentDataSourceUpdateStateModification.h"

@interface CKStatefulTestComponent : CKComponent
@property (nonatomic, readonly) NSString *state;
@end

@implementation CKStatefulTestComponent

+ (instancetype)new
{
  CKComponentScope scope(self);
  CKStatefulTestComponent *c = [super new];
  if (c) {
    c->_state = scope.state();
  }
  return c;
}

@end

@interface CKTransactionalComponentDataSourceUpdateStateModificationTests : XCTestCase <CKComponentProvider, CKComponentStateListener>
@end

@implementation CKTransactionalComponentDataSourceUpdateStateModificationTests
{
  CKComponentStateUpdatesMap _pendingStateUpdates;
}

+ (CKComponent *)componentForModel:(id<NSObject>)model context:(id<NSObject>)context
{
  return [CKStatefulTestComponent new];
}

- (void)componentScopeHandleWithIdentifier:(CKComponentScopeHandleIdentifier)globalIdentifier
                            rootIdentifier:(CKComponentScopeRootIdentifier)rootIdentifier
                     didReceiveStateUpdate:(id (^)(id))stateUpdate
                     tryAsynchronousUpdate:(BOOL)tryAsynchronousUpdate
{
  _pendingStateUpdates[rootIdentifier].insert({globalIdentifier, stateUpdate});
}

- (void)tearDown
{
  _pendingStateUpdates.clear();
}

- (void)testAppliedChangesIncludesUpdatedIndexPathForAffectedComponent
{
  CKTransactionalComponentDataSourceState *originalState = CKTransactionalComponentDataSourceTestState([self class], self, 1, 5);

  NSIndexPath *ip = [NSIndexPath indexPathForItem:2 inSection:0];
  CKTransactionalComponentDataSourceItem *item = [originalState objectAtIndexPath:ip];
  [[item layout].component updateState:^(id state){return @"hello";}];

  CKTransactionalComponentDataSourceUpdateStateModification *updateStateModification =
  [[CKTransactionalComponentDataSourceUpdateStateModification alloc] initWithStateUpdates:_pendingStateUpdates];

  CKTransactionalComponentDataSourceChange *change = [updateStateModification changeFromState:originalState];

  CKTransactionalComponentDataSourceAppliedChanges *expectedAppliedChanges =
  [[CKTransactionalComponentDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:ip]
                                                                    removedIndexPaths:nil
                                                                      removedSections:nil
                                                                      movedIndexPaths:nil
                                                                     insertedSections:nil
                                                                   insertedIndexPaths:nil
                                                                             userInfo:nil];

  XCTAssertEqualObjects([change appliedChanges], expectedAppliedChanges);
}

- (void)testExposesComponentWithNewState
{
  CKTransactionalComponentDataSourceState *originalState = CKTransactionalComponentDataSourceTestState([self class], self, 1, 1);

  NSIndexPath *ip = [NSIndexPath indexPathForItem:0 inSection:0];
  CKTransactionalComponentDataSourceItem *item = [originalState objectAtIndexPath:ip];
  [[item layout].component updateState:^(id state){return @"hello";}];

  CKTransactionalComponentDataSourceUpdateStateModification *updateStateModification =
  [[CKTransactionalComponentDataSourceUpdateStateModification alloc] initWithStateUpdates:_pendingStateUpdates];

  CKTransactionalComponentDataSourceChange *change = [updateStateModification changeFromState:originalState];

  NSString *updatedComponentState =
  [(CKStatefulTestComponent *)[[[change state] objectAtIndexPath:ip] layout].component state];

  XCTAssertEqualObjects(updatedComponentState, @"hello");
}

- (void)testCoalescesMultipleStateUpdates
{
  CKTransactionalComponentDataSourceState *originalState = CKTransactionalComponentDataSourceTestState([self class], self, 1, 1);

  NSIndexPath *ip = [NSIndexPath indexPathForItem:0 inSection:0];
  CKTransactionalComponentDataSourceItem *item = [originalState objectAtIndexPath:ip];
  [[item layout].component updateState:^(NSString *state){return @"hello";}];
  [[item layout].component updateState:^(NSString *state){return [state stringByAppendingString:@" world"];}];

  CKTransactionalComponentDataSourceUpdateStateModification *updateStateModification =
  [[CKTransactionalComponentDataSourceUpdateStateModification alloc] initWithStateUpdates:_pendingStateUpdates];

  CKTransactionalComponentDataSourceChange *change = [updateStateModification changeFromState:originalState];

  NSString *updatedComponentState =
  [(CKStatefulTestComponent *)[[[change state] objectAtIndexPath:ip] layout].component state];

  XCTAssertEqualObjects(updatedComponentState, @"hello world");
}

@end
