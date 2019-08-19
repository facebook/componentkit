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
#import <ComponentKit/CKCompositeComponent.h>
#import <ComponentKit/CKComponentProvider.h>
#import <ComponentKit/CKComponentSubclass.h>
#import <ComponentKit/CKDataSourceAppliedChanges.h>
#import <ComponentKit/CKDataSourceChange.h>
#import <ComponentKit/CKDataSourceChangeset.h>
#import <ComponentKit/CKDataSourceConfiguration.h>
#import <ComponentKit/CKDataSourceConfigurationInternal.h>
#import <ComponentKit/CKDataSourceInternal.h>
#import <ComponentKit/CKDataSourceItem.h>
#import <ComponentKit/CKDataSourceListener.h>
#import <ComponentKit/CKDataSourceState.h>
#import <ComponentKit/CKDataSourceProtocolInternal.h>
#import <ComponentKit/CKDataSourceChangesetModification.h>

#import "CKDataSourceStateTestHelpers.h"

static NSString *const kTestInvalidateControllerContext = @"kTestInvalidateControllerContext";

@interface CKDataSourceTests : XCTestCase <CKDataSourceAsyncListener>
@end

@implementation CKDataSourceTests
{
  NSMutableArray<CKDataSourceAppliedChanges *> *_announcedChanges;
  NSInteger _willGenerateChangeCounter;
  NSInteger _didGenerateChangeCounter;
  NSInteger _syncModificationStartCounter;
  CKDataSourceState *_state;
}

