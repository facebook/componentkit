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
#import <ComponentKit/CKDataSourceItem.h>
#import <ComponentKit/CKDataSourceReloadModification.h>
#import <ComponentKit/CKDataSourceState.h>
#import <ComponentKitTestHelpers/CKLifecycleTestComponent.h>

#import "CKDataSourceStateTestHelpers.h"

// Some tests manipulate this to simulate global singleton state changing.
static u_int32_t globalState = 0;
static u_int32_t lifecycleComponentState = 1;

@interface CKTestGlobalStateComponent : CKCompositeComponent

+ (instancetype)new;

@property (nonatomic, readonly) u_int32_t globalStateAtTimeOfCreation;
@property (nonatomic, readonly) CKLifecycleTestComponent *lifecycleComponent;
@end

@implementation CKTestGlobalStateComponent
+ (instancetype)new
{
  CKLifecycleTestComponent *lifecycleComponent =
  globalState == lifecycleComponentState ? [CKLifecycleTestComponent newWithView:{} size:{}] : nil;
  const auto c = [super newWithComponent:lifecycleComponent ?: CK::ComponentBuilder()
                                                                   .build()];
  if (c) {
    c->_globalStateAtTimeOfCreation = globalState;
    c->_lifecycleComponent = lifecycleComponent;
  }
  return c;
}
@end

@interface CKDataSourceReloadModificationTests : XCTestCase
@end

@implementation CKDataSourceReloadModificationTests

static CKComponent *ComponentProvider(id<NSObject> model, id<NSObject> context)
{
  return [CKTestGlobalStateComponent new];
}

- (void)testAppliedChangesIncludesUpdatedIndexPathsForEveryItem
{
  CKDataSourceState *originalState = CKDataSourceTestState(ComponentProvider, nil, 5, 5);

  CKDataSourceReloadModification *reloadModification =
  [[CKDataSourceReloadModification alloc] initWithUserInfo:nil];

  CKDataSourceChange *change = [reloadModification changeFromState:originalState];

  CKDataSourceAppliedChanges *expectedAppliedChanges =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:CKTestIndexPaths(5, 5)
                                              removedIndexPaths:nil
                                                removedSections:nil
                                                movedIndexPaths:nil
                                               insertedSections:nil
                                             insertedIndexPaths:nil
                                                       userInfo:nil];

  XCTAssertEqualObjects([change appliedChanges], expectedAppliedChanges);
}

- (void)testAppliedChangesIncludesUserInfo
{
  CKDataSourceState *originalState = CKDataSourceTestState(ComponentProvider, nil, 1, 1);
  NSDictionary *userInfo = @{@"foo": @"bar"};
  CKDataSourceReloadModification *reloadModification =
  [[CKDataSourceReloadModification alloc] initWithUserInfo:userInfo];
  CKDataSourceChange *change = [reloadModification changeFromState:originalState];
  XCTAssertEqualObjects([[change appliedChanges] userInfo], userInfo);
}

- (void)testActuallyRegeneratesComponents
{
  CKDataSourceState *originalState = CKDataSourceTestState(ComponentProvider, nil, 1, 1);
  CKDataSourceReloadModification *reloadModification =
  [[CKDataSourceReloadModification alloc] initWithUserInfo:nil];

  u_int32_t newGlobalState = arc4random();
  globalState = newGlobalState;
  CKDataSourceChange *change = [reloadModification changeFromState:originalState];
  CKDataSourceItem *item =
  [[change state] objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
  CKTestGlobalStateComponent *component = (CKTestGlobalStateComponent *)[item rootLayout].component();

  XCTAssertEqual(component.globalStateAtTimeOfCreation, newGlobalState);
}

- (void)testReturnsInvalidComponentControllers
{
  globalState = lifecycleComponentState;
  const auto originalState = CKDataSourceTestState(ComponentProvider, nil, 1, 1);
  const auto item = [originalState objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
  const auto componentController = ((CKTestGlobalStateComponent *)[item rootLayout].component()).lifecycleComponent.controller;

  globalState = 0;
  const auto reloadModification = [[CKDataSourceReloadModification alloc] initWithUserInfo:nil];
  const auto change = [reloadModification changeFromState:originalState];

  XCTAssertEqual(change.invalidComponentControllers.firstObject, componentController,
                 @"Invalid component controller should be returned because component is removed from hierarchy.");
}

@end
