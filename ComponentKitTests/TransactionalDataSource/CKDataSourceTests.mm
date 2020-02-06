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
#import <ComponentKitTestHelpers/CKRenderComponentTestHelpers.h>

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
#import <ComponentKit/CKDataSourceChangesetModification.h>

#import "CKDataSourceStateTestHelpers.h"

static NSString *const kTestInvalidateControllerContext = @"kTestInvalidateControllerContext";
static NSString *const kTestInitialiseControllerContext = @"kTestInitialiseControllerContext";
static NSNumber *const kTestinitialiseControllerModel = @2;

@interface CKDataSourceTests : XCTestCase <CKDataSourceAsyncListener>
@end

@implementation CKDataSourceTests
{
  NSMutableArray<CKDataSourceAppliedChanges *> *_announcedChanges;
  NSInteger _willGenerateChangeCounter;
  NSInteger _didGenerateChangeCounter;
  NSInteger _syncModificationStartCounter;
  CKDataSourceState *_state;
  void(^_didModifyPreviousStateBlock)(void);
}

static CKComponent *ComponentProvider(id<NSObject> model, id<NSObject> context)
{
  if ([context isEqual:kTestInvalidateControllerContext]) {
    return CK::ComponentBuilder()
               .build();
  } else if ([context isEqual:kTestInitialiseControllerContext] || model == kTestinitialiseControllerModel) {
    return [CKCompositeComponentWithScope newWithComponentProvider:^{
      return [CKLifecycleTestComponent new];
    }];
  } else {
    return [CKLifecycleTestComponent new];
  }
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
  CKDataSource *ds = [[CKDataSource alloc]
                      initWithConfiguration:
                      [[CKDataSourceConfiguration alloc]
                       initWithComponentProviderFunc:ComponentProvider
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

  XCTAssertEqualObjects(_announcedChanges.firstObject, expectedAppliedChanges);
  XCTAssertEqual(_syncModificationStartCounter, 1);
  XCTAssertEqual(_willGenerateChangeCounter, 0);
  XCTAssertEqual(_didGenerateChangeCounter, 0);
}

- (void)testDataSourceAsynchronouslyInsertingItemsAnnouncesInsertionAsynchronously
{
  CKDataSource *ds = [[CKDataSource alloc]
                      initWithConfiguration:
                      [[CKDataSourceConfiguration alloc]
                       initWithComponentProviderFunc:ComponentProvider
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
  CKDataSource *ds = CKComponentTestDataSource(ComponentProvider, self);

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

  XCTAssertEqual(_announcedChanges.count, 2);
  XCTAssertEqualObjects(_announcedChanges[1], expectedAppliedChanges);
  XCTAssertEqual([_state configuration], config);
  XCTAssertEqual(_syncModificationStartCounter, 2);
  XCTAssertEqual(_willGenerateChangeCounter, 0);
  XCTAssertEqual(_didGenerateChangeCounter, 0);
}

- (void)testDataSourceReloadingAnnouncesUpdate
{
  CKDataSource *ds = CKComponentTestDataSource(ComponentProvider, self);
  [ds reloadWithMode:CKUpdateModeSynchronous userInfo:nil];

  CKDataSourceAppliedChanges *expectedAppliedChanges =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:0 inSection:0]]
                                              removedIndexPaths:nil
                                                removedSections:nil
                                                movedIndexPaths:nil
                                               insertedSections:nil
                                             insertedIndexPaths:nil
                                                       userInfo:nil];

  XCTAssertEqual(_announcedChanges.count, 2);
  XCTAssertEqualObjects(_announcedChanges[1], expectedAppliedChanges);
  XCTAssertEqual(_syncModificationStartCounter, 2);
  XCTAssertEqual(_willGenerateChangeCounter, 0);
  XCTAssertEqual(_didGenerateChangeCounter, 0);
}

- (void)testDataSourceSynchronousReloadCancelsPreviousAsynchronousReload
{
  CKDataSource *ds = CKComponentTestDataSource(ComponentProvider, self);

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
  CKLifecycleTestComponentController *controller = nil;
  @autoreleasepool {
    // We dispatch empty operation on Data Source to background so that
    // DataSource deallocation is also triggered on background.
    // CKLifecycleTestComponent will assert if it receives an invalidation not on the main thread,
    CKDataSource *dataSource = CKComponentTestDataSource(ComponentProvider, self);
    CKRunRunLoopUntilBlockIsTrue(^BOOL{
      return _state != nil;
    });
    controller = ((CKLifecycleTestComponent *)[[_state objectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]] rootLayout].component()).controller;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      [dataSource hash];
    });
  }
  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL(void){
    return controller.calledInvalidateController;
  }));
}

