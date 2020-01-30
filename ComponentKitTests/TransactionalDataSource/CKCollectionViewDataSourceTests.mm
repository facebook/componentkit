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
#import <OCMock/OCMock.h>
#import <UIKit/UIKit.h>

#import <ComponentKit/CKCollectionViewDataSource.h>
#import <ComponentKit/CKCollectionViewDataSourceListener.h>
#import <ComponentKit/CKDataSourceChangeset.h>
#import <ComponentKit/CKDataSourceConfiguration.h>
#import <ComponentKit/CKDataSourceState.h>
#import <ComponentKit/CKDataSourceStateInternal.h>
#import <ComponentKit/CKSupplementaryViewDataSource.h>
#import <ComponentKit/CKSizeRange.h>

#import <ComponentKit/CKCollectionViewDataSourceInternal.h>

@interface CKCollectionViewDataSource () <UICollectionViewDataSource>
@end

@interface CKCollectionViewDataSourceSpy : NSObject <CKCollectionViewDataSourceListener>
@property (nonatomic, assign) NSUInteger willApplyChangeset;
@property (nonatomic, assign) NSUInteger didApplyChangeset;
@property (nonatomic, assign) NSUInteger willChangeState;
@property (nonatomic, assign) NSUInteger didChangeState;
@property (nonatomic, retain) id state;
@property (nonatomic, retain) id previousState;
@end

@interface CKCollectionViewDataSourceTests : XCTestCase
@property (nonatomic, strong) CKCollectionViewDataSource *dataSource;
@property (nonatomic, strong) id mockCollectionView;
@property (nonatomic, strong) id mockSupplementaryViewDataSource;
@end

@implementation CKCollectionViewDataSourceTests

- (void)setUp {
  [super setUp];

  self.mockSupplementaryViewDataSource = [OCMockObject mockForProtocol:@protocol(CKSupplementaryViewDataSource)];
  self.mockCollectionView = [OCMockObject niceMockForClass:[UICollectionView class]];

  CKDataSourceConfiguration *config = [[CKDataSourceConfiguration alloc]
                                       initWithComponentProviderFunc:nullptr
                                       context:nil
                                       sizeRange:CKSizeRange()];

  self.dataSource = [[CKCollectionViewDataSource alloc]
                     initWithCollectionView:self.mockCollectionView
                     supplementaryViewDataSource:self.mockSupplementaryViewDataSource
                     configuration:config];
}

- (void)testSupplementaryViewDataSource
{
  NSIndexPath *indexPath = [NSIndexPath indexPathForItem:3 inSection:4];
  NSString *viewKind = @"foo";

  [[self.mockSupplementaryViewDataSource expect] collectionView:self.mockCollectionView viewForSupplementaryElementOfKind:viewKind atIndexPath:indexPath];
  [self.dataSource collectionView:self.mockCollectionView viewForSupplementaryElementOfKind:viewKind atIndexPath:indexPath];
}

- (void)testDataSourceListenerApplyChangeset
{
  OCMStub([self.mockCollectionView performBatchUpdates:[OCMArg any] completion:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
    void(^block)(BOOL completed);
    [invocation getArgument:&block atIndex:3];
    block(YES);
  });

  auto const spy = [CKCollectionViewDataSourceSpy new];
  [self.dataSource addListener:spy];

  [self.dataSource applyChangeset:
   [[[[CKDataSourceChangesetBuilder new]
      withInsertedSections:[NSIndexSet indexSetWithIndex:0]]
     withInsertedItems:@{ [NSIndexPath indexPathForItem:0 inSection:0] : @"" }]
    build] mode:CKUpdateModeSynchronous userInfo:nil];

  XCTAssertEqual(spy.willApplyChangeset, 1);
  XCTAssertEqual(spy.didApplyChangeset, 1);
  XCTAssertNotEqual(spy.state, spy.previousState);
}

- (void)testDataSourceListenerSetState
{
  auto const spy = [CKCollectionViewDataSourceSpy new];
  [self.dataSource addListener:spy];

  id configuration = [[CKDataSourceConfiguration alloc] initWithComponentProviderFunc:nullptr context:nil sizeRange:{}];
  id newState = [[CKDataSourceState alloc] initWithConfiguration:configuration sections:@[]];

  [self.dataSource setState:newState];

  XCTAssertEqual(spy.willChangeState, 1);
  XCTAssertEqual(spy.didChangeState, 1);
  XCTAssertEqual(newState, spy.state);
  XCTAssertNotEqual(newState, spy.previousState);
}

@end

@implementation CKCollectionViewDataSourceSpy

- (void)dataSourceWillBeginUpdates:(CKCollectionViewDataSource *)dataSource
{
  _willApplyChangeset++;
}

- (void)dataSourceDidEndUpdates:(CKCollectionViewDataSource *)dataSource
         didModifyPreviousState:(CKDataSourceState *)previousState
                      withState:(CKDataSourceState *)state
              byApplyingChanges:(CKDataSourceAppliedChanges *)changes
{
  _didApplyChangeset++;
  _previousState = previousState;
  _state = state;
}

- (void)dataSource:(CKCollectionViewDataSource *)dataSource
   willChangeState:(CKDataSourceState *)state
{
  _willChangeState++;
}

- (void)dataSource:(CKCollectionViewDataSource *)dataSource
    didChangeState:(CKDataSourceState *)previousState
         withState:(CKDataSourceState *)state
{
  _didChangeState++;
  _previousState = previousState;
  _state = state;
}

@end
