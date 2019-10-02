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
   sizeRange:{}
   options:{}
   componentPredicates:{}
   componentControllerPredicates:{}
   analyticsListener:self];
  const auto dataSourceState = [[CKDataSourceState alloc] initWithConfiguration:configuration sections:@[]];
  _dataSource = [[CKDataSourceMock alloc] initWithState:dataSourceState];
  _queue = dispatch_queue_create("CKDataSourceChangesetApplicator.Tests", DISPATCH_QUEUE_SERIAL);
  _changesetApplicator =
  [[CKDataSourceChangesetApplicator alloc]
   initWithDataSource:(CKDataSource *)_dataSource
   dataSourceState:dataSourceState
   queue:_queue];
  _buildComponentCount = 0;
}

- (void)tearDown
{
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
  XCTAssertEqual(_dataSource.verifyChangeCount, 1);
  XCTAssertEqual(_dataSource.applyChangeCount, 1);
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
  XCTAssertEqual(_dataSource.verifyChangeCount, 2);
  XCTAssertEqual(_dataSource.applyChangeCount, 2);
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
  XCTAssertEqual(_dataSource.verifyChangeCount, 2);
  XCTAssertEqual(_dataSource.applyChangeCount, 0);
  [self waitUntilChangesetApplicatorQueueIsIdle];
  [self waitUntilChangesetApplicatorFinishesItsTasksOnMainQueue];
  XCTAssertEqual(_dataSource.verifyChangeCount, 4);
  XCTAssertEqual(_dataSource.applyChangeCount, 2);
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
  [_dataSource sendNewState];
  dispatch_sync(_queue, ^{
    [self->_changesetApplicator
     applyChangeset:defaultChangeset()
     userInfo:@{}
     qos:CKDataSourceQOSDefault];
  });
  [self waitUntilChangesetApplicatorFinishesItsTasksOnMainQueue];
  XCTAssertEqual(_dataSource.verifyChangeCount, 2);
  XCTAssertEqual(_dataSource.applyChangeCount, 1);
  [self waitUntilChangesetApplicatorQueueIsIdle];
  [self waitUntilChangesetApplicatorFinishesItsTasksOnMainQueue];
  XCTAssertEqual(_dataSource.verifyChangeCount, 3);
  XCTAssertEqual(_dataSource.applyChangeCount, 2);
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
  XCTAssertEqual(_dataSource.verifyChangeCount, 2);
  XCTAssertEqual(_dataSource.applyChangeCount, 1);
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
  XCTAssertEqual(_dataSource.verifyChangeCount, 2);
  XCTAssertEqual(_dataSource.applyChangeCount, 1);
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

static CKComponent *componentProvider(id<NSObject> model, id<NSObject> context)
{
  return CK::ComponentBuilder()
             .build();
}

#pragma mark - CKAnalyticsListener

- (void)willBuildComponentTreeWithScopeRoot:(CKComponentScopeRoot *)scopeRoot
                               buildTrigger:(BuildTrigger)buildTrigger
                               stateUpdates:(const CKComponentStateUpdateMap &)stateUpdates
{
  _buildComponentCount++;
}

- (void)didBuildComponentTreeWithScopeRoot:(CKComponentScopeRoot *)scopeRoot
                              buildTrigger:(BuildTrigger)buildTrigger
                              stateUpdates:(const CKComponentStateUpdateMap &)stateUpdates
                                 component:(CKComponent *)component
{

}

- (void)didCollectAnimationsFromComponentTreeWithRootComponent:(id<CKMountable>)component
{

}

- (void)didLayoutComponentTreeWithRootComponent:(id<CKMountable>)component
{

}

- (void)didMountComponentTreeWithRootComponent:(id<CKMountable>)component
                         mountAnalyticsContext:(CK::Component::MountAnalyticsContext *)mountAnalyticsContext
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

- (void)willLayoutComponentTreeWithRootComponent:(id<CKMountable>)component buildTrigger:(CK::Optional<BuildTrigger>)buildTrigger
{

}

- (void)willMountComponentTreeWithRootComponent:(id<CKMountable>)component
{

}

#pragma mark - Helpers

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

static CKDataSourceChangeset *defaultChangeset()
{
  return [[CKDataSourceChangesetBuilder dataSourceChangeset] build];
}

@end

#pragma mark - CKDataSourceMock

@implementation CKDataSourceMock
{
  CKDataSourceState *_state;
}

- (instancetype)initWithConfiguration:(CKDataSourceConfiguration *)configuration
{
  return [self initWithState:[[CKDataSourceState alloc] initWithConfiguration:configuration sections:@[]]];
}

- (instancetype)initWithState:(CKDataSourceState *)state
{
  if (self = [super init]) {
    _state = state;
  }
  return self;
}

- (CKDataSourceState *)state
{
  return _state;
}

- (BOOL)applyChange:(CKDataSourceChange *)change
{
  if (change.previousState != _state) {
    return NO;
  }
  _applyChangeCount++;
  _globalApplyChangeCount++;
  _state = change.state;
  return YES;
}

- (BOOL)verifyChange:(CKDataSourceChange *)change
{
  _verifyChangeCount++;
  _globalVerifyChangeCount++;
  return change.previousState == _state;
}

- (void)sendNewState
{
  [self sendNewStateWithSizeRange:_state.configuration.sizeRange];
}

- (void)sendNewStateWithSizeRange:(CKSizeRange)sizeRange
{
  const auto previousState = _state;
  const auto configuration =
  [[CKDataSourceConfiguration alloc]
   initWithComponentProviderFunc:componentProvider
   context:previousState.configuration.context
   sizeRange:sizeRange
   options:previousState.configuration.options
   componentPredicates:previousState.configuration.componentPredicates
   componentControllerPredicates:previousState.configuration.componentControllerPredicates
   analyticsListener:previousState.configuration.analyticsListener];
  _state = [[CKDataSourceState alloc] initWithConfiguration:configuration sections:@[]];
}

@end
