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

#import <ComponentKitTestHelpers/CKLifecycleTestComponent.h>
#import <ComponentKitTestHelpers/CKTestRunLoopRunning.h>

#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKComponentProvider.h>
#import <ComponentKit/CKComponentSubclass.h>
#import <ComponentKit/CKDataSource.h>
#import <ComponentKit/CKDataSourceAppliedChanges.h>
#import <ComponentKit/CKDataSourceChange.h>
#import <ComponentKit/CKDataSourceChangeset.h>
#import <ComponentKit/CKDataSourceConfiguration.h>
#import <ComponentKit/CKDataSourceItem.h>
#import <ComponentKit/CKDataSourceListener.h>
#import <ComponentKit/CKDataSourceState.h>
#import <ComponentKit/CKThreadSafeDataSource.h>
#import <ComponentKit/CKDataSourceProtocolInternal.h>
#import <ComponentKit/CKDataSourceChangesetModification.h>

#import "CKDataSourceStateTestHelpers.h"

@interface CKDataSourceTests : XCTestCase <CKComponentProvider, CKDataSourceAsyncListener>
@end

@implementation CKDataSourceTests
{
  NSMutableArray<CKDataSourceAppliedChanges *> *_announcedChanges;
  NSInteger _willGenerateChangeCounter;
  NSInteger _didGenerateChangeCounter;
  NSInteger _syncModificationStartCounter;
  CKDataSourceState *_state;
}

+ (CKComponent *)componentForModel:(id<NSObject>)model context:(id<NSObject>)context
{
  return [CKLifecycleTestComponent new];
}

- (void)setUp
{
  [super setUp];
  _announcedChanges = [NSMutableArray new];
}

- (void)tearDown
{
  [_announcedChanges removeAllObjects];
  _willGenerateChangeCounter = 0;
  _didGenerateChangeCounter = 0;
  _syncModificationStartCounter = 0;
  [super tearDown];
}

- (void)testDataSourceSynchronouslyInsertingItemsAnnouncesInsertion
{
  [self _testSynchronouslyInsertingItemsAnnouncesInsertionWithDataSourceClass:[CKDataSource class]];
}

- (void)testThreadSafeDataSourceSynchronouslyInsertingItemsAnnouncesInsertion
{
  [self _testSynchronouslyInsertingItemsAnnouncesInsertionWithDataSourceClass:[CKThreadSafeDataSource class]];
}

- (void)_testSynchronouslyInsertingItemsAnnouncesInsertionWithDataSourceClass:(Class<CKDataSourceProtocol>)dataSourceClass
{
  id<CKDataSourceProtocol> ds =
  [[(Class)dataSourceClass alloc] initWithConfiguration:
   [[CKDataSourceConfiguration alloc] initWithComponentProvider:[self class]
                                                        context:nil
                                                      sizeRange:{}]];
  [ds addListener:self];

  CKDataSourceChangeset *insertion =
  [[[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
     withInsertedSections:[NSIndexSet indexSetWithIndex:0]]
    withInsertedItems:@{[NSIndexPath indexPathForItem:0 inSection:0]: @1}]
   build];
  [ds applyChangeset:insertion mode:CKUpdateModeSynchronous userInfo:nil];

  CKDataSourceAppliedChanges *expectedAppliedChanges =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:nil
                                              removedIndexPaths:nil
                                                removedSections:nil
                                                movedIndexPaths:nil
                                               insertedSections:[NSIndexSet indexSetWithIndex:0]
                                             insertedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:0 inSection:0]]
                                                       userInfo:nil];


  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL{
    return [_announcedChanges.firstObject isEqual:expectedAppliedChanges];
  }));
  XCTAssertEqual(_syncModificationStartCounter, 1);
  XCTAssertEqual(_willGenerateChangeCounter, 0);
  XCTAssertEqual(_didGenerateChangeCounter, 0);
}

- (void)testDataSourceAsynchronouslyInsertingItemsAnnouncesInsertionAsynchronously
{
  [self _testAsynchronouslyInsertingItemsAnnouncesInsertionAsynchronouslyWithDataSourceClass:[CKDataSource class]];
}

- (void)testThreadSafeDataSourceAsynchronouslyInsertingItemsAnnouncesInsertionAsynchronously
{
  [self _testAsynchronouslyInsertingItemsAnnouncesInsertionAsynchronouslyWithDataSourceClass:[CKThreadSafeDataSource class]];
}

