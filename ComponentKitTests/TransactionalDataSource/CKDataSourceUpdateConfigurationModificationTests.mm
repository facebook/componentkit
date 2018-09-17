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
#import <ComponentKit/CKDataSourceAppliedChanges.h>
#import <ComponentKit/CKDataSourceChange.h>
#import <ComponentKit/CKDataSourceConfiguration.h>
#import <ComponentKit/CKDataSourceItem.h>
#import <ComponentKit/CKDataSourceState.h>

#import "CKDataSourceStateTestHelpers.h"
#import "CKDataSourceUpdateConfigurationModification.h"

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

@interface CKDataSourceUpdateConfigurationModificationTests : XCTestCase <CKComponentProvider>
@end

@implementation CKDataSourceUpdateConfigurationModificationTests

+ (CKComponent *)componentForModel:(id<NSObject>)model context:(id<NSObject>)context
{
  return [CKTestContextComponent newWithContext:context];
}

- (void)testAppliedChangesExposesNewConfiguration
{
  CKDataSourceState *originalState = CKDataSourceTestState([self class], nil, 5, 5);

  CKDataSourceConfiguration *newConfiguration =
  [[CKDataSourceConfiguration alloc] initWithComponentProvider:[self class]
                                                       context:@"some updated context"
                                                     sizeRange:{{100, 100}, {100, 100}}];

  CKDataSourceUpdateConfigurationModification *updateConfigurationModification =
  [[CKDataSourceUpdateConfigurationModification alloc] initWithConfiguration:newConfiguration userInfo:nil];

  CKDataSourceChange *change = [updateConfigurationModification changeFromState:originalState];

  XCTAssert([[change state] configuration] == newConfiguration);
}

- (void)testAppliedChangesIncludesUpdatedIndexPathsForEveryItem
{
  CKDataSourceState *originalState = CKDataSourceTestState([self class], nil, 5, 5);

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
  CKDataSourceState *originalState = CKDataSourceTestState([self class], nil, 1, 1);
  NSDictionary *userInfo = @{@"foo": @"bar"};
  CKDataSourceUpdateConfigurationModification *updateConfigurationModification =
  [[CKDataSourceUpdateConfigurationModification alloc] initWithConfiguration:[originalState configuration] userInfo:userInfo];
  CKDataSourceChange *change = [updateConfigurationModification changeFromState:originalState];
  XCTAssertEqualObjects([[change appliedChanges] userInfo], userInfo);
}

- (void)testReturnsComponentsWithUpdatedComponentProvider
{
  CKDataSourceState *originalState = CKDataSourceTestState([self class], nil, 1, 1);
  CKDataSourceConfiguration *oldConfiguration = [originalState configuration];
  CKDataSourceConfiguration *newConfiguration =
  [[CKDataSourceConfiguration alloc] initWithComponentProvider:[CKAlternateComponentProvider class]
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
  CKDataSourceState *originalState = CKDataSourceTestState([self class], nil, 1, 1);
  CKDataSourceConfiguration *oldConfiguration = [originalState configuration];
  CKDataSourceConfiguration *newConfiguration =
  [[CKDataSourceConfiguration alloc] initWithComponentProvider:[oldConfiguration componentProvider]
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
  CKDataSourceState *originalState = CKDataSourceTestState([self class], nil, 1, 1);
  CKDataSourceConfiguration *oldConfiguration = [originalState configuration];
  CKDataSourceConfiguration *newConfiguration =
  [[CKDataSourceConfiguration alloc] initWithComponentProvider:[oldConfiguration componentProvider]
                                                       context:[oldConfiguration context]
                                                     sizeRange:{{50, 50}, {50, 50}}];
  CKDataSourceUpdateConfigurationModification *updateConfigurationModification =
  [[CKDataSourceUpdateConfigurationModification alloc] initWithConfiguration:newConfiguration userInfo:nil];
  CKDataSourceChange *change = [updateConfigurationModification changeFromState:originalState];
  CKDataSourceItem *item = [[change state] objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
  XCTAssertTrue(CGSizeEqualToSize([item rootLayout].size(), CGSizeMake(50, 50)));
}

@end
