/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <mutex>

#import <XCTest/XCTest.h>

#import <ComponentKit/CKAnalyticsListener.h>
#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKDataSourceChange.h>
#import <ComponentKit/CKDataSourceChangeset.h>
#import <ComponentKit/CKDataSourceConfigurationInternal.h>
#import <ComponentKit/CKDataSourceInternal.h>
#import <ComponentKit/CKDataSourceListener.h>
#import <ComponentKit/CKDataSourceStateInternal.h>
#import <ComponentKit/CKDataSourceChangesetApplicator.h>
#import <ComponentKitTestHelpers/CKTestRunLoopRunning.h>

@interface CKDataSourceMock : CKDataSource

// Indicates how many times `verifyChange:` is called.
@property (nonatomic, readonly, assign) NSUInteger verifyChangeCount;
// Indicates how many times `applyChange:` is called if change is verified.
@property (nonatomic, readonly, assign) NSUInteger applyChangeCount;

- (void)sendNewState;
- (void)sendNewStateWithSizeRange:(CKSizeRange)sizeRange;

@end

@interface CKDataSourceChangesetApplicatorTests : XCTestCase <CKAnalyticsListener>

@end

// Use without relying on lifecycle of `dataSource`.
static NSUInteger _globalVerifyChangeCount = 0;
static NSUInteger _globalApplyChangeCount = 0;

@implementation CKDataSourceChangesetApplicatorTests
{
  CKDataSourceMock *_dataSource;
  CKDataSourceChangesetApplicator *_changesetApplicator;
  dispatch_queue_t _queue;

  std::atomic<NSUInteger> _buildComponentCount;
}

- (void)setUp
{
  const auto configuration =
  [[CKDataSourceConfiguration alloc]
   initWithComponentProviderFunc:componentProvider
   context:nil
   sizeRange:{{100, 100}, {100, 100}}
   options:{}
   componentPredicates:{}
   componentControllerPredicates:{}
   analyticsListener:self];
  const auto dataSourceState = [[CKDataSourceState alloc] initWithConfiguration:configuration sections:@[]];
  _dataSource = [[CKDataSourceMock alloc] initWithState:dataSourceState];
  _queue = dispatch_queue_create("CKDataSourceChangesetApplicator.Tests", DISPATCH_QUEUE_SERIAL);
  _changesetApplicator =
  [[CKDataSourceChangesetApplicator alloc]
   initWithDataSource:_dataSource
   queue:_queue];
  _buildComponentCount = 0;
}

- (void)tearDown
{
  _dataSource = nil;
  _changesetApplicator = nil;
  _globalVerifyChangeCount = 0;
  _globalApplyChangeCount = 0;
}

- (void)testChangeIsAppliedAfterApplyChangesetIsCalled
{
  dispatch_sync(_queue, ^{
    [self->_changesetApplicator applyChangeset:defaultChangeset()
                                      userInfo:@{}
                                           qos:CKDataSourceQOSDefault];
  });
  [self waitUntilChangesetApplicatorFinishesItsTasksOnMainQueue];
  [self assertNumberOfSuccessfulChanges:1 numberOfFailedChanges:0];
}

- (void)testChangesetIsNotAppliedIfDataSourceIsDeallocated
{
  dispatch_sync(_queue, ^{
    [self->_changesetApplicator applyChangeset:defaultChangeset()
                                      userInfo:@{}
                                           qos:CKDataSourceQOSDefault];
  });
  _dataSource = nil;
  [self waitUntilChangesetApplicatorFinishesItsTasksOnMainQueue];
  XCTAssertEqual(_globalVerifyChangeCount, 0);
  XCTAssertEqual(_globalApplyChangeCount, 0);
}

- (void)testChangesAreAppliedSequentiallyAfterApplyChangesetIsCalledMultipleTimes
{
  dispatch_sync(_queue, ^{
    [self->_changesetApplicator
     applyChangeset:defaultChangeset()
     userInfo:@{}
     qos:CKDataSourceQOSDefault];
    [self->_changesetApplicator
     applyChangeset:defaultChangeset()
     userInfo:@{}
     qos:CKDataSourceQOSDefault];
  });
  [self waitUntilChangesetApplicatorFinishesItsTasksOnMainQueue];
  [self assertNumberOfSuccessfulChanges:2 numberOfFailedChanges:0];
}

- (void)testChangesetsAreReappliedIfDataSourceStateIsChangedWhenProcessingChangesets
{
  dispatch_sync(_queue, ^{
    [self->_changesetApplicator
     applyChangeset:defaultChangeset()
     userInfo:@{}
     qos:CKDataSourceQOSDefault];
    [self->_changesetApplicator
     applyChangeset:defaultChangeset()
     userInfo:@{}
     qos:CKDataSourceQOSDefault];
  });
  [_dataSource sendNewState];
  [self waitUntilChangesetApplicatorFinishesItsTasksOnMainQueue];
  [self waitUntilChangesetApplicatorQueueIsIdle];
  [self waitUntilChangesetApplicatorFinishesItsTasksOnMainQueue];
  [self assertNumberOfSuccessfulChanges:2 numberOfFailedChanges:2];
}

