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
#import <ComponentKit/CKComponentProvider.h>
#import <ComponentKit/CKDataSource.h>
#import <ComponentKit/CKDataSourceAppliedChanges.h>
#import <ComponentKit/CKDataSourceChangeset.h>
#import <ComponentKit/CKDataSourceConfigurationInternal.h>
#import <ComponentKit/CKDataSourceListener.h>

@interface CKDataSourceSplitChangesetTests : XCTestCase <CKComponentProvider, CKDataSourceListener>

@end

@implementation CKDataSourceSplitChangesetTests {
  NSMutableArray<CKDataSourceAppliedChanges *> *_announcedChanges;
}

+ (CKComponent *)componentForModel:(id<NSObject>)model context:(id<NSObject>)context
{
  const CGSize size = [(NSValue *)model CGSizeValue];
  return [CKComponent newWithView:{} size:{size.width, size.height}];
}

- (void)setUp
{
  [super setUp];
  _announcedChanges = [NSMutableArray<CKDataSourceAppliedChanges *> new];
}

- (void)testDataSourceDoesNotSplitChangesetIfChangesetSplittingDisabled
{
  CKDataSource *const dataSource = dataSourceWithSplitChangesetOptions([self class], {});
  [dataSource addListener:self];

  [dataSource applyChangeset:initialInsertionChangeset(10, {.width = 10, .height = 10}) mode:CKUpdateModeSynchronous userInfo:nil];
  XCTAssertEqualObjects(expectedAppliedChangesForInsertion(NSMakeRange(0, 10)), _announcedChanges.firstObject);
}

- (void)testDataSourceDoesNotSplitChangesetIfDoesntFillViewportVertical
{
  CKDataSource *const dataSource = dataSourceWithSplitChangesetOptions([self class], {
    .enabled = YES,
    .viewportBoundingSize = { .width = 10, .height = 20 },
    .layoutAxis = CKDataSourceLayoutAxisVertical,
  });
  [dataSource addListener:self];

  [dataSource applyChangeset:initialInsertionChangeset(1, {.width = 10, .height = 10}) mode:CKUpdateModeSynchronous userInfo:nil];
  XCTAssertEqualObjects(expectedAppliedChangesForInsertion(NSMakeRange(0, 1)), _announcedChanges.firstObject);
}

- (void)testDataSourceDoesNotSplitChangesetIfFillsViewportVertical
{
  CKDataSource *const dataSource = dataSourceWithSplitChangesetOptions([self class], {
    .enabled = YES,
    .viewportBoundingSize = { .width = 10, .height = 20 },
    .layoutAxis = CKDataSourceLayoutAxisVertical,
  });
  [dataSource addListener:self];

  [dataSource applyChangeset:initialInsertionChangeset(2, {.width = 10, .height = 10}) mode:CKUpdateModeSynchronous userInfo:nil];
  XCTAssertEqualObjects(expectedAppliedChangesForInsertion(NSMakeRange(0, 2)), _announcedChanges.firstObject);
}

- (void)testDataSourceSplitsChangesetIfOverflowsViewportVertical
{
  CKDataSource *const dataSource = dataSourceWithSplitChangesetOptions([self class], {
    .enabled = YES,
    .viewportBoundingSize = { .width = 10, .height = 20 },
    .layoutAxis = CKDataSourceLayoutAxisVertical,
  });
  [dataSource addListener:self];

  [dataSource applyChangeset:initialInsertionChangeset(4, {.width = 10, .height = 10}) mode:CKUpdateModeSynchronous userInfo:nil];
  XCTAssertEqual(2, _announcedChanges.count);
  XCTAssertEqualObjects(expectedAppliedChangesForInsertion(NSMakeRange(0, 2)), _announcedChanges[0]);
  XCTAssertEqualObjects(expectedAppliedChangesForInsertion(NSMakeRange(2, 2)), _announcedChanges[1]);
}

- (void)testDataSourceDoesNotSplitChangesetIfDoesntFillViewportHorizontal
{
  CKDataSource *const dataSource = dataSourceWithSplitChangesetOptions([self class], {
    .enabled = YES,
    .viewportBoundingSize = { .width = 20, .height = 10 },
    .layoutAxis = CKDataSourceLayoutAxisHorizontal,
  });
  [dataSource addListener:self];

  [dataSource applyChangeset:initialInsertionChangeset(1, {.width = 10, .height = 10}) mode:CKUpdateModeSynchronous userInfo:nil];
  XCTAssertEqualObjects(expectedAppliedChangesForInsertion(NSMakeRange(0, 1)), _announcedChanges.firstObject);
}

