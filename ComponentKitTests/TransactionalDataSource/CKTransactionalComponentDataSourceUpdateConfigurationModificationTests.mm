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
#import <ComponentKit/CKComponentLayout.h>
#import <ComponentKit/CKComponentProvider.h>
#import <ComponentKit/CKCompositeComponent.h>
#import <ComponentKit/CKTransactionalComponentDataSourceAppliedChanges.h>
#import <ComponentKit/CKTransactionalComponentDataSourceChange.h>
#import <ComponentKit/CKTransactionalComponentDataSourceConfiguration.h>
#import <ComponentKit/CKTransactionalComponentDataSourceItem.h>
#import <ComponentKit/CKTransactionalComponentDataSourceState.h>

#import "CKTransactionalComponentDataSourceStateTestHelpers.h"
#import "CKTransactionalComponentDataSourceUpdateConfigurationModification.h"

@interface CKTestContextComponent : CKComponent
@property (nonatomic, strong, readonly) id<NSObject> context;
+ (instancetype)newWithContext:(id<NSObject>)context;
@end

@implementation CKTestContextComponent

+ (instancetype)newWithContext:(id<NSObject>)context
{
  CKTestContextComponent *c = [super newWithView:{} size:{}];
  if (c) {
    c->_context = context;
  }
  return c;
}

@end

/** Vends CKCompositeComponents instead of CKTestContextComponents */
@interface CKAlternateComponentProvider : NSObject <CKComponentProvider>
@end

@implementation CKAlternateComponentProvider
+ (CKComponent *)componentForModel:(id<NSObject>)model context:(id<NSObject>)context
{
  return [CKCompositeComponent newWithComponent:[CKComponent new]];
}
@end

@interface CKTransactionalComponentDataSourceUpdateConfigurationModificationTests : XCTestCase <CKComponentProvider>
@end

@implementation CKTransactionalComponentDataSourceUpdateConfigurationModificationTests

+ (CKComponent *)componentForModel:(id<NSObject>)model context:(id<NSObject>)context
{
  return [CKTestContextComponent newWithContext:context];
}

- (void)testAppliedChangesExposesNewConfiguration
{
  CKTransactionalComponentDataSourceState *originalState = CKTransactionalComponentDataSourceTestState([self class], nil, 5, 5);

  CKTransactionalComponentDataSourceConfiguration *newConfiguration =
  [[CKTransactionalComponentDataSourceConfiguration alloc] initWithComponentProvider:[self class]
                                                                             context:@"some updated context"
                                                                           sizeRange:{{100, 100}, {100, 100}}];

  CKTransactionalComponentDataSourceUpdateConfigurationModification *updateConfigurationModification =
  [[CKTransactionalComponentDataSourceUpdateConfigurationModification alloc] initWithConfiguration:newConfiguration userInfo:nil];

  CKTransactionalComponentDataSourceChange *change = [updateConfigurationModification changeFromState:originalState];

  XCTAssert([[change state] configuration] == newConfiguration);
}