- (void)testSecondChangesetIsReappliedIfDataSourceStateIsChangedWhenProcessingSecondChangeset
{
  dispatch_sync(_queue, ^{
    [self->_changesetApplicator
     applyChangeset:defaultChangeset()
     userInfo:@{}
     qos:CKDataSourceQOSDefault];
  });
  [self waitUntilChangesetApplicatorFinishesItsTasksOnMainQueue];
  dispatch_sync(_queue, ^{
    [self->_changesetApplicator
     applyChangeset:defaultChangeset()
     userInfo:@{}
     qos:CKDataSourceQOSDefault];
  });
  [_dataSource sendNewState];
  [self waitUntilChangesetApplicatorFinishesItsTasksOnMainQueue];
  [self waitUntilChangesetApplicatorQueueIsIdle];
  [self waitUntilChangesetApplicatorFinishesItsTasksOnMainQueue];
  [self assertNumberOfSuccessfulChanges:2 numberOfFailedChanges:1];
}

- (void)testDataSourceItemCacheIsUsedWhenChangesetIsReapplied
{
  dispatch_sync(_queue, ^{
    [self->_changesetApplicator
     applyChangeset:
     [[[[CKDataSourceChangesetBuilder dataSourceChangeset]
        withInsertedItems:@{[NSIndexPath indexPathForItem:0 inSection:0]: @0}]
       withInsertedSections:[NSIndexSet indexSetWithIndex:0]]
      build]
     userInfo:@{}
     qos:CKDataSourceQOSDefault];
  });
  [_dataSource sendNewState];
  [self waitUntilChangesetApplicatorFinishesItsTasksOnMainQueue];
  [self waitUntilChangesetApplicatorQueueIsIdle];
  [self waitUntilChangesetApplicatorFinishesItsTasksOnMainQueue];
  [self assertNumberOfSuccessfulChanges:1 numberOfFailedChanges:1];
  XCTAssertTrue(_buildComponentCount == 1, @"`dataSourceItem` should only be built once because of cache.");
}

- (void)testDataSourceItemCacheIsNotUsedIfConfigurationIsChangedWhenChangesetIsReapplied
{
  dispatch_sync(_queue, ^{
    [self->_changesetApplicator
     applyChangeset:
     [[[[CKDataSourceChangesetBuilder dataSourceChangeset]
        withInsertedItems:@{[NSIndexPath indexPathForItem:0 inSection:0]: @0}]
       withInsertedSections:[NSIndexSet indexSetWithIndex:0]]
      build]
     userInfo:@{}
     qos:CKDataSourceQOSDefault];
  });
  [_dataSource sendNewStateWithSizeRange:{{0, 0}, {200, 200}}];
  [self waitUntilChangesetApplicatorFinishesItsTasksOnMainQueue];
  [self waitUntilChangesetApplicatorQueueIsIdle];
  [self waitUntilChangesetApplicatorFinishesItsTasksOnMainQueue];
  [self assertNumberOfSuccessfulChanges:1 numberOfFailedChanges:1];
  XCTAssertTrue(_buildComponentCount == 2, @"`dataSourceItem` should be built twice because cache is invalidated.");
}

- (void)testStateUpdatesArePausedInDataSourceAfterApplyChangesetIsCalled
{
  XCTAssertFalse(_dataSource.shouldPauseStateUpdates);
  dispatch_sync(_queue, ^{
    [self->_changesetApplicator
     applyChangeset:defaultChangeset()
     userInfo:@{}
     qos:CKDataSourceQOSDefault];
  });
  [self waitUntilChangesetApplicatorFinishesItsTasksOnMainQueue];
  XCTAssertTrue(_dataSource.shouldPauseStateUpdates);

  [self waitUntilChangesetApplicatorQueueIsIdle];
  [self waitUntilChangesetApplicatorFinishesItsTasksOnMainQueue];
  // After changeset applicator finishes processing changeset, `shouldPauseStateUpdates` is set to NO.
  XCTAssertFalse(_dataSource.shouldPauseStateUpdates);
}