- (void)_testAsynchronouslyInsertingItemsAnnouncesInsertionAsynchronouslyWithDataSourceClass:(Class<CKDataSourceProtocol>)dataSourceClass
{
  id<CKDataSourceProtocol> ds =
  [[(Class)dataSourceClass alloc] initWithConfiguration:
   [[CKDataSourceConfiguration alloc] initWithComponentProvider:[self class]
                                                        context:nil
                                                      sizeRange:{}]];
  [ds addListener:self];

  CKDataSourceChangeset *insertion =
  [[[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
     withInsertedSections:[NSIndexSet indexSetWithIndex:0]]
    withInsertedItems:@{[NSIndexPath indexPathForItem:0 inSection:0]: @1}]
   build];
  [ds applyChangeset:insertion mode:CKUpdateModeAsynchronous userInfo:nil];

  CKDataSourceAppliedChanges *expectedAppliedChanges =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:nil
                                              removedIndexPaths:nil
                                                removedSections:nil
                                                movedIndexPaths:nil
                                               insertedSections:[NSIndexSet indexSetWithIndex:0]
                                             insertedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:0 inSection:0]]
                                                       userInfo:nil];

  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL(void){
    return [_announcedChanges.firstObject isEqual:expectedAppliedChanges];
  }));
  XCTAssertEqual(_syncModificationStartCounter, 0);
  XCTAssertEqual(_willGenerateChangeCounter, 1);
  XCTAssertEqual(_didGenerateChangeCounter, 1);
}

- (void)testDataSourceUpdatingConfigurationAnnouncesUpdate
{
  [self _testUpdatingConfigurationAnnouncesUpdateWithDataSourceClass:[CKDataSource class]];
}

- (void)testThreadSafeDataSourceUpdatingConfigurationAnnouncesUpdate
{
  [self _testUpdatingConfigurationAnnouncesUpdateWithDataSourceClass:[CKThreadSafeDataSource class]];
}

- (void)_testUpdatingConfigurationAnnouncesUpdateWithDataSourceClass:(Class<CKDataSourceProtocol>)dataSourceClass
{
  id<CKDataSourceProtocol> ds = CKComponentTestDataSource(dataSourceClass, [self class], self);

  CKDataSourceConfiguration *config =
  [[CKDataSourceConfiguration alloc] initWithComponentProvider:[self class]
                                                       context:@"new context"
                                                     sizeRange:{}];
  [ds updateConfiguration:config
                     mode:CKUpdateModeSynchronous
                 userInfo:nil];

  CKDataSourceAppliedChanges *expectedAppliedChanges =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:0 inSection:0]]
                                              removedIndexPaths:nil
                                                removedSections:nil
                                                movedIndexPaths:nil
                                               insertedSections:nil
                                             insertedIndexPaths:nil
                                                       userInfo:nil];

  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL(void){
    return _announcedChanges.count == 2 && [_announcedChanges[1] isEqual:expectedAppliedChanges];
  }));
  XCTAssertEqual([_state configuration], config);
  XCTAssertEqual(_syncModificationStartCounter, 2);
  XCTAssertEqual(_willGenerateChangeCounter, 0);
  XCTAssertEqual(_didGenerateChangeCounter, 0);
}

- (void)testDataSourceReloadingAnnouncesUpdate
{
  [self _testReloadingAnnouncesUpdateWithDataSourceClass:[CKDataSource class]];
}

- (void)testThreadSafeDataSourceReloadingAnnouncesUpdate
{
  [self _testReloadingAnnouncesUpdateWithDataSourceClass:[CKThreadSafeDataSource class]];
}

- (void)_testReloadingAnnouncesUpdateWithDataSourceClass:(Class<CKDataSourceProtocol>)dataSourceClass
{
  id<CKDataSourceProtocol> ds = CKComponentTestDataSource(dataSourceClass, [self class], self);
  [ds reloadWithMode:CKUpdateModeSynchronous userInfo:nil];

  CKDataSourceAppliedChanges *expectedAppliedChanges =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:0 inSection:0]]
                                              removedIndexPaths:nil
                                                removedSections:nil
                                                movedIndexPaths:nil
                                               insertedSections:nil
                                             insertedIndexPaths:nil
                                                       userInfo:nil];

  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL(void){
    return _announcedChanges.count == 2 && [_announcedChanges[1] isEqual:expectedAppliedChanges];
  }));
  XCTAssertEqual(_syncModificationStartCounter, 2);
  XCTAssertEqual(_willGenerateChangeCounter, 0);
  XCTAssertEqual(_didGenerateChangeCounter, 0);
}

