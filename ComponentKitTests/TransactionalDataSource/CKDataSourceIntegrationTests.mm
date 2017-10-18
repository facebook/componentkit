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
  CKTestConfigAlwaysSendUpdates,
};

- (instancetype)initWithComponent:(CKComponent *)component
{
  if ((self = [super initWithComponent:component])) {
    self.callbacks = [NSMutableArray array];
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
@property (strong) NSMutableArray <CKComponent *> *components;
@property (strong) CKDataSourceIntegrationTestComponentController *componentController;
@end

@implementation CKDataSourceIntegrationTests

- (void)setUp
{
  [super setUp];

  self.collectionViewController = [[UICollectionViewController alloc]
                                   initWithCollectionViewLayout:[UICollectionViewFlowLayout new]];

  self.components = [NSMutableArray new];
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
                                                             sizeRange:CKSizeRange({50, 50}, {50, 50})
                                                             alwaysSendComponentUpdate:(testConfig == CKTestConfigAlwaysSendUpdates)
                                                             forceAutorelease:NO
                                                             componentPredicates:{}
                                                             componentControllerPredicates:{}
                                                             ];

  return [[CKCollectionViewTransactionalDataSource alloc] initWithCollectionView:self.collectionViewController.collectionView
                                                     supplementaryViewDataSource:nil
                                                                   configuration:config];
}

- (CKComponent *)componentForModel:(NSString*)model context:(id<NSObject>)context
{
  CKComponent *component = [CKDataSourceIntegrationTestComponent newWithIdentifier:@"TestComponent"];
  [self.components addObject:component];
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

- (void)testUpdateModelAlwaysSendUpdateControllerCallbacks
{
  self.dataSource = [self generateDataSource:CKTestConfigAlwaysSendUpdates];

  [self.dataSource applyChangeset:
   [[[[CKDataSourceChangesetBuilder new]
      withInsertedSections:[NSIndexSet indexSetWithIndex:0]]
     withInsertedItems:@{ [NSIndexPath indexPathForItem:0 inSection:0] : @"" }]
    build] mode:CKUpdateModeSynchronous userInfo:nil];

  [self.dataSource applyChangeset:
   [[[CKDataSourceChangesetBuilder new]
     withUpdatedItems:@{[NSIndexPath indexPathForItem:0 inSection:0] : @""}]
    build] mode:CKUpdateModeSynchronous userInfo:nil];

  CKDataSourceIntegrationTestComponentController * controller =
    (CKDataSourceIntegrationTestComponentController*) self.components.lastObject.controller;
  [controller.callbacks count];

  XCTAssertEqualObjects(controller.callbacks, (@[
                                                               NSStringFromSelector(@selector(willUpdateComponent)),
                                                               NSStringFromSelector(@selector(willRemount)),
                                                               NSStringFromSelector(@selector(didRemount)),
                                                               NSStringFromSelector(@selector(didUpdateComponent))
                                                               ]));
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