- (void)testDataSourceAddingComponentByUpdatingConfigurationTriggersDidInitOnMainThread
{
  const auto firstIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
  CKDataSource *dataSource = CKComponentTestDataSource(ComponentProvider, self);
  const auto firstController = (CKLifecycleTestComponentController *)((CKLifecycleTestComponent *)[[_state objectAtIndexPath:firstIndexPath] rootLayout].component()).controller;
  XCTAssertTrue(firstController.calledDidInit);
  [dataSource updateConfiguration:[_state.configuration copyWithContext:kTestInitialiseControllerContext sizeRange:{}]
                             mode:CKUpdateModeSynchronous
                         userInfo:@{}];
  const auto secondController = (CKLifecycleTestComponentController *)((CKCompositeComponent *)[[_state objectAtIndexPath:firstIndexPath] rootLayout].component()).child.controller;
  XCTAssertNotEqual(firstController, secondController);
  XCTAssertTrue(firstController.calledInvalidateController);
  XCTAssertTrue(secondController.calledDidInit);
}

- (void)testDataSourceAddingComponentByApplyingChangesetTriggersDidInitOnMainThread
{
  const auto firstIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
  CKDataSource *dataSource = CKComponentTestDataSource(ComponentProvider, self);
  const auto firstController = (CKLifecycleTestComponentController *)((CKLifecycleTestComponent *)[[_state objectAtIndexPath:firstIndexPath] rootLayout].component()).controller;
  XCTAssertTrue(firstController.calledDidInit);
  [dataSource applyChangeset:[[[CKDataSourceChangesetBuilder dataSourceChangeset]
                              withUpdatedItems:@{firstIndexPath: kTestinitialiseControllerModel}]
                              build]
                        mode:CKUpdateModeSynchronous
                    userInfo:@{}];
  const auto secondController = (CKLifecycleTestComponentController *)((CKCompositeComponent *)[[_state objectAtIndexPath:firstIndexPath] rootLayout].component()).child.controller;
  XCTAssertNotEqual(firstController, secondController);
  XCTAssertTrue(firstController.calledInvalidateController);
  XCTAssertTrue(secondController.calledDidInit);
}

- (void)testDataSourceRemovingComponentTriggersInvalidateOnMainThread
{
  CKDataSource *dataSource = CKComponentTestDataSource(ComponentProvider, self);
  CKRunRunLoopUntilBlockIsTrue(^BOOL{
    return _state != nil;
  });
  const auto controller = ((CKLifecycleTestComponent *)[[_state objectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]] rootLayout].component()).controller;
  [dataSource updateConfiguration:[_state.configuration copyWithContext:kTestInvalidateControllerContext sizeRange:{}]
                             mode:CKUpdateModeSynchronous
                         userInfo:@{}];
  XCTAssertTrue(controller.calledInvalidateController);
}

- (void)testDataSourceApplyingPrecomputedChange
{
  const auto dataSource = CKComponentTestDataSource(ComponentProvider, self);
  const auto insertion =
  [[[CKDataSourceChangesetBuilder dataSourceChangeset]
    withInsertedItems:@{[NSIndexPath indexPathForItem:0 inSection:0]: @1}]
   build];
  const auto modification =
  [[CKDataSourceChangesetModification alloc]
   initWithChangeset:insertion
   stateListener:nil userInfo:@{} qos:CKDataSourceQOSDefault shouldValidateChangeset:NO];
  const auto change = [modification changeFromState:_state];
  const auto isApplied = [dataSource applyChange:change];
  XCTAssertTrue(isApplied, @"Change should be applied to datasource successfully.");
  XCTAssertEqual(_state, change.state);
}

- (void)testDataSourceApplyingPrecomputedChangeAfterStateIsChanged
{
  const auto dataSource = CKComponentTestDataSource(ComponentProvider, self);
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
   stateListener:nil userInfo:@{} qos:CKDataSourceQOSDefault shouldValidateChangeset:NO];
  const auto change = [modification changeFromState:_state];
  [dataSource reloadWithMode:CKUpdateModeSynchronous userInfo:@{}];
  const auto newState = _state;
  const auto isApplied = [dataSource applyChange:change];
  XCTAssertFalse(isApplied, @"Applying change to datasource should fail.");
  XCTAssertEqualObjects(_state, newState, @"State should remain the same.");
}

- (void)testDataSourceVerifyingPrecomputedChange
{
  const auto dataSource = CKComponentTestDataSource(ComponentProvider, self);
  const auto insertion =
  [[[CKDataSourceChangesetBuilder dataSourceChangeset]
    withInsertedItems:@{[NSIndexPath indexPathForItem:0 inSection:0]: @1}]
   build];
  const auto modification =
  [[CKDataSourceChangesetModification alloc]
   initWithChangeset:insertion
   stateListener:nil userInfo:@{} qos:CKDataSourceQOSDefault shouldValidateChangeset:NO];
  const auto change = [modification changeFromState:_state];
  const auto isValid = [dataSource verifyChange:change];
  XCTAssertTrue(isValid, @"Change should be valid.");
}