- (void)testAppliedChangesIncludesUpdatedIndexPathsForEveryItem
{
  CKTransactionalComponentDataSourceState *originalState = CKTransactionalComponentDataSourceTestState([self class], nil, 5, 5);

  CKTransactionalComponentDataSourceUpdateConfigurationModification *updateConfigurationModification =
  [[CKTransactionalComponentDataSourceUpdateConfigurationModification alloc] initWithConfiguration:[originalState configuration] userInfo:nil];

  CKTransactionalComponentDataSourceChange *change = [updateConfigurationModification changeFromState:originalState];

  CKTransactionalComponentDataSourceAppliedChanges *expectedAppliedChanges =
  [[CKTransactionalComponentDataSourceAppliedChanges alloc] initWithUpdatedIndexPaths:CKTestIndexPaths(5, 5)
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
  CKTransactionalComponentDataSourceState *originalState = CKTransactionalComponentDataSourceTestState([self class], nil, 1, 1);
  NSDictionary *userInfo = @{@"foo": @"bar"};
  CKTransactionalComponentDataSourceUpdateConfigurationModification *updateConfigurationModification =
  [[CKTransactionalComponentDataSourceUpdateConfigurationModification alloc] initWithConfiguration:[originalState configuration] userInfo:userInfo];
  CKTransactionalComponentDataSourceChange *change = [updateConfigurationModification changeFromState:originalState];
  XCTAssertEqualObjects([[change appliedChanges] userInfo], userInfo);
}

- (void)testReturnsComponentsWithUpdatedComponentProvider
{
  CKTransactionalComponentDataSourceState *originalState = CKTransactionalComponentDataSourceTestState([self class], nil, 1, 1);
  CKTransactionalComponentDataSourceConfiguration *oldConfiguration = [originalState configuration];
  CKTransactionalComponentDataSourceConfiguration *newConfiguration =
  [[CKTransactionalComponentDataSourceConfiguration alloc] initWithComponentProvider:[CKAlternateComponentProvider class]
                                                                             context:[oldConfiguration context]
                                                                           sizeRange:[oldConfiguration sizeRange]];
  CKTransactionalComponentDataSourceUpdateConfigurationModification *updateConfigurationModification =
  [[CKTransactionalComponentDataSourceUpdateConfigurationModification alloc] initWithConfiguration:newConfiguration userInfo:nil];
  CKTransactionalComponentDataSourceChange *change = [updateConfigurationModification changeFromState:originalState];
  CKTransactionalComponentDataSourceItem *item = [[change state] objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
  XCTAssertTrue([[item layout].component isKindOfClass:[CKCompositeComponent class]]);
}

- (void)testReturnsComponentsWithUpdatedContext
{
  CKTransactionalComponentDataSourceState *originalState = CKTransactionalComponentDataSourceTestState([self class], nil, 1, 1);
  CKTransactionalComponentDataSourceConfiguration *oldConfiguration = [originalState configuration];
  CKTransactionalComponentDataSourceConfiguration *newConfiguration =
  [[CKTransactionalComponentDataSourceConfiguration alloc] initWithComponentProvider:[oldConfiguration componentProvider]
                                                                             context:@"some new context"
                                                                           sizeRange:[oldConfiguration sizeRange]];
  CKTransactionalComponentDataSourceUpdateConfigurationModification *updateConfigurationModification =
  [[CKTransactionalComponentDataSourceUpdateConfigurationModification alloc] initWithConfiguration:newConfiguration userInfo:nil];
  CKTransactionalComponentDataSourceChange *change = [updateConfigurationModification changeFromState:originalState];
  CKTransactionalComponentDataSourceItem *item = [[change state] objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
  CKTestContextComponent *component = (CKTestContextComponent *)[item layout].component;
  XCTAssertEqualObjects([component context], @"some new context");
}

- (void)testReturnsComponentsWithUpdatedSizeRange
{
  CKTransactionalComponentDataSourceState *originalState = CKTransactionalComponentDataSourceTestState([self class], nil, 1, 1);
  CKTransactionalComponentDataSourceConfiguration *oldConfiguration = [originalState configuration];
  CKTransactionalComponentDataSourceConfiguration *newConfiguration =
  [[CKTransactionalComponentDataSourceConfiguration alloc] initWithComponentProvider:[oldConfiguration componentProvider]
                                                                             context:[oldConfiguration context]
                                                                           sizeRange:{{50, 50}, {50, 50}}];
  CKTransactionalComponentDataSourceUpdateConfigurationModification *updateConfigurationModification =
  [[CKTransactionalComponentDataSourceUpdateConfigurationModification alloc] initWithConfiguration:newConfiguration userInfo:nil];
  CKTransactionalComponentDataSourceChange *change = [updateConfigurationModification changeFromState:originalState];
  CKTransactionalComponentDataSourceItem *item = [[change state] objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
  XCTAssertTrue(CGSizeEqualToSize([item layout].size, CGSizeMake(50, 50)));
}

@end
