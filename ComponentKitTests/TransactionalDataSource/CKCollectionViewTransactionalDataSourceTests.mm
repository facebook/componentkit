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

#import <ComponentKit/CKCollectionViewTransactionalDataSource.h>
#import <ComponentKit/CKTransactionalComponentDataSourceConfiguration.h>
#import <ComponentKit/CKTransactionalComponentDataSourceChangeset.h>
#import <ComponentKit/CKSupplementaryViewDataSource.h>
#import <ComponentKit/CKCollectionViewDataSourceCell.h>
#import <ComponentKit/CKComponentDataSourceAttachControllerInternal.h>
#import <ComponentKit/CKComponentRootView.h>
#import <ComponentKit/CKComponentProvider.h>
#import <ComponentKit/CKComponent.h>

#import "CKTransactionalComponentDataSourceStateTestHelpers.h"

@interface CKTestModelComponent : CKComponent
@property (nonatomic, strong, readonly) id<NSObject> model;
+ (instancetype)newWithModel:(id<NSObject>)context;
@end

@implementation CKTestModelComponent

+ (instancetype)newWithModel:(id<NSObject>)model
{
  CKTestModelComponent *c = [super newWithView:{} size:{}];
  if (c) {
    c->_model = model;
  }
  return c;
}

@end

static id<NSObject> CKMountedModelAtIndexPath(UICollectionView *collectionView, NSIndexPath *indexPath)
{
  CKCollectionViewDataSourceCell *cell = (CKCollectionViewDataSourceCell *)[collectionView cellForItemAtIndexPath:indexPath];
  CKComponentDataSourceAttachState *attachState = cell.rootView.ck_attachState;
  if (!attachState)
    return nil;
  
  return [(CKTestModelComponent *)attachState.layout.component model];
}

@interface CKCollectionViewTransactionalDataSource () <UICollectionViewDataSource>
@end

@interface CKCollectionViewTransactionalDataSourceTests : XCTestCase <CKComponentProvider>
@property (strong) CKCollectionViewTransactionalDataSource *dataSource;
@property (strong) UICollectionView *collectionView;
@property (strong) id mockSupplementaryViewDataSource;
@end

@implementation CKCollectionViewTransactionalDataSourceTests

+ (CKComponent *)componentForModel:(id<NSObject>)model context:(id<NSObject>)context
{
  return [CKTestModelComponent newWithModel:model];
}

- (void)setUp
{
  [super setUp];
  
  UICollectionViewFlowLayout *collectionViewLayout = [UICollectionViewFlowLayout new];
  self.collectionView = [[UICollectionView alloc] initWithFrame:{0, 0, 100, 1000} collectionViewLayout:collectionViewLayout];
  
  self.mockSupplementaryViewDataSource = [OCMockObject mockForProtocol:@protocol(CKSupplementaryViewDataSource)];

  CKTransactionalComponentDataSourceConfiguration *config = [[CKTransactionalComponentDataSourceConfiguration alloc]
                                                             initWithComponentProvider:[self class]
                                                             context:nil
                                                             sizeRange:{{100, 10}, {100, 10}}];

  self.dataSource = [[CKCollectionViewTransactionalDataSource alloc]
                     initWithCollectionView:self.collectionView
                     supplementaryViewDataSource:self.mockSupplementaryViewDataSource
                     configuration:config];
  
  CKTransactionalComponentDataSourceChangeset *changeset =
  [[[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
     withInsertedSections:[NSIndexSet indexSetWithIndex:0]]
    withInsertedItems:@{[NSIndexPath indexPathForItem:0 inSection:0]: @0,
                        [NSIndexPath indexPathForItem:1 inSection:0]: @1,
                        [NSIndexPath indexPathForItem:2 inSection:0]: @2}]
   build];
  
  [self.dataSource applyChangeset:changeset mode:CKUpdateModeSynchronous userInfo:nil];
}

- (void)testSupplementaryViewDataSource
{
  NSIndexPath *indexPath = [NSIndexPath indexPathForItem:3 inSection:4];
  NSString *viewKind = @"foo";
  
  [[self.mockSupplementaryViewDataSource expect] collectionView:self.collectionView viewForSupplementaryElementOfKind:viewKind atIndexPath:indexPath];
  [self.dataSource collectionView:self.collectionView viewForSupplementaryElementOfKind:viewKind atIndexPath:indexPath];
}

- (void)testRemovingAndUpdatingSimultaneously
{
  NSIndexPath *firstIndexPath = [NSIndexPath indexPathForItem:0 inSection:0];
  CKTransactionalComponentDataSourceChangeset *changeset =
  [[[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
     withUpdatedItems:@{[NSIndexPath indexPathForItem:1 inSection:0]: @"updated"}]
    withRemovedItems:[NSSet setWithObject:firstIndexPath]]
   build];
  
  [self.dataSource applyChangeset:changeset mode:CKUpdateModeSynchronous userInfo:nil];
  
  XCTAssertEqualObjects(CKMountedModelAtIndexPath(self.collectionView, firstIndexPath), @"updated");
}

@end
