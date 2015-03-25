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
#import <ComponentKit/CKComponentPreparationQueue.h>
#import <ComponentKit/CKComponentPreparationQueueInternal.h>
#import <ComponentKit/CKComponentProvider.h>

using namespace CK::ArrayController;

@interface CKCPQTestModel : NSObject
@end

@implementation CKCPQTestModel
@end

// OCMock doesn't support stubbing class methods on protocol mocks
@interface CKCPQTestComponentProvider : NSObject <CKComponentProvider>
@end

@implementation CKCPQTestComponentProvider

static CKComponent *(^_componentBlock)(void);

+ (void)setComponentBlock:(CKComponent *(^)(void))block
{
  _componentBlock = block;
}

+ (CKComponent *)componentForModel:(id<NSObject>)model context:(id<NSObject>)context
{
  return _componentBlock ?  _componentBlock() : nil;
}

@end

@interface CKStubLayoutComponent : NSObject
@property (readwrite, nonatomic, copy) CKComponentLayout (^layoutBlock)(CKSizeRange);
- (CKComponentLayout)layoutThatFits:(CKSizeRange)constrainedSize
                         parentSize:(CGSize)parentSize;
@end

@implementation CKStubLayoutComponent
- (CKComponentLayout)layoutThatFits:(CKSizeRange)constrainedSize
                         parentSize:(CGSize)parentSize
{
  return _layoutBlock(constrainedSize);
}
@end


@interface CKComponentPreparationQueueSyncTests : XCTestCase
@end

@implementation CKComponentPreparationQueueSyncTests

- (void)testPrepareInsertion
{
  CKStubLayoutComponent *component = [[CKStubLayoutComponent alloc] init];
  __weak id weakComponent = component;
  component.layoutBlock = ^(CKSizeRange s) {
    return (CKComponentLayout){(id)weakComponent, CGSizeZero};
  };
  [CKCPQTestComponentProvider setComponentBlock:^CKComponent *{
    return (id)component;
  }];
  id lifecycleManager = [[CKComponentLifecycleManager alloc] initWithComponentProvider:[CKCPQTestComponentProvider class]
                                                                               context:nil];

  id model = [[CKCPQTestModel alloc] init];
  NSIndexPath *indexPath = [NSIndexPath indexPathForItem:1 inSection:1];
  CKArrayControllerChangeType changeType = CKArrayControllerChangeTypeInsert;

  CKComponentPreparationInputItem *input = [[CKComponentPreparationInputItem alloc] initWithReplacementModel:model
                                                                                            lifecycleManager:lifecycleManager
                                                                                             constrainedSize:{{0,0}, {10, 20}}
                                                                                                     oldSize:{320, 100}
                                                                                                        UUID:@"foo"
                                                                                                   indexPath:indexPath
                                                                                                  changeType:changeType
                                                                                                 passthrough:NO];

  CKComponentPreparationOutputItem *output = [CKComponentPreparationQueue prepare:input];

  XCTAssertNotNil(output);
  XCTAssertEqual([output changeType], changeType);
  XCTAssertEqualObjects([output indexPath], indexPath);
  XCTAssertEqualObjects([output UUID], [input UUID]);
  XCTAssertTrue(CGSizeEqualToSize([input oldSize], [output oldSize]));

  CKComponentLifecycleManagerState state = [output lifecycleManagerState];
  XCTAssertEqualObjects(state.model, model);
}

- (void)testPrepareUpdate
{
  CKStubLayoutComponent *component = [[CKStubLayoutComponent alloc] init];
  __weak id weakComponent = component;
  component.layoutBlock = ^(CKSizeRange s) {
    return (CKComponentLayout){(id)weakComponent, CGSizeZero};
  };
  [CKCPQTestComponentProvider setComponentBlock:^CKComponent *{
    return (id)component;
  }];
  id lifecycleManager = [[CKComponentLifecycleManager alloc] initWithComponentProvider:[CKCPQTestComponentProvider class]
                                                                               context:nil];

  id newModel = [[CKCPQTestModel alloc] init];
  NSIndexPath *indexPath = [NSIndexPath indexPathForItem:1 inSection:1];
  CKArrayControllerChangeType changeType = CKArrayControllerChangeTypeUpdate;

  CKComponentPreparationInputItem *input = [[CKComponentPreparationInputItem alloc] initWithReplacementModel:newModel
                                                                                            lifecycleManager:lifecycleManager
                                                                                             constrainedSize:{{0,0}, {10, 20}}
                                                                                                     oldSize:{320, 100}
                                                                                                        UUID:@"foo"
                                                                                                   indexPath:indexPath
                                                                                                  changeType:changeType
                                                                                                 passthrough:NO];

  CKComponentPreparationOutputItem *output = [CKComponentPreparationQueue prepare:input];

  XCTAssertNotNil(output);
  XCTAssertEqual([output changeType], changeType);
  XCTAssertEqualObjects([output indexPath], indexPath);
  XCTAssertEqualObjects([output UUID], [input UUID]);
  XCTAssertTrue(CGSizeEqualToSize([input oldSize], [output oldSize]));

  CKComponentLifecycleManagerState state = [output lifecycleManagerState];
  XCTAssertEqualObjects(state.model, newModel);
}

