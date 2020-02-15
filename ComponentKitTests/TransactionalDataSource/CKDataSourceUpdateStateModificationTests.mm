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

#import <ComponentKit/CKCompositeComponent.h>
#import <ComponentKit/CKComponentLayout.h>
#import <ComponentKit/CKComponentProvider.h>
#import <ComponentKit/CKComponentScope.h>
#import <ComponentKit/CKComponentScopeRoot.h>
#import <ComponentKit/CKComponentSubclass.h>
#import <ComponentKit/CKDataSourceAppliedChanges.h>
#import <ComponentKit/CKDataSourceChange.h>
#import <ComponentKit/CKDataSourceItem.h>
#import <ComponentKit/CKDataSourceState.h>
#import <ComponentKit/CKDataSourceUpdateStateModification.h>

#import <ComponentKitTestHelpers/CKLifecycleTestComponent.h>

#import "CKDataSourceStateTestHelpers.h"

static NSString *const kTestStateForLifecycleComponent = @"kTestStateForLifecycleComponent";

@interface CKStatefulTestComponent : CKCompositeComponent

+ (instancetype)new;

@property (nonatomic, readonly) NSString *state;
@property (nonatomic, readonly) CKLifecycleTestComponent *lifecycleComponent;
@end

@implementation CKStatefulTestComponent

+ (instancetype)new
{
  CKComponentScope scope(self);
  CKLifecycleTestComponent *lifecycleComponent = [scope.state() isEqual:kTestStateForLifecycleComponent]
  ? [CKLifecycleTestComponent newWithView:{} size:{}]
  : nil;
  const auto c = [super newWithComponent:lifecycleComponent ?: CK::ComponentBuilder()
                                                                   .build()];
  if (c) {
    c->_state = scope.state();
    c->_lifecycleComponent = lifecycleComponent;
  }
  return c;
}

@end

@interface CKDataSourceUpdateStateModificationTests : XCTestCase <CKComponentStateListener>
@end

@implementation CKDataSourceUpdateStateModificationTests
{
  CKComponentStateUpdatesMap _pendingStateUpdates;
}

static CKComponent *ComponentProvider(id<NSObject> model, id<NSObject> context)
{
  return [CKStatefulTestComponent new];
}

- (void)componentScopeHandle:(CKComponentScopeHandle *)handle
              rootIdentifier:(CKComponentScopeRootIdentifier)rootIdentifier
       didReceiveStateUpdate:(id (^)(id))stateUpdate
                    metadata:(const CKStateUpdateMetadata &)metadata
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
  CKDataSourceState *originalState = CKDataSourceTestState(ComponentProvider, self, 1, 5);

  NSIndexPath *ip = [NSIndexPath indexPathForItem:2 inSection:0];
  CKDataSourceItem *item = [originalState objectAtIndexPath:ip];
  CKComponent *c = (CKComponent *)[item rootLayout].component();
  [c updateState:^(id state){return @"hello";} mode:CKUpdateModeSynchronous];

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
  CKDataSourceState *originalState = CKDataSourceTestState(ComponentProvider, self, 1, 1);

  NSIndexPath *ip = [NSIndexPath indexPathForItem:0 inSection:0];
  CKDataSourceItem *item = [originalState objectAtIndexPath:ip];
  CKComponent *c = (CKComponent *)[item rootLayout].component();
  [c updateState:^(id state){return @"hello";} mode:CKUpdateModeSynchronous];

  CKDataSourceUpdateStateModification *updateStateModification =
  [[CKDataSourceUpdateStateModification alloc] initWithStateUpdates:_pendingStateUpdates];

  CKDataSourceChange *change = [updateStateModification changeFromState:originalState];

  NSString *updatedComponentState =
  [(CKStatefulTestComponent *)[[[change state] objectAtIndexPath:ip] rootLayout].component() state];

  XCTAssertEqualObjects(updatedComponentState, @"hello");
}

- (void)testCoalescesMultipleStateUpdates
{
  CKDataSourceState *originalState = CKDataSourceTestState(ComponentProvider, self, 1, 1);

  NSIndexPath *ip = [NSIndexPath indexPathForItem:0 inSection:0];
  CKDataSourceItem *item = [originalState objectAtIndexPath:ip];
  CKComponent *c = (CKComponent *)[item rootLayout].component();
  [c updateState:^(NSString *state){return @"hello";} mode:CKUpdateModeSynchronous];
  [c updateState:^(NSString *state){return [state stringByAppendingString:@" world"];} mode:CKUpdateModeSynchronous];

  CKDataSourceUpdateStateModification *updateStateModification =
  [[CKDataSourceUpdateStateModification alloc] initWithStateUpdates:_pendingStateUpdates];

  CKDataSourceChange *change = [updateStateModification changeFromState:originalState];

  NSString *updatedComponentState =
  [(CKStatefulTestComponent *)[[[change state] objectAtIndexPath:ip] rootLayout].component() state];

  XCTAssertEqualObjects(updatedComponentState, @"hello world");
}

- (void)testReturnsInvalidComponentControllers
{
  const auto originalState = CKDataSourceTestState(ComponentProvider, self, 1, 1);

  const auto ip = [NSIndexPath indexPathForItem:0 inSection:0];
  CKComponent *c = (CKComponent *)[[originalState objectAtIndexPath:ip] rootLayout].component();
  [c updateState:^(NSString *state){return kTestStateForLifecycleComponent;} mode:CKUpdateModeSynchronous];

  auto updateStateModification = [[CKDataSourceUpdateStateModification alloc] initWithStateUpdates:_pendingStateUpdates];
  auto change = [updateStateModification changeFromState:originalState];

  const auto componentController = ((CKStatefulTestComponent *)[[change.state objectAtIndexPath:ip] rootLayout].component()).lifecycleComponent.controller;
  CKComponent *c2 = (CKComponent *)[[change.state objectAtIndexPath:ip] rootLayout].component();
  [c2 updateState:^(NSString *state){return @"";} mode:CKUpdateModeSynchronous];

  updateStateModification = [[CKDataSourceUpdateStateModification alloc] initWithStateUpdates:_pendingStateUpdates];
  change = [updateStateModification changeFromState:change.state];

  XCTAssertEqual(change.invalidComponentControllers.firstObject, componentController,
                 @"Invalid component controller should be returned because component is removed from hierarchy.");
}

@end