- (void)testDataSourceDoesNotSplitChangesetIfFillsViewportHorizontal
{
  CKDataSource *const dataSource = dataSourceWithSplitChangesetOptions([self class], {
    .enabled = YES,
    .viewportBoundingSize = { .width = 20, .height = 10 },
    .layoutAxis = CKDataSourceLayoutAxisHorizontal,
  });
  [dataSource addListener:self];

  [dataSource applyChangeset:initialInsertionChangeset(2, {.width = 10, .height = 10}) mode:CKUpdateModeSynchronous userInfo:nil];
  XCTAssertEqualObjects(expectedAppliedChangesForInsertion(NSMakeRange(0, 2)), _announcedChanges.firstObject);
}

- (void)testDataSourceSplitsChangesetIfOverflowsViewportHorizontal
{
  CKDataSource *const dataSource = dataSourceWithSplitChangesetOptions([self class], {
    .enabled = YES,
    .viewportBoundingSize = { .width = 20, .height = 10 },
    .layoutAxis = CKDataSourceLayoutAxisHorizontal,
  });
  [dataSource addListener:self];

  [dataSource applyChangeset:initialInsertionChangeset(4, {.width = 10, .height = 10}) mode:CKUpdateModeSynchronous userInfo:nil];
  XCTAssertEqual(2, _announcedChanges.count);
  XCTAssertEqualObjects(expectedAppliedChangesForInsertion(NSMakeRange(0, 2)), _announcedChanges[0]);
  XCTAssertEqualObjects(expectedAppliedChangesForInsertion(NSMakeRange(2, 2)), _announcedChanges[1]);
}

- (void)testDeferredChangesetHasTheSameUserInfo
{
  CKDataSource *const dataSource = dataSourceWithSplitChangesetOptions([self class], {
    .enabled = YES,
    .viewportBoundingSize = { .width = 20, .height = 10 },
    .layoutAxis = CKDataSourceLayoutAxisHorizontal,
  });
  [dataSource addListener:self];

  NSDictionary<NSString *, id> *const userInfo = @{@"foo": @YES};
  [dataSource applyChangeset:initialInsertionChangeset(4, {.width = 10, .height = 10}) mode:CKUpdateModeSynchronous userInfo:userInfo];
  XCTAssertEqual(2, _announcedChanges.count);
  XCTAssertEqualObjects(userInfo, _announcedChanges[0].userInfo);
  XCTAssertEqualObjects(userInfo, _announcedChanges[1].userInfo);
}

- (void)testDeferredChangesetAppliedImmediatelyAfterOriginalChangeset
{
  CKDataSource *const dataSource = dataSourceWithSplitChangesetOptions([self class], {
    .enabled = YES,
    .viewportBoundingSize = { .width = 10, .height = 20 },
    .layoutAxis = CKDataSourceLayoutAxisVertical,
  });
  [dataSource addListener:self];

  [dataSource applyChangeset:initialInsertionChangeset(4, {.width = 10, .height = 10}) mode:CKUpdateModeAsynchronous userInfo:nil];
  [dataSource applyChangeset:tailInsertionChangeset(NSMakeRange(4, 1), {.width = 10, .height = 10}) mode:CKUpdateModeSynchronous userInfo:nil];
  XCTAssertEqual(3, _announcedChanges.count);
  XCTAssertEqualObjects(expectedAppliedChangesForInsertion(NSMakeRange(4, 1)), _announcedChanges[2]);
}

- (void)testDataSourceDoesNotSplitChangesetIfExistingContentFillsViewport
{
  CKDataSource *const dataSource = dataSourceWithSplitChangesetOptions([self class], {
    .enabled = YES,
    .viewportBoundingSize = { .width = 10, .height = 20 },
    .layoutAxis = CKDataSourceLayoutAxisVertical,
  });
  [dataSource addListener:self];

  [dataSource applyChangeset:initialInsertionChangeset(4, {.width = 10, .height = 10}) mode:CKUpdateModeSynchronous userInfo:nil];
  [dataSource applyChangeset:tailInsertionChangeset(NSMakeRange(4, 4), {.width = 10, .height = 10}) mode:CKUpdateModeSynchronous userInfo:nil];
  XCTAssertEqual(3, _announcedChanges.count);
  XCTAssertEqualObjects(expectedAppliedChangesForInsertion(NSMakeRange(4, 4)), _announcedChanges[2]);
}