static CKComponent *ComponentProvider(id<NSObject> model, id<NSObject> context)
{
  if ([context isEqual:kTestInvalidateControllerContext]) {
    return [CKComponent newWithView:{} size:{}];
  }
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

- (void)_testSynchronouslyInsertingItemsAnnouncesInsertionWithDataSourceClass:(Class<CKDataSourceProtocol>)dataSourceClass
{
  id<CKDataSourceProtocol> ds = [[(Class)dataSourceClass alloc]
      initWithConfiguration:[[CKDataSourceConfiguration alloc] initWithComponentProviderFunc:ComponentProvider
                                                                                     context:nil
                                                                                   sizeRange:{}]];
  [ds addListener:self];

  CKDataSourceChangeset *insertion =
  [[[[CKDataSourceChangesetBuilder dataSourceChangeset]
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

- (void)_testAsynchronouslyInsertingItemsAnnouncesInsertionAsynchronouslyWithDataSourceClass:(Class<CKDataSourceProtocol>)dataSourceClass
{
  id<CKDataSourceProtocol> ds = [[(Class)dataSourceClass alloc]
      initWithConfiguration:[[CKDataSourceConfiguration alloc] initWithComponentProviderFunc:ComponentProvider
                                                                                     context:nil
                                                                                   sizeRange:{}]];
  [ds addListener:self];

  CKDataSourceChangeset *insertion =
  [[[[CKDataSourceChangesetBuilder dataSourceChangeset]
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

- (void)_testUpdatingConfigurationAnnouncesUpdateWithDataSourceClass:(Class<CKDataSourceProtocol>)dataSourceClass
{
  id<CKDataSourceProtocol> ds = CKComponentTestDataSource(dataSourceClass, ComponentProvider, self);

  CKDataSourceConfiguration *config = [[CKDataSourceConfiguration alloc] initWithComponentProviderFunc:ComponentProvider
                                                                                               context:@"new context"
                                                                                             sizeRange:{}];
  [ds updateConfiguration:config mode:CKUpdateModeSynchronous userInfo:nil];

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

- (void)_testReloadingAnnouncesUpdateWithDataSourceClass:(Class<CKDataSourceProtocol>)dataSourceClass
{
  id<CKDataSourceProtocol> ds = CKComponentTestDataSource(dataSourceClass, ComponentProvider, self);
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
  id<CKDataSourceProtocol> ds = CKComponentTestDataSource([CKDataSource class], ComponentProvider, self);

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

- (void)_testDeallocatingDataSourceTriggersInvalidateOnMainThreadWithDataSourceClass:(Class<CKDataSourceProtocol>)dataSourceClass
{
  CKLifecycleTestComponentController *controller = nil;
  @autoreleasepool {
    // We dispatch empty operation on Data Source to background so that
    // DataSource deallocation is also triggered on background.
    // CKLifecycleTestComponent will assert if it receives an invalidation not on the main thread,
    id<CKDataSourceProtocol> dataSource = CKComponentTestDataSource(dataSourceClass, ComponentProvider, self);
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

- (void)testDataSourceRemovingComponentTriggersInvalidateOnMainThread
{
  [self _testRemovingComponentTriggersInvalidateOnMainThreadWithDataSourceClass:[CKDataSource class]];
}

- (void)_testRemovingComponentTriggersInvalidateOnMainThreadWithDataSourceClass:(Class<CKDataSourceProtocol>)dataSourceClass
{
  id<CKDataSourceProtocol> dataSource = CKComponentTestDataSource(dataSourceClass, ComponentProvider, self);
  CKRunRunLoopUntilBlockIsTrue(^BOOL{
    return _state != nil;
  });
  const auto controller = (CKLifecycleTestComponentController *)[[_state objectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]] rootLayout].component().controller;
  [dataSource updateConfiguration:[_state.configuration copyWithContext:kTestInvalidateControllerContext sizeRange:{}]
                             mode:CKUpdateModeSynchronous
                         userInfo:@{}];
  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL(void){
    return controller.calledInvalidateController;
  }));
}

- (void)testDataSourceApplyingPrecomputedChange
{
  [self _testApplyingPrecomputedChange:[CKDataSource class]];
}

- (void)_testApplyingPrecomputedChange:(Class<CKDataSourceProtocol>)dataSourceClass
{
  const auto dataSource = (id<CKDataSourceProtocolInternal>)CKComponentTestDataSource(dataSourceClass, ComponentProvider, self);
  CKRunRunLoopUntilBlockIsTrue(^BOOL{
    return _state != nil;
  });
  const auto insertion =
  [[[CKDataSourceChangesetBuilder dataSourceChangeset]
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

- (void)_testApplyingPrecomputedChangeAfterStateIsChanged:(Class<CKDataSourceProtocol>)dataSourceClass
{
  const auto dataSource = (id<CKDataSourceProtocolInternal>)CKComponentTestDataSource(dataSourceClass, ComponentProvider, self);
  CKRunRunLoopUntilBlockIsTrue(^BOOL{
    return _state != nil;
  });
  const auto insertion =
  [[[CKDataSourceChangesetBuilder dataSourceChangeset]
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

- (void)testDataSourceVerifyingPrecomputedChange
{
  [self _testVerifyingPrecomputedChange:[CKDataSource class]];
}

- (void)_testVerifyingPrecomputedChange:(Class<CKDataSourceProtocol>)dataSourceClass
{
  const auto dataSource = (id<CKDataSourceProtocolInternal>)CKComponentTestDataSource(dataSourceClass, ComponentProvider, self);
  CKRunRunLoopUntilBlockIsTrue(^BOOL{
    return _state != nil;
  });
  const auto insertion =
  [[[CKDataSourceChangesetBuilder dataSourceChangeset]
    withInsertedItems:@{[NSIndexPath indexPathForItem:0 inSection:0]: @1}]
   build];
  const auto modification =
  [[CKDataSourceChangesetModification alloc]
   initWithChangeset:insertion
   stateListener:nil userInfo:@{}];
  const auto change = [modification changeFromState:_state];
  const auto isValid = [dataSource verifyChange:change];
  XCTAssertTrue(isValid, @"Change should be valid.");
}

- (void)testDataSourceVerifyingPrecomputedChangeAfterStateIsChanged
{
  [self _testVerifyingPrecomputedChangeAfterStateIsChanged:[CKDataSource class]];
}

- (void)_testVerifyingPrecomputedChangeAfterStateIsChanged:(Class<CKDataSourceProtocol>)dataSourceClass
{
  const auto dataSource = (id<CKDataSourceProtocol, CKDataSourceProtocolInternal>)CKComponentTestDataSource(dataSourceClass, ComponentProvider, self);
  CKRunRunLoopUntilBlockIsTrue(^BOOL{
    return _state != nil;
  });
  const auto insertion =
  [[[CKDataSourceChangesetBuilder dataSourceChangeset]
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
  const auto isValid = [dataSource verifyChange:change];
  XCTAssertFalse(isValid, @"Change should not be valid since state has changed.");
}

- (void)testDataSourceComponentInControllerIsNotUpdatedAfterComponentBuild
{
  [self _testUpdateComponentInController:[CKDataSource class] updateComponentInControllerAfterBuild:NO];
}

- (void)testDataSourceComponentInControllerIsUpdatedAfterComponentBuild
{
  [self _testUpdateComponentInController:[CKDataSource class] updateComponentInControllerAfterBuild:YES];
}

- (void)_testUpdateComponentInController:(Class<CKDataSourceProtocol>)dataSourceClass
   updateComponentInControllerAfterBuild:(BOOL)updateComponentInControllerAfterBuild
{
  CKComponentController *componentController = nil;
  // Autorelease pool is needed here to make sure `oldState` is deallocated so that weak reference of component
  // in `CKComponentController` is nil.
  @autoreleasepool {
    const auto dataSource = (id<CKDataSourceProtocol, CKDataSourceProtocolInternal>)
    CKComponentTestDataSource(dataSourceClass,
                              ComponentProvider,
                              self,
                              {.updateComponentInControllerAfterBuild = updateComponentInControllerAfterBuild});
    CKRunRunLoopUntilBlockIsTrue(^BOOL{
      return _state != nil;
    });
    componentController = [_state objectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]].rootLayout.component().controller;
    const auto update =
    [[[CKDataSourceChangesetBuilder dataSourceChangeset]
      withUpdatedItems:@{[NSIndexPath indexPathForItem:0 inSection:0]: @1}]
     build];
    auto oldState = _state;
    [dataSource applyChangeset:update mode:CKUpdateModeSynchronous userInfo:@{}];
    CKRunRunLoopUntilBlockIsTrue(^BOOL{
      return _state != oldState;
    });
    oldState = nil;
  }
  if (updateComponentInControllerAfterBuild) {
    // `latestComponent` is updated so `componentController.component` returns the latest generation of component even
    // after `oldState` is deallocated.
    XCTAssertNotEqual(componentController.component, nil);
  } else {
    // `latestComponent` is not updated so `componentController.component` is nil because `oldState` is deallocated.
    XCTAssertEqual(componentController.component, nil);
  }
}

#pragma mark - Listener

- (void)componentDataSource:(CKDataSource *)dataSource
     didModifyPreviousState:(CKDataSourceState *)previousState
                  withState:(CKDataSourceState *)state
          byApplyingChanges:(CKDataSourceAppliedChanges *)changes
{
  _state = state;
  [_announcedChanges addObject:changes];
}

- (void)componentDataSource:(CKDataSource *)dataSource willSyncApplyModificationWithUserInfo:(NSDictionary *)userInfo
{
  _syncModificationStartCounter++;
}

- (void)componentDataSourceWillGenerateNewState:(CKDataSource *)dataSource userInfo:(NSDictionary *)userInfo
{
  _willGenerateChangeCounter++;
}

- (void)componentDataSource:(CKDataSource *)dataSource didGenerateNewState:(CKDataSourceState *)newState changes:(CKDataSourceAppliedChanges *)changes
{
  _didGenerateChangeCounter++;
}

- (void)componentDataSource:(CKDataSource *)dataSource
 willApplyDeferredChangeset:(CKDataSourceChangeset *)deferredChangeset {}

@end
