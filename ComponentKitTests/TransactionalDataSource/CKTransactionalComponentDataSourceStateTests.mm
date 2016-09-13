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

#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKComponentLayout.h>
#import <ComponentKit/CKComponentProvider.h>
#import <ComponentKit/CKTransactionalComponentDataSourceConfiguration.h>
#import <ComponentKit/CKTransactionalComponentDataSourceItemInternal.h>
#import <ComponentKit/CKTransactionalComponentDataSourceStateInternal.h>

#import "CKTransactionalComponentDataSourceStateTestHelpers.h"

#import <UIKit/UIKit.h>

@interface CKTransactionalComponentDataSourceStateTests : XCTestCase <CKComponentProvider>
@end

@implementation CKTransactionalComponentDataSourceStateTests

+ (CKComponent *)componentForModel:(id<NSObject>)model context:(id<NSObject>)context
{
  return [CKComponent new];
}

- (void)testEnumeratingState
{
  CKTransactionalComponentDataSourceState *state = CKTransactionalComponentDataSourceTestState([self class], nil, 2, 2);
  NSMutableArray *models = [NSMutableArray array];
  NSMutableArray *indexPaths = [NSMutableArray array];
  [state enumerateObjectsUsingBlock:^(CKTransactionalComponentDataSourceItem *item, NSIndexPath *indexPath, BOOL *stop){
    [models addObject:[item model]];
    [indexPaths addObject:indexPath];
  }];

  NSArray *expectedModels = @[@0, @1, @2, @3];
  XCTAssertEqualObjects(models, expectedModels);

  NSArray *expectedIndexPaths = @[[NSIndexPath indexPathForItem:0 inSection:0],
                                  [NSIndexPath indexPathForItem:1 inSection:0],
                                  [NSIndexPath indexPathForItem:0 inSection:1],
                                  [NSIndexPath indexPathForItem:1 inSection:1]];
  XCTAssertEqualObjects(indexPaths, expectedIndexPaths);
}

- (void)testEnumeratingStateInSection
{
  CKTransactionalComponentDataSourceState *state = CKTransactionalComponentDataSourceTestState([self class], nil, 2, 2);
  NSMutableArray *models = [NSMutableArray array];
  NSMutableArray *indexPaths = [NSMutableArray array];
  [state enumerateObjectsInSectionAtIndex:0 usingBlock:^(CKTransactionalComponentDataSourceItem *item, NSIndexPath *indexPath, BOOL *stop){
    [models addObject:[item model]];
    [indexPaths addObject:indexPath];
  }];

  NSArray *expectedModels = @[@0, @1];
  XCTAssertEqualObjects(models, expectedModels);

  NSArray *expectedIndexPaths = @[[NSIndexPath indexPathForItem:0 inSection:0],
                                  [NSIndexPath indexPathForItem:1 inSection:0]];
  XCTAssertEqualObjects(indexPaths, expectedIndexPaths);
}

- (void)testStoppingEnumeration
{
  CKTransactionalComponentDataSourceState *state = CKTransactionalComponentDataSourceTestState([self class], nil, 2, 2);
  NSMutableArray *models = [NSMutableArray array];
  NSMutableArray *indexPaths = [NSMutableArray array];
  [state enumerateObjectsInSectionAtIndex:0 usingBlock:^(CKTransactionalComponentDataSourceItem *item, NSIndexPath *indexPath, BOOL *stop){
    [models addObject:[item model]];
    [indexPaths addObject:indexPath];
    *stop = YES;
  }];

  NSArray *expectedModels = @[@0];
  XCTAssertEqualObjects(models, expectedModels);

  NSArray *expectedIndexPaths = @[[NSIndexPath indexPathForItem:0 inSection:0]];
  XCTAssertEqualObjects(indexPaths, expectedIndexPaths);
}


- (void)testStateEquality
{
  CKTransactionalComponentDataSourceItem *firstItem = [[CKTransactionalComponentDataSourceItem alloc] initWithLayout:CKComponentLayout() model:@"model" scopeRoot:nil];
  CKTransactionalComponentDataSourceConfiguration *firstConfiguration =
  [[CKTransactionalComponentDataSourceConfiguration alloc] initWithComponentProvider:[CKTransactionalComponentDataSourceStateTests class]
                                                                             context:@"context"
                                                                           sizeRange:CKSizeRange()
                                                                          workThread:nil];
  CKTransactionalComponentDataSourceState *firstState = [[CKTransactionalComponentDataSourceState alloc] initWithConfiguration:firstConfiguration sections:@[@[firstItem]]];

  CKTransactionalComponentDataSourceItem *secondItem = [[CKTransactionalComponentDataSourceItem alloc] initWithLayout:CKComponentLayout() model:@"model" scopeRoot:nil];
  CKTransactionalComponentDataSourceConfiguration *secondConfiguration =
  [[CKTransactionalComponentDataSourceConfiguration alloc] initWithComponentProvider:[CKTransactionalComponentDataSourceStateTests class]
                                                                             context:@"context"
                                                                           sizeRange:CKSizeRange()
                                                                          workThread:nil];
  CKTransactionalComponentDataSourceState *secondState = [[CKTransactionalComponentDataSourceState alloc] initWithConfiguration:secondConfiguration sections:@[@[secondItem]]];

  XCTAssertEqualObjects(firstState, secondState);
}

- (void)testNonEqualStates
{
  CKTransactionalComponentDataSourceItem *firstItem = [[CKTransactionalComponentDataSourceItem alloc] initWithLayout:CKComponentLayout() model:@"model" scopeRoot:nil];
  CKTransactionalComponentDataSourceConfiguration *firstConfiguration =
  [[CKTransactionalComponentDataSourceConfiguration alloc] initWithComponentProvider:[CKTransactionalComponentDataSourceStateTests class]
                                                                             context:@"context"
                                                                           sizeRange:CKSizeRange()
                                                                          workThread:nil];
  CKTransactionalComponentDataSourceState *firstState = [[CKTransactionalComponentDataSourceState alloc] initWithConfiguration:firstConfiguration sections:@[@[firstItem]]];

  CKTransactionalComponentDataSourceItem *secondItem = [[CKTransactionalComponentDataSourceItem alloc] initWithLayout:CKComponentLayout() model:@"model2" scopeRoot:nil];
  CKTransactionalComponentDataSourceConfiguration *secondConfiguration =
  [[CKTransactionalComponentDataSourceConfiguration alloc] initWithComponentProvider:[CKTransactionalComponentDataSourceStateTests class]
                                                                             context:@"context"
                                                                           sizeRange:CKSizeRange()
                                                                          workThread:nil];
  CKTransactionalComponentDataSourceState *secondState = [[CKTransactionalComponentDataSourceState alloc] initWithConfiguration:secondConfiguration sections:@[@[secondItem]]];

  XCTAssertNotEqualObjects(firstState, secondState);
}

@end
