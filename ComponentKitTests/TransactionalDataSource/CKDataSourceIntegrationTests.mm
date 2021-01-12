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

#import <Foundation/Foundation.h>

#import <ComponentKitTestHelpers/CKTestRunLoopRunning.h>

#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKComponentProvider.h>
#import <ComponentKit/CKComponentScope.h>
#import <ComponentKit/CKComponentSubclass.h>
#import <ComponentKit/CKCompositeComponent.h>
#import <ComponentKit/CKComponentController.h>
#import <ComponentKit/CKCollectionViewDataSource.h>
#import <ComponentKit/CKDataSourceConfiguration.h>
#import <ComponentKit/CKDataSourceConfigurationInternal.h>
#import <ComponentKit/CKDataSourceChangeset.h>

static NSString *const kOverrideDidPrepareLayoutForComponent = @"kOverrideDidPrepareLayoutForComponent";

@interface CKDataSourceIntegrationTestComponent : CKCompositeComponent
@end

@interface CKDataSourceIntegrationTestComponentController : CKComponentController
@property (strong) NSMutableArray *callbacks;
@end

@implementation CKDataSourceIntegrationTestComponent

+ (instancetype)newWithIdentifier:(id)identifier
{
  CKComponentScope scope(self, identifier);
  return [self newWithComponent:[CKComponent new]];
}

+ (Class<CKComponentControllerProtocol>)controllerClass
{
  return [CKDataSourceIntegrationTestComponentController class];
}

@end

@implementation CKDataSourceIntegrationTestComponentController

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

/**
 We will use this component in order to override the 'didPrepareLayoutForComponent'.
 */

@interface CKDataSourceIntegrationOverrideDidPrepareLayoutForComponentTestComponentController : CKDataSourceIntegrationTestComponentController
@property (nonatomic, strong) NSMutableArray<NSString *> *layoutComponentsFromCallbacks;
@property (nonatomic, strong) NSMutableArray<NSString *> *componentsFromCallbacks;
@end

@interface CKDataSourceIntegrationOverrideDidPrepareLayoutForComponentTestComponent : CKDataSourceIntegrationTestComponent
@end
@implementation CKDataSourceIntegrationOverrideDidPrepareLayoutForComponentTestComponent
+ (Class<CKComponentControllerProtocol>)controllerClass
{
  return [CKDataSourceIntegrationOverrideDidPrepareLayoutForComponentTestComponentController class];
}
@end

@implementation CKDataSourceIntegrationOverrideDidPrepareLayoutForComponentTestComponentController

- (instancetype)initWithComponent:(CKComponent *)component
{
  if (self = [super initWithComponent:component]) {
    _layoutComponentsFromCallbacks = [NSMutableArray array];
    _componentsFromCallbacks = [NSMutableArray array];
  }
  return self;
}

- (void)didPrepareLayout:(const RCLayout &)layout forComponent:(CKComponent *)component
{
  [self.callbacks addObject:NSStringFromSelector(_cmd)];
  [self.layoutComponentsFromCallbacks addObject:[NSString stringWithFormat:@"%p",layout.component]];
  [self.componentsFromCallbacks addObject:[NSString stringWithFormat:@"%p",component]];
}
@end

/**
 Tests start here.
 */

static NSMutableArray<CKComponent *> *g_components;
static NSMutableDictionary<NSString *, CKComponent *> *g_componentsDictionary;

@interface CKDataSourceIntegrationTests : XCTestCase
@property (strong) CKCollectionViewDataSource *dataSource;
@property (strong) CKDataSourceIntegrationTestComponentController *componentController;
@property (assign) CGSize itemSize;
@end

@implementation CKDataSourceIntegrationTests

- (void)setUp
{
  [super setUp];

  self.itemSize = CGSizeMake(320, 480);

  g_components = [NSMutableArray new];
  g_componentsDictionary = [NSMutableDictionary dictionary];
  self.dataSource = [self generateDataSource];

  [self.dataSource applyChangeset:
   [[[[CKDataSourceChangesetBuilder new]
      withInsertedSections:[NSIndexSet indexSetWithIndex:0]]
     withInsertedItems:@{ [NSIndexPath indexPathForItem:0 inSection:0] : @"" }]
    build] mode:CKUpdateModeSynchronous userInfo:nil];

  XCTAssertEqual(g_components.count, 1);
  XCTAssertNotNil(g_components.lastObject.controller);
  XCTAssertTrue([g_components.lastObject.controller isKindOfClass:[CKDataSourceIntegrationTestComponentController class]]);

  self.componentController =
  (CKDataSourceIntegrationTestComponentController*) g_components.lastObject.controller;
}