- (void)testDataSourceVerifyingPrecomputedChangeAfterStateIsChanged
{
  const auto dataSource = CKComponentTestDataSource(ComponentProvider, self);
  const auto insertion =
  [[[CKDataSourceChangesetBuilder dataSourceChangeset]
    withInsertedItems:@{[NSIndexPath indexPathForItem:0 inSection:0]: @1}]
   build];
  const auto modification =
  [[CKDataSourceChangesetModification alloc]
   initWithChangeset:insertion
   stateListener:nil userInfo:@{} qos:CKDataSourceQOSDefault shouldValidateChangeset:NO];
  const auto change = [modification changeFromState:_state];
  [dataSource reloadWithMode:CKUpdateModeSynchronous userInfo:@{}];
  const auto isValid = [dataSource verifyChange:change];
  XCTAssertFalse(isValid, @"Change should not be valid since state has changed.");
}

- (void)testDataSourceComponentInControllerIsNotUpdatedAfterComponentBuild
{
  [self _testUpdateComponentInControllerAfterBuild:NO];
}

- (void)testDataSourceComponentInControllerIsUpdatedAfterComponentBuild
{
  [self _testUpdateComponentInControllerAfterBuild:YES];
}

- (void)_testUpdateComponentInControllerAfterBuild:(BOOL)updateComponentInControllerAfterBuild
{
  CKComponentController *componentController = nil;
  // Autorelease pool is needed here to make sure `oldState` is deallocated so that weak reference of component
  // in `CKComponentController` is nil.
  @autoreleasepool {
    const auto dataSource = CKComponentTestDataSource(ComponentProvider,
                                                      self,
                                                      {.updateComponentInControllerAfterBuild = updateComponentInControllerAfterBuild});
    CKComponent *component = (CKComponent *)[_state objectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]].rootLayout.component();
    componentController = component.controller;
    const auto update =
    [[[CKDataSourceChangesetBuilder dataSourceChangeset]
      withUpdatedItems:@{[NSIndexPath indexPathForItem:0 inSection:0]: @1}]
     build];
    [dataSource applyChangeset:update mode:CKUpdateModeSynchronous userInfo:@{}];
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

/**
 This test covers the case when a "re-entrant" changeset application happens in `didModifyPreviousState`
 event callback. We should make sure no redundant work is done in background queue becasue of this.
 */
- (void)testDataSourceApplyingChangesetInDidModifyPreviousStateCallback
{
  const auto dataSource = CKComponentTestDataSource(ComponentProvider, self);
  _didModifyPreviousStateBlock = ^{
    [dataSource
     applyChangeset:[[CKDataSourceChangesetBuilder dataSourceChangeset] build]
     mode:CKUpdateModeAsynchronous
     userInfo:@{}];
    _didModifyPreviousStateBlock = nil;
  };
  // Applying this changeset asynchronously triggers another changeset application in `_didModifyPreviousStateBlock`.
  [dataSource
   applyChangeset:[[CKDataSourceChangesetBuilder dataSourceChangeset] build]
   mode:CKUpdateModeAsynchronous
   userInfo:@{}];
  CKRunRunLoopUntilBlockIsTrue(^BOOL{
    return _announcedChanges.count == 3;
  });
  // Applying another changeset to make sure all asynchronous work is finished in background queue.
  [dataSource
   applyChangeset:[[CKDataSourceChangesetBuilder dataSourceChangeset] build]
   mode:CKUpdateModeAsynchronous
   userInfo:@{}];
  CKRunRunLoopUntilBlockIsTrue(^BOOL{
    return _announcedChanges.count == 4;
  });
  // `_willGenerateChangeCounter` matches the number of asynchronous changeset applications.
  XCTAssertEqual(_willGenerateChangeCounter, 3);
}

#pragma mark - Listener

- (void)dataSource:(CKDataSource *)dataSource
     didModifyPreviousState:(CKDataSourceState *)previousState
                  withState:(CKDataSourceState *)state
          byApplyingChanges:(CKDataSourceAppliedChanges *)changes
{
  _state = state;
  [_announcedChanges addObject:changes];
  if (_didModifyPreviousStateBlock) {
    _didModifyPreviousStateBlock();
  }
}

- (void)dataSource:(CKDataSource *)dataSource willSyncApplyModificationWithUserInfo:(NSDictionary *)userInfo
{
  _syncModificationStartCounter++;
}

- (void)dataSource:(CKDataSource *)dataSource willGenerateNewStateWithUserInfo:(NSDictionary *)userInfo
{
  _willGenerateChangeCounter++;
}

- (void)dataSource:(CKDataSource *)dataSource didGenerateNewState:(CKDataSourceState *)newState changes:(CKDataSourceAppliedChanges *)changes
{
  _didGenerateChangeCounter++;
}

- (void)dataSource:(CKDataSource *)dataSource
 willApplyDeferredChangeset:(CKDataSourceChangeset *)deferredChangeset {}

@end
