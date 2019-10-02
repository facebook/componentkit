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
#import <ComponentKit/CKDataSourceInternal.h>
#import <ComponentKit/CKDataSourceItem.h>
#import <ComponentKit/CKDataSourceState.h>
#import <ComponentKit/CKDataSourceListener.h>

#import "CKStateExposingComponent.h"
#import "CKDataSourceStateTestHelpers.h"

@interface CKDataSourceStateUpdateTests : XCTestCase <CKDataSourceListener>
@end

@implementation CKDataSourceStateUpdateTests
{
  CKDataSource *_dataSource;
  CKDataSourceState *_state;
}

static CKComponent *ComponentProvider(id<NSObject> model, id<NSObject> context)
{
  return [CKStateExposingComponent new];
}

- (void)testSynchronousStateUpdateResultsInUpdatedComponent
{
  _dataSource = CKComponentTestDataSource(ComponentProvider, self);
  NSString *const newState = @"new state";
  [self _updateStates:@[newState] mode:CKUpdateModeSynchronous];

  // Even for synchronous updates, the update is deferred to the end of the run loop, so we must spin the runloop.
  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL{
    return [self _isEqualState:newState];
  }));
}

- (void)testMultipleSynchronousStateUpdatesAreCoalesced
{
  _dataSource = CKComponentTestDataSource(ComponentProvider, self);
  NSArray<id> *const newStates = @[@1, @2, @3];
  [self _updateStates:newStates mode:CKUpdateModeSynchronous];

  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL{
    return [self _isEqualState:newStates.lastObject];
  }));
}

- (void)testAsynchronousStateUpdateResultsInUpdatedComponent
{
  _dataSource = CKComponentTestDataSource(ComponentProvider, self);
  NSString *const newState = @"new state";
  [self _updateStates:@[newState] mode:CKUpdateModeAsynchronous];

  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL{
    return [self _isEqualState:newState];
  }));
}

- (void)testStateUpdatesAreProcessedInTheOrderTheyWereEnqueued
{
  _dataSource = CKComponentTestDataSource(ComponentProvider, self);
  NSArray<id> *const newStates = @[@"NewState", @"NewStateUpdate1", @"NewStateUpdate1Update2"];
  [self _updateStates:newStates mode:CKUpdateModeSynchronous];

  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL{
    return [self _isEqualState:newStates.lastObject];
  }));
}

- (void)testStateUpdatesAreNotProcessedIfShouldPauseStateUpdatesIsYes
{
  _dataSource = CKComponentTestDataSource(ComponentProvider, self);
  _dataSource.shouldPauseStateUpdates = YES;
  const auto state1 = _dataSource.state;
  [self _updateStates:@[@"Test"] mode:CKUpdateModeSynchronous];
  XCTAssertEqual(_dataSource.state, state1);
  _dataSource.shouldPauseStateUpdates = NO;
  XCTAssertNotEqual(_dataSource.state, state1);
}

#pragma mark - CKDataSourceListener

- (void)dataSource:(CKDataSource *)dataSource
     didModifyPreviousState:(CKDataSourceState *)previousState
                  withState:(CKDataSourceState *)state
          byApplyingChanges:(CKDataSourceAppliedChanges *)changes
{
  _state = state;
}

- (void)dataSource:(CKDataSource *)dataSource
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
  CKComponent *const component = (CKComponent *)[item rootLayout].component();
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
