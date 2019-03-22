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
#import <ComponentKit/CKSupplementaryViewDataSource.h>
#import <ComponentKit/CKSizeRange.h>

#import "CKCollectionViewDataSourceInternal.h"

@interface CKCollectionViewDataSource () <UICollectionViewDataSource>
@end

@interface CKCollectionViewDataSourceSpy : NSObject <CKCollectionViewDataSourceListener>
@property (nonatomic, assign) NSUInteger willApplyChangeset;
@property (nonatomic, assign) NSUInteger didApplyChangeset;
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
                                       initWithComponentProvider:nil
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

- (void)testDataSourceListener
{
  OCMStub([self.mockCollectionView performBatchUpdates:[OCMArg any] completion:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
    void(^block)(BOOL completed);
    [invocation getArgument:&block atIndex:3];
    block(YES);
  });

  CKCollectionViewDataSourceSpy *spy = [CKCollectionViewDataSourceSpy new];
  [self.dataSource addListener:spy];

  [self.dataSource applyChangeset:
   [[[[CKDataSourceChangesetBuilder new]
      withInsertedSections:[NSIndexSet indexSetWithIndex:0]]
     withInsertedItems:@{ [NSIndexPath indexPathForItem:0 inSection:0] : @"" }]
    build] mode:CKUpdateModeSynchronous userInfo:nil];

  XCTAssertEqual(spy.willApplyChangeset, 1);
  XCTAssertEqual(spy.didApplyChangeset, 1);
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
}

@end
