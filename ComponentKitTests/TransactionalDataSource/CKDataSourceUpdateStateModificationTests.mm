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

#import <ComponentKit/CKComponentLayout.h>
#import <ComponentKit/CKComponentProvider.h>
#import <ComponentKit/CKComponentScope.h>
#import <ComponentKit/CKComponentScopeRoot.h>
#import <ComponentKit/CKComponentSubclass.h>
#import <ComponentKit/CKDataSourceAppliedChanges.h>
#import <ComponentKit/CKDataSourceChange.h>
#import <ComponentKit/CKDataSourceItem.h>
#import <ComponentKit/CKDataSourceState.h>

#import "CKDataSourceStateTestHelpers.h"
#import "CKDataSourceUpdateStateModification.h"

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

@interface CKDataSourceUpdateStateModificationTests : XCTestCase <CKComponentProvider, CKComponentStateListener>
@end

@implementation CKDataSourceUpdateStateModificationTests
{
  CKComponentStateUpdatesMap _pendingStateUpdates;
}

+ (CKComponent *)componentForModel:(id<NSObject>)model context:(id<NSObject>)context
{
  return [CKStatefulTestComponent new];
}

- (void)componentScopeHandle:(CKComponentScopeHandle *)handle
              rootIdentifier:(CKComponentScopeRootIdentifier)rootIdentifier
       didReceiveStateUpdate:(id (^)(id))stateUpdate
                    metadata:(const CKStateUpdateMetadata)metadata
                        mode:(CKUpdateMode)mode
{
  _pendingStateUpdates[rootIdentifier][handle].push_back(stateUpdate);
}

- (void)tearDown
{
  _pendingStateUpdates.clear();
  [super tearDown];
}

- (void)testAppliedChangesIncludesUpdatedIndexPathForAffectedComponent
{
  CKDataSourceState *originalState = CKDataSourceTestState([self class], self, 1, 5);

  NSIndexPath *ip = [NSIndexPath indexPathForItem:2 inSection:0];
  CKDataSourceItem *item = [originalState objectAtIndexPath:ip];
  [[item rootLayout].component() updateState:^(id state){return @"hello";} mode:CKUpdateModeSynchronous];

  CKDataSourceUpdateStateModification *updateStateModification =
  [[CKDataSourceUpdateStateModification alloc] initWithStateUpdates:_pendingStateUpdates];

  CKDataSourceChange *change = [updateStateModification changeFromState:originalState];

  const auto stateUpdatesForItem = _pendingStateUpdates.find([[item scopeRoot] globalIdentifier]);
  NSInteger globalIdentifier = (stateUpdatesForItem->second).begin()->first.globalIdentifier;
  CKDataSourceAppliedChanges *expectedAppliedChanges =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:ip]
                                                                    removedIndexPaths:nil
                                                                      removedSections:nil
                                                                      movedIndexPaths:nil
                                                                     insertedSections:nil
                                                                   insertedIndexPaths:nil
                                                                             userInfo:@{@"updatedComponentIdentifier":@(globalIdentifier)}];

  XCTAssertEqualObjects([change appliedChanges], expectedAppliedChanges);
}

- (void)testExposesComponentWithNewState
{
  CKDataSourceState *originalState = CKDataSourceTestState([self class], self, 1, 1);

  NSIndexPath *ip = [NSIndexPath indexPathForItem:0 inSection:0];
  CKDataSourceItem *item = [originalState objectAtIndexPath:ip];
  [[item rootLayout].component() updateState:^(id state){return @"hello";} mode:CKUpdateModeSynchronous];

  CKDataSourceUpdateStateModification *updateStateModification =
  [[CKDataSourceUpdateStateModification alloc] initWithStateUpdates:_pendingStateUpdates];

  CKDataSourceChange *change = [updateStateModification changeFromState:originalState];

  NSString *updatedComponentState =
  [(CKStatefulTestComponent *)[[[change state] objectAtIndexPath:ip] rootLayout].component() state];

  XCTAssertEqualObjects(updatedComponentState, @"hello");
}

- (void)testCoalescesMultipleStateUpdates
{
  CKDataSourceState *originalState = CKDataSourceTestState([self class], self, 1, 1);

  NSIndexPath *ip = [NSIndexPath indexPathForItem:0 inSection:0];
  CKDataSourceItem *item = [originalState objectAtIndexPath:ip];
  [[item rootLayout].component() updateState:^(NSString *state){return @"hello";} mode:CKUpdateModeSynchronous];
  [[item rootLayout].component() updateState:^(NSString *state){return [state stringByAppendingString:@" world"];} mode:CKUpdateModeSynchronous];

  CKDataSourceUpdateStateModification *updateStateModification =
  [[CKDataSourceUpdateStateModification alloc] initWithStateUpdates:_pendingStateUpdates];

  CKDataSourceChange *change = [updateStateModification changeFromState:originalState];

  NSString *updatedComponentState =
  [(CKStatefulTestComponent *)[[[change state] objectAtIndexPath:ip] rootLayout].component() state];

  XCTAssertEqualObjects(updatedComponentState, @"hello world");
}

@end