- (void)testDataSourceSynchronousReloadCancelsPreviousAsynchronousReload
{
  id<CKDataSourceProtocol> ds = CKComponentTestDataSource([CKDataSource class], [self class], self);

  // The initial asynchronous reload should be canceled by the immediately subsequent synchronous reload.
  // We then request *another* async reload so that we can wait for it to complete and assert that the initial
  // async reload doesn't actually take effect after the synchronous reload.
  [ds reloadWithMode:CKUpdateModeAsynchronous userInfo:@{@"id": @1}];
  [ds reloadWithMode:CKUpdateModeSynchronous userInfo:@{@"id": @2}];
  [ds reloadWithMode:CKUpdateModeAsynchronous userInfo:@{@"id": @3}];

  CKDataSourceAppliedChanges *expectedAppliedChangesForSyncReload =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:0 inSection:0]]
                                              removedIndexPaths:nil
                                                removedSections:nil
                                                movedIndexPaths:nil
                                               insertedSections:nil
                                             insertedIndexPaths:nil
                                                       userInfo:@{@"id": @2}];
  CKDataSourceAppliedChanges *expectedAppliedChangesForSecondAsyncReload =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:0 inSection:0]]
                                              removedIndexPaths:nil
                                                removedSections:nil
                                                movedIndexPaths:nil
                                               insertedSections:nil
                                             insertedIndexPaths:nil
                                                       userInfo:@{@"id": @3}];
  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL{
    return _announcedChanges.count == 3
    && [_announcedChanges[1] isEqual:expectedAppliedChangesForSyncReload]
    && [_announcedChanges[2] isEqual:expectedAppliedChangesForSecondAsyncReload];
  }));
  XCTAssertEqual(_syncModificationStartCounter, 2);
}

- (void)testDataSourceDeallocatingDataSourceTriggersInvalidateOnMainThread
{
  [self _testDeallocatingDataSourceTriggersInvalidateOnMainThreadWithDataSourceClass:[CKDataSource class]];
}

- (void)testThreadSafeDataSourceDeallocatingDataSourceTriggersInvalidateOnMainThread
{
  [self _testDeallocatingDataSourceTriggersInvalidateOnMainThreadWithDataSourceClass:[CKThreadSafeDataSource class]];
}

- (void)_testDeallocatingDataSourceTriggersInvalidateOnMainThreadWithDataSourceClass:(Class<CKDataSourceProtocol>)dataSourceClass
{
  CKLifecycleTestComponentController *controller = nil;
  @autoreleasepool {
    // We dispatch empty operation on Data Source to background so that
    // DataSource deallocation is also triggered on background.
    // CKLifecycleTestComponent will assert if it receives an invalidation not on the main thread,
    id<CKDataSourceProtocol> dataSource = CKComponentTestDataSource(dataSourceClass, [self class], self);
    CKRunRunLoopUntilBlockIsTrue(^BOOL{
      return _state != nil;
    });
    controller = (CKLifecycleTestComponentController *)[[_state objectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]] rootLayout].component().controller;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      [dataSource hash];
    });
  }
  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL(void){
    return controller.calledInvalidateController;
  }));
}

- (void)testDataSourceApplyingPrecomputedChange
{
  [self _testApplyingPrecomputedChange:[CKDataSource class]];
}

- (void)testThreadSafeDataSourceApplyingPrecomputedChange
{
  [self _testApplyingPrecomputedChange:[CKThreadSafeDataSource class]];
}

- (void)_testApplyingPrecomputedChange:(Class<CKDataSourceProtocol>)dataSourceClass
{
  const auto dataSource = (id<CKDataSourceProtocolInternal>)CKComponentTestDataSource(dataSourceClass, [self class], self);
  CKRunRunLoopUntilBlockIsTrue(^BOOL{
    return _state != nil;
  });
  const auto insertion =
  [[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withInsertedItems:@{[NSIndexPath indexPathForItem:0 inSection:0]: @1}]
   build];
  const auto modification =
  [[CKDataSourceChangesetModification alloc]
   initWithChangeset:insertion
   stateListener:nil userInfo:@{}];
  const auto change = [modification changeFromState:_state];
  const auto isApplied = [dataSource applyChange:change];
  XCTAssertTrue(isApplied, @"Change should be applied to datasource successfully.");
  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL{
    return _state == change.state;
  }));
}