- (CKCollectionViewDataSource *)generateDataSource
{
  UICollectionViewFlowLayout *flowLayout = [UICollectionViewFlowLayout new];
  flowLayout.itemSize = self.itemSize;

  UICollectionView *collectionView =
  [[UICollectionView alloc]
   initWithFrame:CGRectMake(0, 0, self.itemSize.width, self.itemSize.height)
   collectionViewLayout:flowLayout];

  CKDataSourceConfiguration *config = [[CKDataSourceConfiguration alloc]
                                       initWithComponentProviderFunc:componentProvider
                                       context:nil
                                       sizeRange:CKSizeRange(self.itemSize, self.itemSize)
                                       options:{}
                                       componentPredicates:{}
                                       componentControllerPredicates:{}
                                       analyticsListener:nil];
  return [[CKCollectionViewDataSource alloc] initWithCollectionView:collectionView
                                                     supplementaryViewDataSource:nil
                                                                   configuration:config];
}

static CKComponent *componentProvider(id<NSObject> untypedModel, id<NSObject> _)
{
  NSString *const model = (NSString *)untypedModel;
  Class klass =
  [model isEqualToString:kOverrideDidPrepareLayoutForComponent]
  ? [CKDataSourceIntegrationOverrideDidPrepareLayoutForComponentTestComponent class]
  : [CKDataSourceIntegrationTestComponent class];

  CKComponent *component = [klass newWithIdentifier:model];
  [g_components addObject:component];
  g_componentsDictionary[model] = component;
  return component;
}

- (void)testUpdateModelShouldCreateNewComponentAndTriggerControllerCallbacksForRemount
{
  [self.dataSource applyChangeset:
   [[[CKDataSourceChangesetBuilder new]
     withUpdatedItems:@{[NSIndexPath indexPathForItem:0 inSection:0] : @""}]
    build] mode:CKUpdateModeSynchronous userInfo:nil];

  XCTAssertEqual(g_components.count, 2);
  XCTAssertEqualObjects(self.componentController.callbacks, (@[
                                                              NSStringFromSelector(@selector(willUpdateComponent)),
                                                              NSStringFromSelector(@selector(willRemount)),
                                                              NSStringFromSelector(@selector(didRemount)),
                                                              NSStringFromSelector(@selector(didUpdateComponent))
                                                              ]));
}

- (void)testUpdateModelAlwaysSendUpdateControllerCallbacks_Off
{
  self.dataSource = [self generateDataSource];

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
  (CKDataSourceIntegrationTestComponentController*)g_componentsDictionary[@"2"].controller;

  // We use 'CKTestConfigDefault' and item is out of the view port. It means it shoudn't get any update.
  XCTAssertEqualObjects(controller.callbacks, (@[NSStringFromSelector(@selector(willUpdateComponent))]));
}

- (void)testUpdateModelAlwaysSendUpdateControllerCallbacks_didPrepareLayoutForComponent_off
{
  self.dataSource = [self generateDataSource];

  [self.dataSource applyChangeset:
   [[[[CKDataSourceChangesetBuilder new]
      withInsertedSections:[NSIndexSet indexSetWithIndex:0]]
     withInsertedItems:@{ [NSIndexPath indexPathForItem:0 inSection:0] : @"0",
                          [NSIndexPath indexPathForItem:1 inSection:0] : @"1",
                          [NSIndexPath indexPathForItem:2 inSection:0] : @"2",
                          }]
    build] mode:CKUpdateModeSynchronous userInfo:nil];

  CKDataSourceIntegrationTestComponentController *controller =
  (CKDataSourceIntegrationTestComponentController*)g_componentsDictionary[@"2"].controller;

  XCTAssertEqualObjects(controller.callbacks, (@[]));

  [self.dataSource applyChangeset:
   [[[CKDataSourceChangesetBuilder new]
     withUpdatedItems:@{[NSIndexPath indexPathForItem:2 inSection:0] : @"2"}]
    build] mode:CKUpdateModeSynchronous userInfo:nil];

  controller =
  (CKDataSourceIntegrationTestComponentController*)g_componentsDictionary[@"2"].controller;

  XCTAssertEqualObjects(controller.callbacks, (@[NSStringFromSelector(@selector(willUpdateComponent))]));

  [self.dataSource applyChangeset:
   [[[CKDataSourceChangesetBuilder new]
     withMovedItems:(@{[NSIndexPath indexPathForItem:1 inSection:0] :
                         [NSIndexPath indexPathForItem:2 inSection:0]})]
    build] mode:CKUpdateModeSynchronous userInfo:nil];

  controller = (CKDataSourceIntegrationTestComponentController*)g_components.lastObject.controller;


  XCTAssertEqualObjects(controller.callbacks, (@[NSStringFromSelector(@selector(willUpdateComponent))]));
}