- (void)testDataSourceDoesNotSplitChangesetIfUpdateCausesSizeIncrease
{
  CKDataSource *const dataSource = dataSourceWithSplitChangesetOptions([self class], {
    .enabled = YES,
    .viewportBoundingSize = { .width = 10, .height = 20 },
    .layoutAxis = CKDataSourceLayoutAxisVertical,
  });
  [dataSource addListener:self];

  [dataSource applyChangeset:initialInsertionChangeset(1, {.width = 10, .height = 10}) mode:CKUpdateModeSynchronous userInfo:nil];
  CKDataSourceChangeset *const updateChangeset =
  [[[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withUpdatedItems:@{
                       [NSIndexPath indexPathForRow:0 inSection:0]: sizeValue(10, 30),
                       }]
   withInsertedItems:@{
                       [NSIndexPath indexPathForRow:1 inSection:0]: sizeValue(10, 10),
                       }]
   build];
  [dataSource applyChangeset:updateChangeset mode:CKUpdateModeSynchronous userInfo:nil];
  XCTAssertEqual(2, _announcedChanges.count);
  XCTAssertEqualObjects([NSSet setWithObject:[NSIndexPath indexPathForRow:0 inSection:0]], _announcedChanges[1].updatedIndexPaths);
  XCTAssertEqualObjects([NSSet setWithObject:[NSIndexPath indexPathForRow:1 inSection:0]], _announcedChanges[1].insertedIndexPaths);
}

- (void)testDataSourceSplitsChangesetIfUpdateCausesSizeDecrease
{
  CKDataSource *const dataSource = dataSourceWithSplitChangesetOptions([self class], {
    .enabled = YES,
    .viewportBoundingSize = { .width = 10, .height = 20 },
    .layoutAxis = CKDataSourceLayoutAxisVertical,
  });
  [dataSource addListener:self];

  [dataSource applyChangeset:initialInsertionChangeset(1, {.width = 10, .height = 40}) mode:CKUpdateModeSynchronous userInfo:nil];
  CKDataSourceChangeset *const updateChangeset =
  [[[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
     withUpdatedItems:@{
                        [NSIndexPath indexPathForRow:0 inSection:0]: sizeValue(10, 10),
                        }]
    withInsertedItems:@{
                        [NSIndexPath indexPathForRow:1 inSection:0]: sizeValue(10, 10),
                        [NSIndexPath indexPathForRow:2 inSection:0]: sizeValue(10, 10),
                        }]
   build];
  [dataSource applyChangeset:updateChangeset mode:CKUpdateModeSynchronous userInfo:nil];
  XCTAssertEqual(3, _announcedChanges.count);
  XCTAssertEqualObjects([NSSet setWithObject:[NSIndexPath indexPathForRow:0 inSection:0]], _announcedChanges[1].updatedIndexPaths);
  XCTAssertEqualObjects([NSSet setWithObject:[NSIndexPath indexPathForRow:1 inSection:0]], _announcedChanges[1].insertedIndexPaths);
  XCTAssertEqualObjects([NSSet setWithObject:[NSIndexPath indexPathForRow:2 inSection:0]], _announcedChanges[2].insertedIndexPaths);
}

- (void)testDataSourceSplitsChangesetIfItemRemovalCausesSizeDecrease
{
  CKDataSource *const dataSource = dataSourceWithSplitChangesetOptions([self class], {
    .enabled = YES,
    .viewportBoundingSize = { .width = 10, .height = 20 },
    .layoutAxis = CKDataSourceLayoutAxisVertical,
  });
  [dataSource addListener:self];

  [dataSource applyChangeset:initialInsertionChangeset(1, {.width = 10, .height = 40}) mode:CKUpdateModeSynchronous userInfo:nil];
  CKDataSourceChangeset *const removalChangeset =
  [[[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
     withRemovedItems:[NSSet setWithObject:[NSIndexPath indexPathForRow:0 inSection:0]]]
    withInsertedItems:@{
                        [NSIndexPath indexPathForRow:0 inSection:0]: sizeValue(10, 20),
                        [NSIndexPath indexPathForRow:1 inSection:0]: sizeValue(10, 20),
                        }]
   build];
  [dataSource applyChangeset:removalChangeset mode:CKUpdateModeSynchronous userInfo:nil];
  XCTAssertEqual(3, _announcedChanges.count);
  XCTAssertEqualObjects([NSSet setWithObject:[NSIndexPath indexPathForRow:0 inSection:0]], _announcedChanges[1].removedIndexPaths);
  XCTAssertEqualObjects([NSSet setWithObject:[NSIndexPath indexPathForRow:0 inSection:0]], _announcedChanges[1].insertedIndexPaths);
  XCTAssertEqualObjects([NSSet setWithObject:[NSIndexPath indexPathForRow:1 inSection:0]], _announcedChanges[2].insertedIndexPaths);
}

