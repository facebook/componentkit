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
#import "CKCompositeComponent.h"
#import "CKComponentController.h"
#import "CKCollectionViewTransactionalDataSource.h"
#import "CKTransactionalComponentDataSourceConfiguration.h"
#import "CKTransactionalComponentDataSourceChangeset.h"

static NSNotificationCenter *_notificationCenter = nil;

@interface CKTransactionalComponentDataSourceIntegrationTestComponent : CKCompositeComponent
@end

@implementation CKTransactionalComponentDataSourceIntegrationTestComponent
+ (instancetype)newWithIdentifier:(id)identifier {
  CKComponentScope scope(self, identifier);
  return [self newWithComponent:[CKComponent new]];
}
@end

@interface CKTransactionalComponentDataSourceIntegrationTestComponentController : CKComponentController
@end

@implementation CKTransactionalComponentDataSourceIntegrationTestComponentController
- (void)didUpdateComponent {
  [super didUpdateComponent];
  [_notificationCenter postNotificationName:NSStringFromSelector(_cmd) object:self];
}
- (void)willRemount {
  [super willRemount];
  [_notificationCenter postNotificationName:NSStringFromSelector(_cmd) object:self];
}
- (void)didRemount {
  [super didRemount];
  [_notificationCenter postNotificationName:NSStringFromSelector(_cmd) object:self];
}
@end

@interface CKTransactionalComponentDataSourceIntegrationTests : XCTestCase <CKComponentProvider>
@property (strong) UICollectionViewController *collectionViewController;
@property (strong) CKCollectionViewTransactionalDataSource *dataSource;
@property (strong) CKComponentController *componentController;
@property (strong) id observerMock;
@end

@implementation CKTransactionalComponentDataSourceIntegrationTests

- (void)setUp {
  [super setUp];

  self.collectionViewController = [[UICollectionViewController alloc]
                                   initWithCollectionViewLayout:[UICollectionViewFlowLayout new]];

  CKTransactionalComponentDataSourceConfiguration *config = [[CKTransactionalComponentDataSourceConfiguration alloc]
                                                             initWithComponentProvider:self.class
                                                             context:nil
                                                             sizeRange:CKSizeRange({50, 50}, {50, 50})];

  self.dataSource = [[CKCollectionViewTransactionalDataSource alloc]
                     initWithCollectionView:self.collectionViewController.collectionView
                     supplementaryViewDataSource:nil
                     configuration:config];

  _notificationCenter = [[NSNotificationCenter alloc] init];

  self.observerMock = [OCMockObject observerMock];
  [_notificationCenter addMockObserver:self.observerMock name:nil object:nil];

  [[self.observerMock expect] notificationWithName:NSStringFromSelector(@selector(didUpdateComponent))
                                            object:[OCMArg checkWithBlock:^BOOL(CKComponentController *c)
                                                    {
                                                      self.componentController = c;
                                                      return YES;
                                                    }]];
  
  [self.dataSource applyChangeset:
   [[[[CKTransactionalComponentDataSourceChangesetBuilder new]
      withInsertedSections:[NSIndexSet indexSetWithIndex:0]]
     withInsertedItems:@{ [NSIndexPath indexPathForItem:0 inSection:0] : @"" }]
    build] mode:CKUpdateModeSynchronous userInfo:nil];
}

- (void)tearDown {
  [self.observerMock verify];
  [_notificationCenter removeObserver:self.observerMock];
  _notificationCenter = nil;
  [super tearDown];
}

+ (CKComponent *)componentForModel:(NSString*)model context:(id<NSObject>)context {
  return [CKTransactionalComponentDataSourceIntegrationTestComponent newWithIdentifier:@"TestComponent"];
}

- (void)testUpdateItemWithMatchingIdentifierShouldTriggerRemountInComponentController
{
  [[self.observerMock expect] notificationWithName:NSStringFromSelector(@selector(didUpdateComponent))
                                            object:self.componentController];
  [[self.observerMock expect] notificationWithName:NSStringFromSelector(@selector(willRemount))
                                            object:self.componentController];
  [[self.observerMock expect] notificationWithName:NSStringFromSelector(@selector(didRemount))
                                            object:self.componentController];

  [self.dataSource applyChangeset:
   [[[CKTransactionalComponentDataSourceChangesetBuilder new]
     withUpdatedItems:@{[NSIndexPath indexPathForItem:0 inSection:0] : @""}]
    build] mode:CKUpdateModeSynchronous userInfo:nil];
}

@end