- (void)testPrepareDeletion
{
  CKStubLayoutComponent *component = [[CKStubLayoutComponent alloc] init];
  __weak id weakComponent = component;
  component.layoutBlock = ^(CKSizeRange s) {
    return (CKComponentLayout){(id)weakComponent, CGSizeZero};
  };
  [CKCPQTestComponentProvider setComponentBlock:^CKComponent *{
    return (id)component;
  }];
  id lifecycleManager = [[CKComponentLifecycleManager alloc] initWithComponentProvider:[CKCPQTestComponentProvider class]
                                                                               context:nil];

  NSIndexPath *indexPath = [NSIndexPath indexPathForItem:1 inSection:1];
  CKArrayControllerChangeType changeType = CKArrayControllerChangeTypeDelete;

  CKComponentPreparationInputItem *input = [[CKComponentPreparationInputItem alloc] initWithReplacementModel:nil
                                                                                            lifecycleManager:lifecycleManager
                                                                                             constrainedSize:{{0,0}, {10, 20}}
                                                                                                     oldSize:{320, 100}
                                                                                                        UUID:@"foo"
                                                                                                   indexPath:indexPath
                                                                                                  changeType:changeType
                                                                                                 passthrough:NO];

  CKComponentPreparationOutputItem *output = [CKComponentPreparationQueue prepare:input];

  XCTAssertNotNil(output);
  XCTAssertNil([output lifecycleManager]);
  XCTAssertEqual([output changeType], changeType);
  XCTAssertEqualObjects([output indexPath], indexPath);
  XCTAssertEqualObjects([output UUID], [input UUID]);
  XCTAssertTrue(CGSizeEqualToSize([input oldSize], [output oldSize]));

  CKComponentLifecycleManagerState state = [output lifecycleManagerState];
  XCTAssertNil(state.model);
  XCTAssertNil(state.layout.component);
}

/**
 "Passthrough": A model is not component-compliant. We construct a dummy CKComponentLayoutManager, but do not construct
 a component for it.
 */
- (void)testPreparePassThrough
{
  [CKCPQTestComponentProvider setComponentBlock:^CKComponent *{
    XCTFail(@"Should not be called");
    return nil;
  }];
  id lifecycleManager = [[CKComponentLifecycleManager alloc] initWithComponentProvider:[CKCPQTestComponentProvider class]
                                                                               context:nil];

  id model = [[CKCPQTestModel alloc] init];
  NSIndexPath *indexPath = [NSIndexPath indexPathForItem:1 inSection:1];
  CKArrayControllerChangeType changeType = CKArrayControllerChangeTypeInsert;

  CKComponentPreparationInputItem *input = [[CKComponentPreparationInputItem alloc] initWithReplacementModel:model
                                                                                            lifecycleManager:lifecycleManager
                                                                                             constrainedSize:{{0,0}, {10, 20}}
                                                                                                     oldSize:{320, 100}
                                                                                                        UUID:@"foo"
                                                                                                   indexPath:indexPath
                                                                                                  changeType:changeType
                                                                                                 passthrough:YES];

  CKComponentPreparationOutputItem *output = [CKComponentPreparationQueue prepare:input];

  XCTAssertNotNil(output);
  XCTAssertEqual([output changeType], changeType);
  XCTAssertEqualObjects([output indexPath], indexPath);
  XCTAssertEqualObjects(output.replacementModel, input.replacementModel);
  XCTAssertEqualObjects([output UUID], [input UUID]);
  XCTAssertTrue(CGSizeEqualToSize([input oldSize], [output oldSize]));
}

@end
