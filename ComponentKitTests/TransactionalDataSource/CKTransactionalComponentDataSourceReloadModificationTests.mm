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
#import <ComponentKit/CKTransactionalComponentDataSourceAppliedChangesInternal.h>
#import <ComponentKit/CKTransactionalComponentDataSourceChange.h>
#import <ComponentKit/CKTransactionalComponentDataSourceItem.h>
#import <ComponentKit/CKTransactionalComponentDataSourceReloadModification.h>
#import <ComponentKit/CKTransactionalComponentDataSourceState.h>

#import "CKTransactionalComponentDataSourceStateTestHelpers.h"

// Some tests manipulate this to simulate global singleton state changing.
static u_int32_t globalState = 0;

@interface CKTestGlobalStateComponent : CKComponent
@property (nonatomic, readonly) u_int32_t globalStateAtTimeOfCreation;
@end

@implementation CKTestGlobalStateComponent
+ (instancetype)new
{
  CKTestGlobalStateComponent *c = [super newWithView:{} size:{}];
  if (c) {
    c->_globalStateAtTimeOfCreation = globalState;
  }
  return c;
}
@end

@interface CKTransactionalComponentDataSourceReloadModificationTests : XCTestCase <CKComponentProvider>
@end

@implementation CKTransactionalComponentDataSourceReloadModificationTests

+ (CKComponent *)componentForModel:(id<NSObject>)model context:(id<NSObject>)context
{
  return [CKTestGlobalStateComponent new];
}

- (void)testAppliedChangesIncludesUpdatedIndexPathsForEveryItem
{
  CKTransactionalComponentDataSourceState *originalState = CKTransactionalComponentDataSourceTestState([self class], nil, 5, 5);

  CKTransactionalComponentDataSourceReloadModification *reloadModification =
  [[CKTransactionalComponentDataSourceReloadModification alloc] initWithUserInfo:nil];

  CKTransactionalComponentDataSourceChange *change = [reloadModification changeFromState:originalState];

  CKTransactionalComponentDataSourceAppliedChanges *expectedAppliedChanges =
  [[CKTransactionalComponentDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:CKTestIndexPaths(5, 5)
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
  CKTransactionalComponentDataSourceState *originalState = CKTransactionalComponentDataSourceTestState([self class], nil, 1, 1);
  NSDictionary *userInfo = @{@"foo": @"bar"};
  CKTransactionalComponentDataSourceReloadModification *reloadModification =
  [[CKTransactionalComponentDataSourceReloadModification alloc] initWithUserInfo:userInfo];
  CKTransactionalComponentDataSourceChange *change = [reloadModification changeFromState:originalState];
  XCTAssertEqualObjects([[change appliedChanges] userInfo], userInfo);
}

- (void)testActuallyRegeneratesComponents
{
  CKTransactionalComponentDataSourceState *originalState = CKTransactionalComponentDataSourceTestState([self class], nil, 1, 1);
  CKTransactionalComponentDataSourceReloadModification *reloadModification =
  [[CKTransactionalComponentDataSourceReloadModification alloc] initWithUserInfo:nil];

  u_int32_t newGlobalState = arc4random();
  globalState = newGlobalState;
  CKTransactionalComponentDataSourceChange *change = [reloadModification changeFromState:originalState];
  CKTransactionalComponentDataSourceItem *item =
  [[change state] objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
  CKTestGlobalStateComponent *component = (CKTestGlobalStateComponent *)[item layout].component;

  XCTAssertEqual(component.globalStateAtTimeOfCreation, newGlobalState);
}

@end
