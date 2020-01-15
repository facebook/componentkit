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
#import <ComponentKit/CKDataSourceConfiguration.h>
#import <ComponentKit/CKDataSourceItemInternal.h>
#import <ComponentKit/CKDataSourceStateInternal.h>

#import "CKDataSourceStateTestHelpers.h"

#import <UIKit/UIKit.h>

@interface CKDataSourceStateTests : XCTestCase
@end

@implementation CKDataSourceStateTests

static CKComponent *ComponentProvider(id<NSObject> _, id<NSObject> __)
{
  return [CKComponent new];
}

- (void)testEnumeratingState
{
  CKDataSourceState *state = CKDataSourceTestState(ComponentProvider, nil, 2, 2);
  NSMutableArray *models = [NSMutableArray array];
  NSMutableArray *indexPaths = [NSMutableArray array];
  [state enumerateObjectsUsingBlock:^(CKDataSourceItem *item, NSIndexPath *indexPath, BOOL *stop){
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
  CKDataSourceState *state = CKDataSourceTestState(ComponentProvider, nil, 2, 2);
  NSMutableArray *models = [NSMutableArray array];
  NSMutableArray *indexPaths = [NSMutableArray array];
  [state enumerateObjectsInSectionAtIndex:0 usingBlock:^(CKDataSourceItem *item, NSIndexPath *indexPath, BOOL *stop){
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
  CKDataSourceState *state = CKDataSourceTestState(ComponentProvider, nil, 2, 2);
  NSMutableArray *models = [NSMutableArray array];
  NSMutableArray *indexPaths = [NSMutableArray array];
  [state enumerateObjectsInSectionAtIndex:0 usingBlock:^(CKDataSourceItem *item, NSIndexPath *indexPath, BOOL *stop){
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
  CKDataSourceItem *firstItem = [[CKDataSourceItem alloc] initWithRootLayout:{}
                                                                       model:@"model"
                                                                   scopeRoot:nil
                                                             boundsAnimation:{}];
  CKDataSourceConfiguration *firstConfiguration =
      [[CKDataSourceConfiguration alloc] initWithComponentProviderFunc:ComponentProvider
                                                               context:@"context"
                                                             sizeRange:CKSizeRange()];
  CKDataSourceState *firstState = [[CKDataSourceState alloc] initWithConfiguration:firstConfiguration
                                                                          sections:@[ @[ firstItem ] ]];

  CKDataSourceItem *secondItem = [[CKDataSourceItem alloc] initWithRootLayout:{}
                                                                        model:@"model"
                                                                    scopeRoot:nil
                                                              boundsAnimation:{}];
  CKDataSourceConfiguration *secondConfiguration =
      [[CKDataSourceConfiguration alloc] initWithComponentProviderFunc:ComponentProvider
                                                               context:@"context"
                                                             sizeRange:CKSizeRange()];
  CKDataSourceState *secondState = [[CKDataSourceState alloc] initWithConfiguration:secondConfiguration
                                                                           sections:@[ @[ secondItem ] ]];

  XCTAssertEqualObjects(firstState, secondState);
}

- (void)testNonEqualStates {
  CKDataSourceItem *firstItem = [[CKDataSourceItem alloc] initWithRootLayout:{}
                                                                       model:@"model"
                                                                   scopeRoot:nil
                                                             boundsAnimation:{}];
  CKDataSourceConfiguration *firstConfiguration =
      [[CKDataSourceConfiguration alloc] initWithComponentProviderFunc:ComponentProvider
                                                               context:@"context"
                                                             sizeRange:CKSizeRange()];
  CKDataSourceState *firstState = [[CKDataSourceState alloc] initWithConfiguration:firstConfiguration
                                                                          sections:@[ @[ firstItem ] ]];

  CKDataSourceItem *secondItem = [[CKDataSourceItem alloc] initWithRootLayout:{}
                                                                        model:@"model2"
                                                                    scopeRoot:nil
                                                              boundsAnimation:{}];
  CKDataSourceConfiguration *secondConfiguration =
      [[CKDataSourceConfiguration alloc] initWithComponentProviderFunc:ComponentProvider
                                                               context:@"context"
                                                             sizeRange:CKSizeRange()];
  CKDataSourceState *secondState = [[CKDataSourceState alloc] initWithConfiguration:secondConfiguration
                                                                           sections:@[ @[ secondItem ] ]];

  XCTAssertNotEqualObjects(firstState, secondState);
}

@end

@interface CKDataSourceStateTests_Description: XCTestCase
@end

@implementation CKDataSourceStateTests_Description

- (void)test_WhenStateIsEmpty_CompactDescriptionIsJustBraces
{
  const auto state = CKDataSourceTestState(ComponentProvider, nil, 0, 0);

  XCTAssertEqualObjects(state.description, @"{}");
}

- (void)test_CompactDescriptionFormat
{
  const auto state = CKDataSourceTestState(ComponentProvider, nil, 2, 2);

  const auto expected = @"\
{\n\
  (0, 0): 0,\n\
  (0, 1): 1,\n\
  (1, 0): 2,\n\
  (1, 1): 3\n\
}";
  XCTAssertEqualObjects(state.description, expected);
}
@end

@interface CKDataSourceStateTests_ContentsFingerprint : XCTestCase
@end

@interface ModelWithModelAndContext : NSObject
@property (nonatomic, readonly, strong) id model;
@property (nonatomic, readonly, strong) id context;

+ (instancetype)newWithModel:(id)model context:(id)context;

@end

static auto stateWithModels(const std::vector<id> &models) -> CKDataSourceState *
{
  auto const items = [NSMutableArray<CKDataSourceItem *> new];
  for (id model : models) {
    [items addObject:[[CKDataSourceItem alloc] initWithModel:model scopeRoot:nil]];
  }
  return
  [[CKDataSourceState alloc]
   initWithConfiguration:nil
   sections:@[items]];
}

@implementation CKDataSourceStateTests_ContentsFingerprint

- (void)test_WhenIsEmpty_FingerprintIsEmpty
{
  XCTAssertEqualObjects([CKDataSourceState new].contentsFingerprint, @"");
}

- (void)test_WhenHasModelWithModelAndContext_FingerprintIncludesModelAndContextTypesInSameOrder
{
  auto const state1 = stateWithModels({
    [ModelWithModelAndContext newWithModel:@"" context:@0],
    [ModelWithModelAndContext newWithModel:@"" context:@0],
    [ModelWithModelAndContext newWithModel:@[] context:@0],
  });

  auto const state2 = stateWithModels({
    [ModelWithModelAndContext newWithModel:@"" context:@0],
    [ModelWithModelAndContext newWithModel:@[] context:@1],
    [ModelWithModelAndContext newWithModel:@[] context:@1],
  });

  XCTAssertEqualObjects(state1.contentsFingerprint, state2.contentsFingerprint);
}

- (void)test_WhenHasModelWithModelAndContextAndNils_FingerprintIncludesModelAndContextTypesInSameOrder
{
  auto const state1 = stateWithModels({
    [ModelWithModelAndContext newWithModel:nil context:@0],
    [ModelWithModelAndContext newWithModel:@"" context:nil],
    [ModelWithModelAndContext newWithModel:@"" context:@0],
  });

  auto const state2 = stateWithModels({
    [ModelWithModelAndContext newWithModel:nil context:@0],
    [ModelWithModelAndContext newWithModel:@"" context:@0],
    [ModelWithModelAndContext newWithModel:nil context:@0],
  });

  XCTAssertEqualObjects(state1.contentsFingerprint, state2.contentsFingerprint);
}

- (void)test_WhenHasModelWithoutModelAndContext_FingerprintIncludesModelTypesInSameOrder
{
  auto const state1 = stateWithModels({
    @0,
    @"",
    @"",
    @0,
  });

  auto const state2 = stateWithModels({
    @0,
    @0,
    @"",
  });

  XCTAssertNotEqualObjects(state1.contentsFingerprint, @"");
  XCTAssertEqualObjects(state1.contentsFingerprint, state2.contentsFingerprint);
}

@end

@implementation ModelWithModelAndContext

+ (instancetype)newWithModel:(id)model context:(id)context
{
  auto const m = [super new];
  m->_model = model;
  m->_context = context;
  return m;
}

@end
