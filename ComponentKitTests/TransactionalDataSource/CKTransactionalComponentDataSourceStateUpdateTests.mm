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

#import <ComponentKitTestHelpers/CKTestRunLoopRunning.h>

#import <ComponentKit/CKComponentInternal.h>
#import <ComponentKit/CKComponentSubclass.h>
#import <ComponentKit/CKComponentLayout.h>
#import <ComponentKit/CKComponentProvider.h>
#import <ComponentKit/CKTransactionalComponentDataSource.h>
#import <ComponentKit/CKTransactionalComponentDataSourceItem.h>
#import <ComponentKit/CKTransactionalComponentDataSourceState.h>

#import "CKStateExposingComponent.h"
#import "CKTransactionalComponentDataSourceStateTestHelpers.h"

@interface CKTransactionalComponentDataSourceStateUpdateTests : XCTestCase <CKComponentProvider>
@end

@implementation CKTransactionalComponentDataSourceStateUpdateTests

+ (CKComponent *)componentForModel:(id<NSObject>)model context:(id<NSObject>)context
{
  return [CKStateExposingComponent new];
}

- (void)testSynchronousStateUpdateResultsInUpdatedComponent
{
  CKTransactionalComponentDataSource *ds = CKTransactionalComponentTestDataSource([self class]);
  CKTransactionalComponentDataSourceItem *item = [[ds state] objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
  [[item layout].component updateState:^(id oldState){return @"new state";} mode:CKUpdateModeSynchronous];

  // Even for synchronous updates, the update is deferred to the end of the run loop, so we must spin the runloop.
  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL{
    CKTransactionalComponentDataSourceItem *updatedItem = [[ds state] objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    return [((CKStateExposingComponent *)[updatedItem layout].component).state isEqual:@"new state"];
  }));
}

- (void)testMultipleSynchronousStateUpdatesAreCoalesced
{
  CKTransactionalComponentDataSource *ds = CKTransactionalComponentTestDataSource([self class]);
  CKTransactionalComponentDataSourceItem *item = [[ds state] objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
  NSNumber *originalState = ((CKStateExposingComponent *)[item layout].component).state;
  [[item layout].component updateState:^(NSNumber *oldState){return @([oldState unsignedIntegerValue] + 1);} mode:CKUpdateModeSynchronous];
  [[item layout].component updateState:^(NSNumber *oldState){return @([oldState unsignedIntegerValue] + 1);} mode:CKUpdateModeSynchronous];
  [[item layout].component updateState:^(NSNumber *oldState){return @([oldState unsignedIntegerValue] + 1);} mode:CKUpdateModeSynchronous];

  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL{
    CKTransactionalComponentDataSourceItem *updatedItem = [[ds state] objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    return [((CKStateExposingComponent *)[updatedItem layout].component).state isEqual:@([originalState unsignedIntegerValue] + 3)];
  }));
}

- (void)testAsynchronousStateUpdateResultsInUpdatedComponent
{
  CKTransactionalComponentDataSource *ds = CKTransactionalComponentTestDataSource([self class]);
  CKTransactionalComponentDataSourceItem *item = [[ds state] objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
  [[item layout].component updateState:^(id oldState){return @"new state";} mode:CKUpdateModeAsynchronous];

  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL{
    CKTransactionalComponentDataSourceItem *updatedItem = [[ds state] objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    return [((CKStateExposingComponent *)[updatedItem layout].component).state isEqual:@"new state"];
  }));
}

@end
