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
#import <ComponentKit/CKDataSource.h>
#import <ComponentKit/CKDataSourceItem.h>
#import <ComponentKit/CKDataSourceState.h>
#import <ComponentKit/CKThreadSafeDataSource.h>

#import "CKStateExposingComponent.h"
#import "CKDataSourceStateTestHelpers.h"

@interface CKDataSourceStateUpdateTests : XCTestCase <CKComponentProvider>
@end

@implementation CKDataSourceStateUpdateTests

+ (CKComponent *)componentForModel:(id<NSObject>)model context:(id<NSObject>)context
{
  return [CKStateExposingComponent new];
}

- (void)testSynchronousStateUpdateResultsInUpdatedComponent
{
  [self _testSynchronousStateUpdateResultsInUpdatedComponentWithDataSourceClass:[CKDataSource class]];
}

- (void)testSynchronousStateUpdateResultsInUpdatedComponentWithThreadSafeDataSource
{
  [self _testSynchronousStateUpdateResultsInUpdatedComponentWithDataSourceClass:[CKThreadSafeDataSource class]];
}

- (void)_testSynchronousStateUpdateResultsInUpdatedComponentWithDataSourceClass:(Class<CKDataSourceProtocol>)dataSourceClass
{
  CKDataSource *ds = CKComponentTestDataSource(dataSourceClass, [self class], nil);
  CKDataSourceItem *item = [[ds state] objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
  [[item rootLayout].component() updateState:^(id oldState){return @"new state";} mode:CKUpdateModeSynchronous];

  // Even for synchronous updates, the update is deferred to the end of the run loop, so we must spin the runloop.
  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL{
    CKDataSourceItem *updatedItem = [[ds state] objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    return [((CKStateExposingComponent *)[updatedItem rootLayout].component()).state isEqual:@"new state"];
  }));
}

- (void)testMultipleSynchronousStateUpdatesAreCoalesced
{
  [self _testMultipleSynchronousStateUpdatesAreCoalescedWithDataSourceClass:[CKDataSource class]];
}

- (void)testMultipleSynchronousStateUpdatesAreCoalescedWithThreadSafeDataSource
{
  [self _testMultipleSynchronousStateUpdatesAreCoalescedWithDataSourceClass:[CKThreadSafeDataSource class]];
}

- (void)_testMultipleSynchronousStateUpdatesAreCoalescedWithDataSourceClass:(Class<CKDataSourceProtocol>)dataSourceClass
{
  CKDataSource *ds = CKComponentTestDataSource(dataSourceClass, [self class], nil);
  CKDataSourceItem *item = [[ds state] objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
  NSNumber *originalState = ((CKStateExposingComponent *)[item rootLayout].component()).state;
  [[item rootLayout].component() updateState:^(NSNumber *oldState){return @([oldState unsignedIntegerValue] + 1);} mode:CKUpdateModeSynchronous];
  [[item rootLayout].component() updateState:^(NSNumber *oldState){return @([oldState unsignedIntegerValue] + 1);} mode:CKUpdateModeSynchronous];
  [[item rootLayout].component() updateState:^(NSNumber *oldState){return @([oldState unsignedIntegerValue] + 1);} mode:CKUpdateModeSynchronous];

  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL{
    CKDataSourceItem *updatedItem = [[ds state] objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    return [((CKStateExposingComponent *)[updatedItem rootLayout].component()).state isEqual:@([originalState unsignedIntegerValue] + 3)];
  }));
}

- (void)testAsynchronousStateUpdateResultsInUpdatedComponent
{
  [self _testAsynchronousStateUpdateResultsInUpdatedComponentWithDataSourceClass:[CKDataSource class]];
}

- (void)testAsynchronousStateUpdateResultsInUpdatedComponentWithThreadSafeDataSource
{
  [self _testAsynchronousStateUpdateResultsInUpdatedComponentWithDataSourceClass:[CKThreadSafeDataSource class]];
}

- (void)_testAsynchronousStateUpdateResultsInUpdatedComponentWithDataSourceClass:(Class<CKDataSourceProtocol>)dataSourceClass
{
  CKDataSource *ds = CKComponentTestDataSource(dataSourceClass, [self class], nil);
  CKDataSourceItem *item = [[ds state] objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
  [[item rootLayout].component() updateState:^(id oldState){return @"new state";} mode:CKUpdateModeAsynchronous];

  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL{
    CKDataSourceItem *updatedItem = [[ds state] objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    return [((CKStateExposingComponent *)[updatedItem rootLayout].component()).state isEqual:@"new state"];
  }));
}

- (void)testStateUpdatesAreProcessedInTheOrderTheyWereEnqueued
{
  [self _testStateUpdatesAreProcessedInTheOrderTheyWereEnqueuedWithDataSourceClass:[CKDataSource class]];
}

- (void)testStateUpdatesAreProcessedInTheOrderTheyWereEnqueuedWithThreadSafeDataSource
{
  [self _testStateUpdatesAreProcessedInTheOrderTheyWereEnqueuedWithDataSourceClass:[CKThreadSafeDataSource class]];
}

- (void)_testStateUpdatesAreProcessedInTheOrderTheyWereEnqueuedWithDataSourceClass:(Class<CKDataSourceProtocol>)dataSourceClass
{
  CKDataSource *ds = CKComponentTestDataSource(dataSourceClass, [self class], nil);
  CKDataSourceItem *item = [[ds state] objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];

  CKComponent *const component = item.rootLayout.component();
  [component updateState:^(NSNumber *oldState){return @"NewState"; } mode:CKUpdateModeSynchronous];
  [component updateState:^(NSString *oldState){return [NSMutableString stringWithFormat:@"%@Update1", oldState]; } mode:CKUpdateModeSynchronous];
  [component updateState:^(NSString *oldState){return [NSMutableString stringWithFormat:@"%@Update2", oldState]; } mode:CKUpdateModeSynchronous];

  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL{
    CKDataSourceItem *updatedItem = [[ds state] objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    return [((CKStateExposingComponent *)[updatedItem rootLayout].component()).state isEqual:@"NewStateUpdate1Update2"];
  }));
}

@end
