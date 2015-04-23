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

#import "CKComponent.h"
#import "CKComponentProvider.h"
#import "CKTestRunLoopRunning.h"
#import "CKTransactionalComponentDataSource.h"
#import "CKTransactionalComponentDataSourceAppliedChangesInternal.h"
#import "CKTransactionalComponentDataSourceChangeset.h"
#import "CKTransactionalComponentDataSourceConfiguration.h"
#import "CKTransactionalComponentDataSourceListener.h"
#import "CKTransactionalComponentDataSourceState.h"

@interface CKTransactionalComponentDataSourceTests : XCTestCase <CKComponentProvider, CKTransactionalComponentDataSourceListener>
@end

struct CKDataSourceAnnouncedUpdate {
  CKTransactionalComponentDataSourceState *previousState;
  CKTransactionalComponentDataSourceAppliedChanges *appliedChanges;
};

@implementation CKTransactionalComponentDataSourceTests
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
  CKTransactionalComponentDataSource *ds =
  [[CKTransactionalComponentDataSource alloc] initWithConfiguration:
   [[CKTransactionalComponentDataSourceConfiguration alloc] initWithComponentProvider:[self class]
                                                                              context:nil
                                                                            sizeRange:{}]];
  XCTAssertEqual([[ds state] numberOfSections], (NSUInteger)0);
}

- (void)testSynchronouslyInsertingItemsAnnouncesInsertion
{
  CKTransactionalComponentDataSource *ds =
  [[CKTransactionalComponentDataSource alloc] initWithConfiguration:
   [[CKTransactionalComponentDataSourceConfiguration alloc] initWithComponentProvider:[self class]
                                                                              context:nil
                                                                            sizeRange:{}]];
  [ds addListener:self];

  CKTransactionalComponentDataSourceChangeset *insertion =
  [[[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
     withInsertedSections:[NSIndexSet indexSetWithIndex:0]]
    withInsertedItems:@{[NSIndexPath indexPathForItem:0 inSection:0]: @1}]
   build];
  [ds applyChangeset:insertion mode:CKTransactionalComponentDataSourceModeSynchronous userInfo:nil];

  CKTransactionalComponentDataSourceAppliedChanges *expectedAppliedChanges =
  [[CKTransactionalComponentDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:nil
                                                                    removedIndexPaths:nil
                                                                      removedSections:nil
                                                                      movedIndexPaths:nil
                                                                     insertedSections:[NSIndexSet indexSetWithIndex:0]
                                                                   insertedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:0 inSection:0]]
                                                                            userInfos:nil];

  XCTAssertEqualObjects(_announcedChanges[0].appliedChanges, expectedAppliedChanges);
}

- (void)testAsynchronouslyInsertingItemsAnnouncesInsertionAsynchronously
{
  CKTransactionalComponentDataSource *ds =
  [[CKTransactionalComponentDataSource alloc] initWithConfiguration:
   [[CKTransactionalComponentDataSourceConfiguration alloc] initWithComponentProvider:[self class]
                                                                              context:nil
                                                                            sizeRange:{}]];
  [ds addListener:self];

  CKTransactionalComponentDataSourceChangeset *insertion =
  [[[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
     withInsertedSections:[NSIndexSet indexSetWithIndex:0]]
    withInsertedItems:@{[NSIndexPath indexPathForItem:0 inSection:0]: @1}]
   build];
  [ds applyChangeset:insertion mode:CKTransactionalComponentDataSourceModeAsynchronous userInfo:nil];

  CKTransactionalComponentDataSourceAppliedChanges *expectedAppliedChanges =
  [[CKTransactionalComponentDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:nil
                                                                    removedIndexPaths:nil
                                                                      removedSections:nil
                                                                      movedIndexPaths:nil
                                                                     insertedSections:[NSIndexSet indexSetWithIndex:0]
                                                                   insertedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:0 inSection:0]]
                                                                            userInfos:nil];

  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL(void){
    return _announcedChanges.size() == 1 && [_announcedChanges[0].appliedChanges isEqual:expectedAppliedChanges];
  }));
}

#pragma mark - Listener

- (void)transactionalComponentDataSource:(CKTransactionalComponentDataSource *)dataSource
                  didModifyPreviousState:(CKTransactionalComponentDataSourceState *)previousState
                       byApplyingChanges:(CKTransactionalComponentDataSourceAppliedChanges *)changes
{
  _announcedChanges.push_back({previousState, changes});
}

@end
