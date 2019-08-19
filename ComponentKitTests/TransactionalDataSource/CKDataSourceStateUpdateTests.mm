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
#import <ComponentKit/CKDataSourceListener.h>

#import "CKStateExposingComponent.h"
#import "CKDataSourceStateTestHelpers.h"

@interface CKDataSourceStateUpdateTests : XCTestCase <CKDataSourceListener>
@end

@implementation CKDataSourceStateUpdateTests
{
  id<CKDataSourceProtocol> _dataSource;
  CKDataSourceState *_state;
}

static CKComponent *ComponentProvider(id<NSObject> model, id<NSObject> context)
{
  return [CKStateExposingComponent new];
}

- (void)testSynchronousStateUpdateResultsInUpdatedComponent
{
  [self _testSynchronousStateUpdateResultsInUpdatedComponentWithDataSourceClass:[CKDataSource class]];
}

- (void)_testSynchronousStateUpdateResultsInUpdatedComponentWithDataSourceClass:(Class<CKDataSourceProtocol>)dataSourceClass
{
  _dataSource = CKComponentTestDataSource(dataSourceClass, ComponentProvider, self);
  NSString *const newState = @"new state";
  [self _updateStates:@[newState] mode:CKUpdateModeSynchronous];

  // Even for synchronous updates, the update is deferred to the end of the run loop, so we must spin the runloop.
  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL{
    return [self _isEqualState:newState];
  }));
}

- (void)testMultipleSynchronousStateUpdatesAreCoalesced
{
  [self _testMultipleSynchronousStateUpdatesAreCoalescedWithDataSourceClass:[CKDataSource class]];
}

- (void)_testMultipleSynchronousStateUpdatesAreCoalescedWithDataSourceClass:(Class<CKDataSourceProtocol>)dataSourceClass
{
  _dataSource = CKComponentTestDataSource(dataSourceClass, ComponentProvider, self);
  NSArray<id> *const newStates = @[@1, @2, @3];
  [self _updateStates:newStates mode:CKUpdateModeSynchronous];

  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL{
    return [self _isEqualState:newStates.lastObject];
  }));
}

- (void)testAsynchronousStateUpdateResultsInUpdatedComponent
{
  [self _testAsynchronousStateUpdateResultsInUpdatedComponentWithDataSourceClass:[CKDataSource class]];
}

- (void)_testAsynchronousStateUpdateResultsInUpdatedComponentWithDataSourceClass:(Class<CKDataSourceProtocol>)dataSourceClass
{
  _dataSource = CKComponentTestDataSource(dataSourceClass, ComponentProvider, self);
  NSString *const newState = @"new state";
  [self _updateStates:@[newState] mode:CKUpdateModeAsynchronous];

  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL{
    return [self _isEqualState:newState];
  }));
}

- (void)testStateUpdatesAreProcessedInTheOrderTheyWereEnqueued
{
  [self _testStateUpdatesAreProcessedInTheOrderTheyWereEnqueuedWithDataSourceClass:[CKDataSource class]];
}

- (void)_testStateUpdatesAreProcessedInTheOrderTheyWereEnqueuedWithDataSourceClass:(Class<CKDataSourceProtocol>)dataSourceClass
{
  _dataSource = CKComponentTestDataSource(dataSourceClass, ComponentProvider, self);
  NSArray<id> *const newStates = @[@"NewState", @"NewStateUpdate1", @"NewStateUpdate1Update2"];
  [self _updateStates:newStates mode:CKUpdateModeSynchronous];

  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL{
    return [self _isEqualState:newStates.lastObject];
  }));
}

#pragma mark - CKDataSourceListener

- (void)componentDataSource:(id<CKDataSourceProtocol>)dataSource
     didModifyPreviousState:(CKDataSourceState *)previousState
                  withState:(CKDataSourceState *)state
          byApplyingChanges:(CKDataSourceAppliedChanges *)changes
{
  _state = state;
}

- (void)componentDataSource:(id<CKDataSourceProtocol>)dataSource
 willApplyDeferredChangeset:(CKDataSourceChangeset *)deferredChangeset
{
}

#pragma mark - Helpers

- (void)_updateStates:(NSArray<id> *)states mode:(CKUpdateMode)mode
{
  CKRunRunLoopUntilBlockIsTrue(^BOOL{
    return _state != nil;
  });
  CKDataSourceItem *const item = [_state objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
  CKComponent *const component = [item rootLayout].component();
  for (id state in states) {
    [component updateState:^(id oldState){return state;} mode:mode];
  }
}

- (BOOL)_isEqualState:(id)state
{
  CKDataSourceItem *updatedItem = [_state objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
  return updatedItem
  ? [((CKStateExposingComponent *)[updatedItem rootLayout].component()).state isEqual:state]
  : NO;
}

@end
