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

#import "CKComponent.h"
#import "CKComponentProvider.h"
#import "CKComponentScope.h"
#import "CKComponentSubclass.h"
#import "CKCompositeComponent.h"
#import "CKComponentController.h"
#import "CKCollectionViewTransactionalDataSource.h"
#import "CKDataSourceConfiguration.h"
#import "CKDataSourceConfigurationInternal.h"
#import "CKDataSourceChangeset.h"

@interface CKDataSourceIntegrationTestComponent : CKCompositeComponent
@end

@implementation CKDataSourceIntegrationTestComponent

+ (instancetype)newWithIdentifier:(id)identifier
{
  CKComponentScope scope(self, identifier);
  return [self newWithComponent:[CKComponent new]];
}
@end

@interface CKDataSourceIntegrationTestComponentController : CKComponentController
@property (strong) NSMutableArray *callbacks;
@end

@implementation CKDataSourceIntegrationTestComponentController

typedef NS_ENUM(NSUInteger, CKTestConfig) {
  CKTestConfigDefault,
};

- (instancetype)initWithComponent:(CKComponent *)component
{
  if ((self = [super initWithComponent:component])) {
    _callbacks = [NSMutableArray array];
  }
  return self;
}

- (void)willUpdateComponent {
  [super willUpdateComponent];
  [self.callbacks addObject:NSStringFromSelector(_cmd)];
}
- (void)willRemount {
  [super willRemount];
  [self.callbacks addObject:NSStringFromSelector(_cmd)];
}
- (void)didRemount {
  [super didRemount];
  [self.callbacks addObject:NSStringFromSelector(_cmd)];
}
- (void)didUpdateComponent {
  [super didUpdateComponent];
  [self.callbacks addObject:NSStringFromSelector(_cmd)];
}
- (void)invalidateController
{
  [super invalidateController];
  [self.callbacks addObject:NSStringFromSelector(_cmd)];
}
@end

@interface CKDataSourceIntegrationTests : XCTestCase
@property (strong) UICollectionViewController *collectionViewController;
@property (strong) CKCollectionViewTransactionalDataSource *dataSource;
@property (strong) NSMutableArray<CKComponent *> *components;
@property (strong) NSMutableDictionary<NSString *, CKComponent *> *componentsDictionary;
@property (strong) CKDataSourceIntegrationTestComponentController *componentController;
@property (assign) CGSize itemSize;
@end

@implementation CKDataSourceIntegrationTests

- (void)setUp
{
  [super setUp];

  self.itemSize = [[UIScreen mainScreen] bounds].size;

  UICollectionViewFlowLayout *flowLayout = [UICollectionViewFlowLayout new];
  flowLayout.itemSize = self.itemSize;

  self.collectionViewController = [[UICollectionViewController alloc]
                                   initWithCollectionViewLayout:flowLayout];

  self.components = [NSMutableArray new];
  self.componentsDictionary = [NSMutableDictionary dictionary];
  self.dataSource = [self generateDataSource:CKTestConfigDefault];

  [self.dataSource applyChangeset:
   [[[[CKDataSourceChangesetBuilder new]
      withInsertedSections:[NSIndexSet indexSetWithIndex:0]]
     withInsertedItems:@{ [NSIndexPath indexPathForItem:0 inSection:0] : @"" }]
    build] mode:CKUpdateModeSynchronous userInfo:nil];

  XCTAssertEqual(self.components.count, 1);
  XCTAssertNotNil(self.components.lastObject.controller);
  XCTAssertTrue([self.components.lastObject.controller isKindOfClass:[CKDataSourceIntegrationTestComponentController class]]);

  self.componentController =
  (CKDataSourceIntegrationTestComponentController*) self.components.lastObject.controller;
}

- (CKCollectionViewTransactionalDataSource *)generateDataSource:(CKTestConfig)testConfig
{
  CKDataSourceConfiguration *config = [[CKDataSourceConfiguration alloc]
                                       initWithComponentProvider:(id) self
                                       context:nil
                                       sizeRange:CKSizeRange(self.itemSize, self.itemSize)
                                       componentLayoutCacheEnabled:NO
                                       componentPredicates:{}
                                       componentControllerPredicates:{}
                                       analyticsListener:nil
                                       ];

  return [[CKCollectionViewTransactionalDataSource alloc] initWithCollectionView:self.collectionViewController.collectionView
                                                     supplementaryViewDataSource:nil
                                                                   configuration:config];
}