- (void)testDataSourceDoesNotSplitChangesetsIfNotContiguousTailInsertion
{
  CKDataSource *const dataSource = dataSourceWithSplitChangesetOptions([self class], {
    .enabled = YES,
    .viewportBoundingSize = { .width = 10, .height = 20 },
    .layoutAxis = CKDataSourceLayoutAxisVertical,
  });
  [dataSource addListener:self];

  [dataSource applyChangeset:initialInsertionChangeset(1, {.width = 10, .height = 10}) mode:CKUpdateModeSynchronous userInfo:nil];
  [dataSource applyChangeset:tailInsertionChangeset(NSMakeRange(0, 2), {.width = 10, .height = 10}) mode:CKUpdateModeSynchronous userInfo:nil];

  XCTAssertEqual(2, _announcedChanges.count);
  XCTAssertEqualObjects([NSSet setWithObject:[NSIndexPath indexPathForRow:0 inSection:0]], _announcedChanges[0].insertedIndexPaths);
  NSSet<NSIndexPath *> *const expectedInsertedIndexPaths = [NSSet setWithObjects:[NSIndexPath indexPathForRow:0 inSection:0], [NSIndexPath indexPathForRow:1 inSection:0], nil];
  XCTAssertEqualObjects(expectedInsertedIndexPaths, _announcedChanges[1].insertedIndexPaths);
}

static CKDataSource *dataSourceWithSplitChangesetOptions(Class<CKComponentProvider> componentProvider, const CKDataSourceSplitChangesetOptions &splitChangesetOptions)
{
  CKDataSourceConfiguration *const config =
  [[CKDataSourceConfiguration alloc]
   initWithComponentProvider:componentProvider
   context:nil
   sizeRange:{}
   buildComponentConfig:{}
   splitChangesetOptions:splitChangesetOptions
   workQueue:nil
   applyModificationsOnWorkQueue:NO
   unifyBuildAndLayout:NO
   componentPredicates:{}
   componentControllerPredicates:{}
   analyticsListener:nil];
  return [[CKDataSource alloc] initWithConfiguration:config];
}

static CKDataSourceChangeset *initialInsertionChangeset(NSUInteger itemCount, CGSize size)
{
  NSMutableDictionary<NSIndexPath *, NSValue *> *const items = [NSMutableDictionary<NSIndexPath *, NSValue *> dictionaryWithCapacity:itemCount];
  for (NSUInteger i = 0; i < itemCount; i++) {
    items[[NSIndexPath indexPathForItem:i inSection:0]] = [NSValue valueWithCGSize:size];
  }
  return [[[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
            withInsertedSections:[NSIndexSet indexSetWithIndex:0]]
           withInsertedItems:items]
          build];
}

static CKDataSourceChangeset *tailInsertionChangeset(NSRange range, CGSize size)
{
  NSMutableDictionary<NSIndexPath *, NSValue *> *const items = [NSMutableDictionary<NSIndexPath *, NSValue *> dictionaryWithCapacity:range.length];
  for (NSUInteger i = 0; i < range.length; i++) {
    items[[NSIndexPath indexPathForItem:i + range.location inSection:0]] = [NSValue valueWithCGSize:size];
  }
  return [[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset] withInsertedItems:items] build];
}

static CKDataSourceAppliedChanges *expectedAppliedChangesForInsertion(NSRange range)
{
  NSIndexSet *insertedSections = nil;
  if (range.location == 0) {
    insertedSections = [NSIndexSet indexSetWithIndex:0];
  }
  NSMutableSet<NSIndexPath *> *const insertedIndexPaths = [NSMutableSet<NSIndexPath *> setWithCapacity:range.length];
  for (NSUInteger i = 0; i < range.length; i++) {
    [insertedIndexPaths addObject:[NSIndexPath indexPathForItem:range.location + i inSection:0]];
  }
  return [[CKDataSourceAppliedChanges alloc]
          initWithUpdatedIndexPaths:nil
          removedIndexPaths:nil
          removedSections:nil
          movedIndexPaths:nil
          insertedSections:insertedSections
          insertedIndexPaths:insertedIndexPaths
          userInfo:nil];
}

static NSValue *sizeValue(CGFloat width, CGFloat height)
{
  return [NSValue valueWithCGSize:{.width = width, .height = height}];
}

#pragma mark - CKDataSourceListener

- (void)componentDataSource:(id<CKDataSourceProtocol>)dataSource
     didModifyPreviousState:(CKDataSourceState *)previousState
                  withState:(CKDataSourceState *)state
          byApplyingChanges:(CKDataSourceAppliedChanges *)changes
{
  [_announcedChanges addObject:changes];
}

- (void)componentDataSource:(id<CKDataSourceProtocol>)dataSource
 willApplyDeferredChangeset:(CKDataSourceChangeset *)deferredChangeset {}

@end
