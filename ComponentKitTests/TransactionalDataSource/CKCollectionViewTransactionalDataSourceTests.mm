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

#import "CKCollectionViewTransactionalDataSource.h"
#import "CKTransactionalComponentDataSourceConfiguration.h"
#import "CKTransactionalComponentDataSourceChangeset.h"
#import "CKSizeRange.h"

@interface CKCollectionViewTransactionalDataSource () <UICollectionViewDataSource>
@end

@interface CKCollectionViewTransactionalDataSourceTests : XCTestCase
@property (strong) CKCollectionViewTransactionalDataSource *dataSource;
@property (strong) id mockCollectionView;
@end

@implementation CKCollectionViewTransactionalDataSourceTests

- (void)setUp {
  [super setUp];

  self.mockCollectionView = [OCMockObject niceMockForClass:[UICollectionView class]];

  CKTransactionalComponentDataSourceConfiguration *config = [[CKTransactionalComponentDataSourceConfiguration alloc]
                                                             initWithComponentProvider:nil
                                                             context:nil
                                                             sizeRange:CKSizeRange()];

  self.dataSource = [[CKCollectionViewTransactionalDataSource alloc]
                     initWithCollectionView:self.mockCollectionView
                     supplementaryViewDataSource:nil
                     configuration:config];
}

- (void)testRemoveAllItems
{
  NSIndexSet *sections = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 3)];
  NSDictionary *items = @{
                          [NSIndexPath indexPathForItem:0 inSection:0] : @"0-0",
                          [NSIndexPath indexPathForItem:0 inSection:1] : @"0-1",
                          [NSIndexPath indexPathForItem:1 inSection:1] : @"1-1",
                          [NSIndexPath indexPathForItem:0 inSection:2] : @"0-2",
                          [NSIndexPath indexPathForItem:1 inSection:2] : @"1-2",
                          [NSIndexPath indexPathForItem:2 inSection:2] : @"2-2"
                          };

  [[[self.mockCollectionView stub] andDo:^(NSInvocation *invocation) {
    dispatch_block_t block;
    [invocation getArgument:&block atIndex:2];
    block();
  }] performBatchUpdates:[OCMArg any] completion:[OCMArg any]];

  CKTransactionalComponentDataSourceChangeset *changeSet = [[CKTransactionalComponentDataSourceChangeset alloc]
                                                            initWithUpdatedItems:nil
                                                            removedItems:nil
                                                            removedSections:nil
                                                            movedItems:nil 
                                                            insertedSections:sections
                                                            insertedItems:items];
  [self.dataSource applyChangeset:changeSet mode:CKUpdateModeSynchronous userInfo:nil];

  id expectEmptyArray = [OCMArg checkWithBlock:^BOOL(NSArray *array) {
    return array.count == 0;
  }];

  [[self.mockCollectionView expect] deleteSections:sections];
  [[self.mockCollectionView expect] deleteItemsAtIndexPaths:items.allKeys];

  [[self.mockCollectionView expect] reloadItemsAtIndexPaths:expectEmptyArray];
  [[self.mockCollectionView expect] insertItemsAtIndexPaths:expectEmptyArray];
  [[self.mockCollectionView expect] moveItemAtIndexPath:[OCMArg any] toIndexPath:[OCMArg any]];
  [[self.mockCollectionView expect] insertSections:[OCMArg checkWithBlock:^BOOL(NSIndexSet *sections) {
    return sections.count == 0;
  }]];

  [self.dataSource removeAllWithMode:CKUpdateModeSynchronous userInfo:nil];
}

@end