- (CKComponent *)componentForModel:(NSString*)model context:(id<NSObject>)context
{
  CKComponent *component = [CKDataSourceIntegrationTestComponent newWithIdentifier:model];
  [self.components addObject:component];
  self.componentsDictionary[model] = component;
  return component;
}

- (void)testUpdateModelShouldCreateNewComponentAndTriggerControllerCallbacksForRemount
{
  [self.dataSource applyChangeset:
   [[[CKDataSourceChangesetBuilder new]
     withUpdatedItems:@{[NSIndexPath indexPathForItem:0 inSection:0] : @""}]
    build] mode:CKUpdateModeSynchronous userInfo:nil];

  XCTAssertEqual(self.components.count, 2);
  XCTAssertEqualObjects(self.componentController.callbacks, (@[
                                                              NSStringFromSelector(@selector(willUpdateComponent)),
                                                              NSStringFromSelector(@selector(willRemount)),
                                                              NSStringFromSelector(@selector(didRemount)),
                                                              NSStringFromSelector(@selector(didUpdateComponent))
                                                              ]));
}

- (void)testUpdateModelAlwaysSendUpdateControllerCallbacks_Off
{
  self.dataSource = [self generateDataSource:CKTestConfigDefault];

  [self.dataSource applyChangeset:
   [[[[CKDataSourceChangesetBuilder new]
      withInsertedSections:[NSIndexSet indexSetWithIndex:0]]
     withInsertedItems:@{ [NSIndexPath indexPathForItem:0 inSection:0] : @"0",
                          [NSIndexPath indexPathForItem:1 inSection:0] : @"1",
                          [NSIndexPath indexPathForItem:2 inSection:0] : @"2",
                          }]
    build] mode:CKUpdateModeSynchronous userInfo:nil];

  [self.dataSource applyChangeset:
   [[[CKDataSourceChangesetBuilder new]
     withUpdatedItems:@{[NSIndexPath indexPathForItem:2 inSection:0] : @"2"}]
    build] mode:CKUpdateModeSynchronous userInfo:nil];

  CKDataSourceIntegrationTestComponentController *controller =
  (CKDataSourceIntegrationTestComponentController*)self.componentsDictionary[@"2"].controller;

  // We use 'CKTestConfigDefault' and item is out of the view port. It means it shoudn't get any update.
  XCTAssertEqualObjects(controller.callbacks, (@[]));
}

// This test checks that controller receives invalidateController callback when DataSource owning it
// applies change that removes it from the state
- (void)testComponentControllerReceivesInvalidateEventWhenRemoved
{
  [self.dataSource applyChangeset:
   [[[CKDataSourceChangesetBuilder new]
     withRemovedItems:[NSSet setWithObject:[NSIndexPath indexPathForItem:0 inSection:0]]]
    build] mode:CKUpdateModeSynchronous userInfo:nil];
  self.dataSource = nil;
  XCTAssertEqualObjects(self.componentController.callbacks, (@[
                                                               NSStringFromSelector(@selector(invalidateController)),
                                                               ]));
}

// This test checks that controller receives invalidateController callback when DataSource owning it is destroyed
- (void)testComponentControllerReceivesInvalidateEventDuringDeallocation
{
  NSArray *callbacks = nil;
  @autoreleasepool {
    self.dataSource = [self generateDataSource:CKTestConfigDefault];

    [self.dataSource applyChangeset:
     [[[[CKDataSourceChangesetBuilder new]
        withInsertedSections:[NSIndexSet indexSetWithIndex:0]]
       withInsertedItems:@{ [NSIndexPath indexPathForItem:0 inSection:0] : @"" }]
      build] mode:CKUpdateModeSynchronous userInfo:nil];

    CKDataSourceIntegrationTestComponentController * controller =
      (CKDataSourceIntegrationTestComponentController*) self.components.lastObject.controller;
    callbacks = controller.callbacks;

    // We clean everything to ensure dataSource receives deallocation happens when autorelease pool is destroyed
    self.dataSource = nil;
  }
  XCTAssertEqualObjects(callbacks, (@[NSStringFromSelector(@selector(invalidateController))]));
}

@end