- (void)testSpiltChangesetIsAppliedWithoutDefferedChangesetWhenViewportIsLargeEnough
{
  [self enableSplitChangeset];
  [_changesetApplicator setViewPort:{.size = {100, 200}}];
  dispatch_sync(_queue, ^{
    [self->_changesetApplicator
     applyChangeset:
     [[[[CKDataSourceChangesetBuilder dataSourceChangeset]
       withInsertedItems:@{
         [NSIndexPath indexPathForItem:0 inSection:0]: @0,
         [NSIndexPath indexPathForItem:1 inSection:0]: @1,
       }]
       withInsertedSections:[NSIndexSet indexSetWithIndex:0]] build]
     userInfo:@{}qos:CKDataSourceQOSDefault];
  });
  [self waitUntilChangesetApplicatorFinishesItsTasksOnMainQueue];
  [self assertNumberOfSuccessfulChanges:1 numberOfFailedChanges:0];
}

- (void)testSpiltChangesetIsAppliedWithDefferedChangesetWhenViewportIsNotLargeEnough
{
  [self enableSplitChangeset];
  [_changesetApplicator setViewPort:{.size = {100, 100}}];
  dispatch_sync(_queue, ^{
    [self->_changesetApplicator
     applyChangeset:
     [[[[CKDataSourceChangesetBuilder dataSourceChangeset]
       withInsertedItems:@{
         [NSIndexPath indexPathForItem:0 inSection:0]: @0,
         [NSIndexPath indexPathForItem:1 inSection:0]: @1,
       }]
       withInsertedSections:[NSIndexSet indexSetWithIndex:0]] build]
     userInfo:@{}qos:CKDataSourceQOSDefault];
  });
  [self waitUntilChangesetApplicatorFinishesItsTasksOnMainQueue];
  [self assertNumberOfSuccessfulChanges:2 numberOfFailedChanges:0];
}

- (void)testSpiltChangesetIsReappliedWithoutDefferedChangesetWhenDataSourceStateIsChanged
{
  [self enableSplitChangeset];
  [_changesetApplicator setViewPort:{.size = {100, 200}}];
  dispatch_sync(_queue, ^{
    [self->_changesetApplicator
     applyChangeset:
     [[[[CKDataSourceChangesetBuilder dataSourceChangeset]
       withInsertedItems:@{
         [NSIndexPath indexPathForItem:0 inSection:0]: @0,
         [NSIndexPath indexPathForItem:1 inSection:0]: @1,
       }]
       withInsertedSections:[NSIndexSet indexSetWithIndex:0]] build]
     userInfo:@{}qos:CKDataSourceQOSDefault];
  });
  [_dataSource sendNewState];
  [self waitUntilChangesetApplicatorFinishesItsTasksOnMainQueue];
  [self waitUntilChangesetApplicatorQueueIsIdle];
  [self waitUntilChangesetApplicatorFinishesItsTasksOnMainQueue];
  [self assertNumberOfSuccessfulChanges:1 numberOfFailedChanges:1];
}

- (void)testSpiltChangesetIsReappliedWithDefferedChangesetWhenDataSourceStateIsChanged
{
  [self enableSplitChangeset];
  [_changesetApplicator setViewPort:{.size = {100, 100}}];
  dispatch_sync(_queue, ^{
    [self->_changesetApplicator
     applyChangeset:
     [[[[CKDataSourceChangesetBuilder dataSourceChangeset]
       withInsertedItems:@{
         [NSIndexPath indexPathForItem:0 inSection:0]: @0,
         [NSIndexPath indexPathForItem:1 inSection:0]: @1,
       }]
       withInsertedSections:[NSIndexSet indexSetWithIndex:0]] build]
     userInfo:@{}qos:CKDataSourceQOSDefault];
  });
  [_dataSource sendNewState];
  [self waitUntilChangesetApplicatorFinishesItsTasksOnMainQueue];
  [self waitUntilChangesetApplicatorQueueIsIdle];
  [self waitUntilChangesetApplicatorFinishesItsTasksOnMainQueue];
  [self assertNumberOfSuccessfulChanges:2 numberOfFailedChanges:2];
}

static CKComponent *componentProvider(id<NSObject> model, id<NSObject> context)
{
  return CK::ComponentBuilder()
    .size({100, 100})
    .build();
}

#pragma mark - CKAnalyticsListener

- (void)willBuildComponentTreeWithScopeRoot:(CKComponentScopeRoot *)scopeRoot
                               buildTrigger:(CKBuildTrigger)buildTrigger
                               stateUpdates:(const CKComponentStateUpdateMap &)stateUpdates
          enableComponentReuseOptimizations:(BOOL)enableComponentReuseOptimizations
{
  _buildComponentCount++;
}

- (void)didBuildComponentTreeWithScopeRoot:(CKComponentScopeRoot *)scopeRoot
                              buildTrigger:(CKBuildTrigger)buildTrigger
                              stateUpdates:(const CKComponentStateUpdateMap &)stateUpdates
                                 component:(CKComponent *)component
         enableComponentReuseOptimizations:(BOOL)enableComponentReuseOptimizations
{

}

- (void)didCollectAnimationsFromComponentTreeWithRootComponent:(id<CKMountable>)component
{

}

