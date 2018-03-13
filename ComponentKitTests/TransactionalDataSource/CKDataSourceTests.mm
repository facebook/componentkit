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

#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKComponentProvider.h>
#import <ComponentKit/CKDataSource.h>
#import <ComponentKit/CKDataSourceAppliedChanges.h>
#import <ComponentKit/CKDataSourceChangeset.h>
#import <ComponentKit/CKDataSourceConfiguration.h>
#import <ComponentKit/CKDataSourceListener.h>
#import <ComponentKit/CKDataSourceState.h>

#import "CKDataSourceStateTestHelpers.h"

@interface CKDataSourceTests : XCTestCase <CKComponentProvider, CKDataSourceListener>
@end

struct CKDataSourceAnnouncedUpdate {
  CKDataSourceState *previousState;
  CKDataSourceAppliedChanges *appliedChanges;
};

@implementation CKDataSourceTests
{
  std::vector<CKDataSourceAnnouncedUpdate> _announcedChanges;
}

+ (CKComponent *)componentForModel:(id<NSObject>)model context:(id<NSObject>)context
{
  return [CKComponent new];
}

- (void)tearDown
{
  _announcedChanges.clear();
  [super tearDown];
}

- (void)testDataSourceIsInitiallyEmpty
{
  CKDataSource *ds =
  [[CKDataSource alloc] initWithConfiguration:
   [[CKDataSourceConfiguration alloc] initWithComponentProvider:[self class]
                                                        context:nil
                                                      sizeRange:{}]];
  XCTAssertEqual([[ds state] numberOfSections], (NSUInteger)0);
}

- (void)testSynchronouslyInsertingItemsAnnouncesInsertion
{
  CKDataSource *ds =
  [[CKDataSource alloc] initWithConfiguration:
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

  XCTAssertEqualObjects(_announcedChanges[0].appliedChanges, expectedAppliedChanges);
}

- (void)testAsynchronouslyInsertingItemsAnnouncesInsertionAsynchronously
{
  CKDataSource *ds =
  [[CKDataSource alloc] initWithConfiguration:
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
    return _announcedChanges.size() == 1 && [_announcedChanges[0].appliedChanges isEqual:expectedAppliedChanges];
  }));
}

- (void)testUpdatingConfigurationAnnouncesUpdate
{
  CKDataSource *ds = CKTransactionalComponentTestDataSource([self class]);
  [ds addListener:self];

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

  XCTAssertEqual([[ds state] configuration], config);
  XCTAssertEqualObjects(_announcedChanges[0].appliedChanges, expectedAppliedChanges);
}

- (void)testReloadingAnnouncesUpdate
{
  CKDataSource *ds = CKTransactionalComponentTestDataSource([self class]);
  [ds addListener:self];
  [ds reloadWithMode:CKUpdateModeSynchronous userInfo:nil];

  CKDataSourceAppliedChanges *expectedAppliedChanges =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:0 inSection:0]]
                                              removedIndexPaths:nil
                                                removedSections:nil
                                                movedIndexPaths:nil
                                               insertedSections:nil
                                             insertedIndexPaths:nil
                                                       userInfo:nil];
  XCTAssertEqualObjects(_announcedChanges[0].appliedChanges, expectedAppliedChanges);
}

- (void)testSynchronousReloadCancelsPreviousAsynchronousReload
{
  CKDataSource *ds = CKTransactionalComponentTestDataSource([self class]);
  [ds addListener:self];

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
    return _announcedChanges.size() == 2
    && [_announcedChanges[0].appliedChanges isEqual:expectedAppliedChangesForSyncReload]
    && [_announcedChanges[1].appliedChanges isEqual:expectedAppliedChangesForSecondAsyncReload];
  }));
}

#pragma mark - Listener

- (void)componentDataSource:(CKDataSource *)dataSource
     didModifyPreviousState:(CKDataSourceState *)previousState
          byApplyingChanges:(CKDataSourceAppliedChanges *)changes
{
  _announcedChanges.push_back({previousState, changes});
}

@end
