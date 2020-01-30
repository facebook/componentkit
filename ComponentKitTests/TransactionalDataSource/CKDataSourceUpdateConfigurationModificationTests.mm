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

#include <stdlib.h>

#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKCompositeComponent.h>
#import <ComponentKit/CKComponentLayout.h>
#import <ComponentKit/CKComponentProvider.h>
#import <ComponentKit/CKCompositeComponent.h>
#import <ComponentKit/CKDataSourceAppliedChanges.h>
#import <ComponentKit/CKDataSourceChange.h>
#import <ComponentKit/CKDataSourceConfiguration.h>
#import <ComponentKit/CKDataSourceConfigurationInternal.h>
#import <ComponentKit/CKDataSourceItem.h>
#import <ComponentKit/CKDataSourceState.h>
#import <ComponentKit/CKDataSourceUpdateConfigurationModification.h>

#import <ComponentKitTestHelpers/CKLifecycleTestComponent.h>

#import "CKDataSourceStateTestHelpers.h"

static NSString *const kTestContextForLifecycleComponent = @"kTestContextForLifecycleComponent";

@interface CKTestContextComponent : CKCompositeComponent
@property (nonatomic, strong, readonly) id<NSObject> context;
@property (nonatomic, strong, readonly) CKLifecycleTestComponent *lifecycleComponent;
+ (instancetype)newWithContext:(id<NSObject>)context;
@end

@implementation CKTestContextComponent

+ (instancetype)newWithContext:(id<NSObject>)context
{
  CKLifecycleTestComponent *lifecycleComponent = [context isEqual:kTestContextForLifecycleComponent]
  ? [CKLifecycleTestComponent newWithView:{} size:{}]
  : nil;
  const auto c = [super newWithComponent:lifecycleComponent ?: CK::ComponentBuilder()
                                                                   .build()];
  if (c) {
    c->_context = context;
    c->_lifecycleComponent = lifecycleComponent;
  }
  return c;
}

@end

@interface CKDataSourceUpdateConfigurationModificationTests : XCTestCase
@end

@implementation CKDataSourceUpdateConfigurationModificationTests

- (void)testAppliedChangesExposesNewConfiguration
{
  CKDataSourceState *originalState = CKDataSourceTestState(ComponentProvider, nil, 5, 5);

  CKDataSourceConfiguration *newConfiguration =
      [[CKDataSourceConfiguration alloc] initWithComponentProviderFunc:ComponentProvider
                                                               context:@"some updated context"
                                                             sizeRange:{{100, 100}, {100, 100}}];

  CKDataSourceUpdateConfigurationModification *updateConfigurationModification =
  [[CKDataSourceUpdateConfigurationModification alloc] initWithConfiguration:newConfiguration userInfo:nil];

  CKDataSourceChange *change = [updateConfigurationModification changeFromState:originalState];

  XCTAssert([[change state] configuration] == newConfiguration);
}