- (void)didLayoutComponentTreeWithRootComponent:(id<CKMountable>)component
{

}

- (void)didMountComponentTreeWithRootComponent:(id<CKMountable>)component
                         mountAnalyticsContext:(CK::Optional<CK::Component::MountAnalyticsContext>)mountAnalyticsContext
{

}

- (void)didReuseNode:(id<CKTreeNodeProtocol>)node
         inScopeRoot:(CKComponentScopeRoot *)scopeRoot
fromPreviousScopeRoot:(CKComponentScopeRoot *)previousScopeRoot
{

}

- (BOOL)shouldCollectMountInformationForRootComponent:(CKComponent *)component
{
  return NO;
}

- (id<CKSystraceListener>)systraceListener
{
  return nil;
}

- (BOOL)shouldCollectTreeNodeCreationInformation:(CKComponentScopeRoot *)scopeRoot { return NO; }

- (void)didBuildTreeNodeForPrecomputedChild:(id<CKTreeNodeComponentProtocol>)component
                                       node:(id<CKTreeNodeProtocol>)node
                                     parent:(id<CKTreeNodeWithChildrenProtocol>)parent
                                     params:(const CKBuildComponentTreeParams &)params
                       parentHasStateUpdate:(BOOL)parentHasStateUpdate {}

- (void)willCollectAnimationsFromComponentTreeWithRootComponent:(id<CKMountable>)component
{

}

- (void)willLayoutComponentTreeWithRootComponent:(id<CKMountable>)component buildTrigger:(CK::Optional<CKBuildTrigger>)buildTrigger
{

}

- (void)willMountComponentTreeWithRootComponent:(id<CKMountable>)component
{

}

#pragma mark - Helpers

- (void)enableSplitChangeset
{
  const auto preivousConfiguration = _dataSource.state.configuration;
  const auto configuration =
  [[CKDataSourceConfiguration alloc]
   initWithComponentProviderFunc:componentProvider
   context:preivousConfiguration.context
   sizeRange:preivousConfiguration.sizeRange
   options:{
    .splitChangesetOptions = {
      .enabled = YES,
    },
   }
   componentPredicates:preivousConfiguration.componentPredicates
   componentControllerPredicates:preivousConfiguration.componentControllerPredicates
   analyticsListener:preivousConfiguration.analyticsListener];
  [_dataSource updateConfiguration:configuration mode:CKUpdateModeSynchronous userInfo:@{}];
}

- (void)waitUntilChangesetApplicatorFinishesItsTasksOnMainQueue
{
  __block BOOL didRun = NO;
  dispatch_async(dispatch_get_main_queue(), ^{
    didRun = YES;
  });
  CKRunRunLoopUntilBlockIsTrue(^BOOL{
    return didRun;
  });
}

- (void)waitUntilChangesetApplicatorQueueIsIdle
{
  // Use `dispatch_sync` to block the main queue until the queue finishes its current task.
  dispatch_sync(_queue, ^{});
}

- (void)assertNumberOfSuccessfulChanges:(NSUInteger)numberOfSuccessfulChanges
                  numberOfFailedChanges:(NSUInteger)numberOfFailedChanges
{
  // Number is doubled because internally `applyChange` calls `verifyChange` as well.
  XCTAssertEqual(_dataSource.verifyChangeCount, (numberOfFailedChanges + numberOfSuccessfulChanges) * 2);
  XCTAssertEqual(_dataSource.applyChangeCount, numberOfSuccessfulChanges);
}

static CKDataSourceChangeset *defaultChangeset()
{
  return [[CKDataSourceChangesetBuilder dataSourceChangeset] build];
}

@end

#pragma mark - CKDataSourceMock

@implementation CKDataSourceMock

- (BOOL)applyChange:(CKDataSourceChange *)change
{
  const auto applied = [super applyChange:change];
  if (applied) {
    _applyChangeCount++;
    _globalApplyChangeCount++;
  }
  return applied;
}

- (BOOL)verifyChange:(CKDataSourceChange *)change
{
  _verifyChangeCount++;
  _globalVerifyChangeCount++;
  return [super verifyChange:change];
}

- (void)sendNewState
{
  [self sendNewStateWithSizeRange:self.state.configuration.sizeRange];
}

- (void)sendNewStateWithSizeRange:(CKSizeRange)sizeRange
{
  const auto configuration =
  [[CKDataSourceConfiguration alloc]
   initWithComponentProviderFunc:componentProvider
   context:self.state.configuration.context
   sizeRange:sizeRange
   options:self.state.configuration.options
   componentPredicates:self.state.configuration.componentPredicates
   componentControllerPredicates:self.state.configuration.componentControllerPredicates
   analyticsListener:self.state.configuration.analyticsListener];
  [self updateConfiguration:configuration mode:CKUpdateModeSynchronous userInfo:@{}];
}

@end