- (void)testUpdateModelAlwaysSendUpdateControllerCallbacks_didPrepareLayoutForComponent_on
{
  self.dataSource = [self generateDataSource];

  // Test 'didPrepareLayoutForComponent:' during insert.
  [self.dataSource applyChangeset:
   [[[[CKDataSourceChangesetBuilder new]
      withInsertedSections:[NSIndexSet indexSetWithIndex:0]]
     withInsertedItems:@{ [NSIndexPath indexPathForItem:0 inSection:0] : @"0",
                          [NSIndexPath indexPathForItem:1 inSection:0] : @"1",
                          [NSIndexPath indexPathForItem:2 inSection:0] : kOverrideDidPrepareLayoutForComponent,
                          }]
    build] mode:CKUpdateModeSynchronous userInfo:nil];

  CKDataSourceIntegrationOverrideDidPrepareLayoutForComponentTestComponentController *controller =
  (CKDataSourceIntegrationOverrideDidPrepareLayoutForComponentTestComponentController*)g_componentsDictionary[kOverrideDidPrepareLayoutForComponent].controller;

  XCTAssertEqualObjects(controller.callbacks, (@[
                                                 NSStringFromSelector(@selector(didPrepareLayout:forComponent:))
                                                 ]));

  // Test 'didPrepareLayoutForComponent:' during update.
  [self.dataSource applyChangeset:
   [[[[CKDataSourceChangesetBuilder new]
      withInsertedItems:
      @{ [NSIndexPath indexPathForItem:0 inSection:0] : @"0.1"}]
     withUpdatedItems:
     @{ [NSIndexPath indexPathForItem:2 inSection:0] : kOverrideDidPrepareLayoutForComponent }]
    build] mode:CKUpdateModeSynchronous userInfo:nil];

  controller = (CKDataSourceIntegrationOverrideDidPrepareLayoutForComponentTestComponentController*)g_componentsDictionary[kOverrideDidPrepareLayoutForComponent].controller;

  XCTAssertEqualObjects(controller.callbacks, (@[
                                                 NSStringFromSelector(@selector(didPrepareLayout:forComponent:)),
                                                 NSStringFromSelector(@selector(willUpdateComponent)),
                                                 NSStringFromSelector(@selector(didPrepareLayout:forComponent:))
                                                 ]));

  // Make sure that we can the correct layout in the "didPrepareLayout:forComponent:" by comparing the address of the component and layout.component.
  for (NSUInteger i=0; i<controller.layoutComponentsFromCallbacks.count; i++) {
    NSString *componentLayoutAddress = controller.layoutComponentsFromCallbacks[i];
    NSString *componentAddress = controller.componentsFromCallbacks[i];
    XCTAssertEqualObjects(componentLayoutAddress, componentAddress);
  }
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
    self.dataSource = [self generateDataSource];

    [self.dataSource applyChangeset:
     [[[[CKDataSourceChangesetBuilder new]
        withInsertedSections:[NSIndexSet indexSetWithIndex:0]]
       withInsertedItems:@{ [NSIndexPath indexPathForItem:0 inSection:0] : @"" }]
      build] mode:CKUpdateModeSynchronous userInfo:nil];

    CKDataSourceIntegrationTestComponentController * controller =
    (CKDataSourceIntegrationTestComponentController*) g_components.lastObject.controller;
    callbacks = controller.callbacks;

    // We clean everything to ensure dataSource receives deallocation happens when autorelease pool is destroyed
    self.dataSource = nil;
  }

  CKRunRunLoopUntilBlockIsTrue(^BOOL{
    return callbacks.count > 0;
  });

  XCTAssertEqualObjects(callbacks, (@[NSStringFromSelector(@selector(invalidateController))]));
}

@end
