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
#import <ComponentKit/CKDataSourceConfiguration.h>
#import <ComponentKit/CKSupplementaryViewDataSource.h>
#import <ComponentKit/CKSizeRange.h>

@interface CKCollectionViewDataSource () <UICollectionViewDataSource>
@end

@interface CKCollectionViewDataSourceTests : XCTestCase
@property (strong) CKCollectionViewDataSource *dataSource;
@property (strong) id mockCollectionView;
@property (strong) id mockSupplementaryViewDataSource;
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

@end