- (void)testAppliedChangesIncludesUpdatedIndexPathsForEveryItem
{
  CKDataSourceState *originalState = CKDataSourceTestState(ComponentProvider, nil, 5, 5);

  CKDataSourceUpdateConfigurationModification *updateConfigurationModification =
  [[CKDataSourceUpdateConfigurationModification alloc] initWithConfiguration:[originalState configuration] userInfo:nil];

  CKDataSourceChange *change = [updateConfigurationModification changeFromState:originalState];

  CKDataSourceAppliedChanges *expectedAppliedChanges =
  [[CKDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:CKTestIndexPaths(5, 5)
                                                                    removedIndexPaths:nil
                                                                      removedSections:nil
                                                                      movedIndexPaths:nil
                                                                     insertedSections:nil
                                                                   insertedIndexPaths:nil
                                                                             userInfo:nil];

  XCTAssertEqualObjects([change appliedChanges], expectedAppliedChanges);
}

- (void)testAppliedChangesIncludesUserInfo
{
  CKDataSourceState *originalState = CKDataSourceTestState(ComponentProvider, nil, 1, 1);
  NSDictionary *userInfo = @{@"foo": @"bar"};
  CKDataSourceUpdateConfigurationModification *updateConfigurationModification =
  [[CKDataSourceUpdateConfigurationModification alloc] initWithConfiguration:[originalState configuration] userInfo:userInfo];
  CKDataSourceChange *change = [updateConfigurationModification changeFromState:originalState];
  XCTAssertEqualObjects([[change appliedChanges] userInfo], userInfo);
}

- (void)testReturnsComponentsWithUpdatedComponentProvider
{
  CKDataSourceState *originalState = CKDataSourceTestState(ComponentProvider, nil, 1, 1);
  CKDataSourceConfiguration *oldConfiguration = [originalState configuration];
  CKDataSourceConfiguration *newConfiguration =
  [[CKDataSourceConfiguration alloc] initWithComponentProviderFunc:AlternateComponentProvider
                                                           context:[oldConfiguration context]
                                                         sizeRange:[oldConfiguration sizeRange]];
  CKDataSourceUpdateConfigurationModification *updateConfigurationModification =
  [[CKDataSourceUpdateConfigurationModification alloc] initWithConfiguration:newConfiguration userInfo:nil];
  CKDataSourceChange *change = [updateConfigurationModification changeFromState:originalState];
  CKDataSourceItem *item = [[change state] objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
  XCTAssertTrue([[item rootLayout].component() isKindOfClass:[CKCompositeComponent class]]);
}

- (void)testReturnsComponentsWithUpdatedContext
{
  CKDataSourceState *originalState = CKDataSourceTestState(ComponentProvider, nil, 1, 1);
  CKDataSourceConfiguration *oldConfiguration = [originalState configuration];
  CKDataSourceConfiguration *newConfiguration =
      [[CKDataSourceConfiguration alloc] initWithComponentProviderFunc:ComponentProvider
                                                               context:@"some new context"
                                                             sizeRange:[oldConfiguration sizeRange]];
  CKDataSourceUpdateConfigurationModification *updateConfigurationModification =
      [[CKDataSourceUpdateConfigurationModification alloc] initWithConfiguration:newConfiguration userInfo:nil];
  CKDataSourceChange *change = [updateConfigurationModification changeFromState:originalState];
  CKDataSourceItem *item = [[change state] objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
  CKTestContextComponent *component = (CKTestContextComponent *)[item rootLayout].component();
  XCTAssertEqualObjects([component context], @"some new context");
}

- (void)testReturnsComponentsWithUpdatedSizeRange
{
  CKDataSourceState *originalState = CKDataSourceTestState(ComponentProvider, nil, 1, 1);
  CKDataSourceConfiguration *oldConfiguration = [originalState configuration];
  CKDataSourceConfiguration *newConfiguration =
      [[CKDataSourceConfiguration alloc] initWithComponentProviderFunc:ComponentProvider
                                                               context:[oldConfiguration context]
                                                             sizeRange:{{50, 50}, {50, 50}}];
  CKDataSourceUpdateConfigurationModification *updateConfigurationModification =
      [[CKDataSourceUpdateConfigurationModification alloc] initWithConfiguration:newConfiguration userInfo:nil];
  CKDataSourceChange *change = [updateConfigurationModification changeFromState:originalState];
  CKDataSourceItem *item = [[change state] objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
  XCTAssertTrue(CGSizeEqualToSize([item rootLayout].size(), CGSizeMake(50, 50)));
}

- (void)testReturnsInvalidComponentControllers
{
  const auto originalState = CKDataSourceTestState(ComponentProvider, nil, 1, 1);
  const auto oldConfiguration = [originalState configuration];
  auto newConfiguration = [oldConfiguration copyWithContext:kTestContextForLifecycleComponent sizeRange:oldConfiguration.sizeRange];
  auto change =
  [[[CKDataSourceUpdateConfigurationModification alloc]
    initWithConfiguration:newConfiguration userInfo:nil]
   changeFromState:originalState];

  const auto componentController = ((CKTestContextComponent *)[[change state] objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]].rootLayout.component()).lifecycleComponent.controller;

  change =
  [[[CKDataSourceUpdateConfigurationModification alloc]
    initWithConfiguration:oldConfiguration userInfo:nil]
   changeFromState:change.state];
  XCTAssertEqual(change.invalidComponentControllers.firstObject, componentController,
                 @"Invalid component controller should be returned because component is removed from hierarchy.");
}

static CKComponent *AlternateComponentProvider(id<NSObject> model, id<NSObject> context)
{
  return CK::CompositeComponentBuilder().component([CKComponent new]).build();
}

static CKComponent *ComponentProvider(id<NSObject> _, id<NSObject> context)
{
  return [CKTestContextComponent newWithContext:context];
}

@end