- (void)testDataSourceApplyingPrecomputedChangeAfterStateIsChanged
{
  [self _testApplyingPrecomputedChangeAfterStateIsChanged:[CKDataSource class]];
}

- (void)testThreadSafeDataSourceApplyingPrecomputedChangeAfterStateIsChanged
{
  [self _testApplyingPrecomputedChangeAfterStateIsChanged:[CKThreadSafeDataSource class]];
}

- (void)_testApplyingPrecomputedChangeAfterStateIsChanged:(Class<CKDataSourceProtocol>)dataSourceClass
{
  const auto dataSource = (id<CKDataSourceProtocolInternal>)CKComponentTestDataSource(dataSourceClass, [self class], self);
  CKRunRunLoopUntilBlockIsTrue(^BOOL{
    return _state != nil;
  });
  const auto insertion =
  [[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withInsertedItems:@{[NSIndexPath indexPathForItem:0 inSection:0]: @1}]
   build];
  const auto modification =
  [[CKDataSourceChangesetModification alloc]
   initWithChangeset:insertion
   stateListener:nil userInfo:@{}];
  const auto oldState = _state;
  const auto change = [modification changeFromState:oldState];
  [dataSource reloadWithMode:CKUpdateModeSynchronous userInfo:@{}];
  CKRunRunLoopUntilBlockIsTrue(^BOOL{
    return _state != oldState;
  }); 
  const auto newState = _state;
  const auto isApplied = [dataSource applyChange:change];
  XCTAssertFalse(isApplied, @"Applying change to datasource should fail.");
  XCTAssertEqualObjects(_state, newState, @"State should remain the same.");
}

- (void)testDataSourceApplyingPrecomputedChangeWhenThereIsPendingModification
{
  const auto dataSource = (id<CKDataSourceProtocolInternal>)CKComponentTestDataSource([CKDataSource class], [self class], self);
  const auto insertion =
  [[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withInsertedItems:@{[NSIndexPath indexPathForItem:0 inSection:0]: @1}]
   build];
  const auto modification =
  [[CKDataSourceChangesetModification alloc]
   initWithChangeset:insertion
   stateListener:nil userInfo:@{}];
  const auto oldState = _state;
  const auto change1 = [modification changeFromState:oldState];
  [dataSource reloadWithMode:CKUpdateModeAsynchronous userInfo:@{}];
  const auto isApplied1 = [dataSource applyChange:change1];
  XCTAssertEqualObjects(_state, oldState, @"State is not changed but calling `applyChange` should fail because of pending modification.");
  XCTAssertFalse(isApplied1, @"Applying change to datasource should fail.");
  CKRunRunLoopUntilBlockIsTrue(^BOOL{
    return _state != oldState;
  });
  const auto change2 = [modification changeFromState:_state];
  const auto isApplied2 = [dataSource applyChange:change2];
  XCTAssertTrue(isApplied2, @"Re-applying change should succeed once the pending modification finishes processing.");
}

#pragma mark - Listener

- (void)componentDataSource:(id<CKDataSourceProtocol>)dataSource
     didModifyPreviousState:(CKDataSourceState *)previousState
                  withState:(CKDataSourceState *)state
          byApplyingChanges:(CKDataSourceAppliedChanges *)changes
{
  _state = state;
  [_announcedChanges addObject:changes];
}

- (void)componentDataSource:(id<CKDataSourceProtocol>)dataSource willSyncApplyModificationWithUserInfo:(NSDictionary *)userInfo
{
  _syncModificationStartCounter++;
}

- (void)componentDataSourceWillGenerateNewState:(id<CKDataSourceProtocol>)dataSource userInfo:(NSDictionary *)userInfo
{
  _willGenerateChangeCounter++;
}

- (void)componentDataSource:(id<CKDataSourceProtocol>)dataSource didGenerateNewState:(CKDataSourceState *)newState changes:(CKDataSourceAppliedChanges *)changes
{
  _didGenerateChangeCounter++;
}

- (void)componentDataSource:(id<CKDataSourceProtocol>)dataSource
 willApplyDeferredChangeset:(CKDataSourceChangeset *)deferredChangeset {}

@end
