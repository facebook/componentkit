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
#import <ComponentKit/CKDataSourceInternal.h>
#import <ComponentKit/CKDataSourceItem.h>
#import <ComponentKit/CKDataSourceAppliedChanges.h>
#import <ComponentKit/CKDataSourceChangeset.h>
#import <ComponentKit/CKDataSourceConfigurationInternal.h>
#import <ComponentKit/CKDataSourceListener.h>
#import <ComponentKit/CKDataSourceState.h>

#import <ComponentKitTestHelpers/CKTestRunLoopRunning.h>

@interface CKDataSourceSplitChangesetTests : XCTestCase <CKComponentProvider, CKDataSourceListener>

@end

@implementation CKDataSourceSplitChangesetTests {
  NSMutableArray<CKDataSourceAppliedChanges *> *_announcedChanges;
  CKDataSourceState *_currentDataSourceState;
}

+ (CKComponent *)componentForModel:(id<NSObject>)model context:(id<NSObject>)context
{
  const CGSize size = [(NSValue *)model CGSizeValue];
  return CK::ComponentBuilder()
             .width(size.width)
             .height(size.height)
             .build();
}

- (void)setUp
{
  [super setUp];
  _announcedChanges = [NSMutableArray<CKDataSourceAppliedChanges *> new];
  _currentDataSourceState = nil;
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

  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL{
    return _announcedChanges.count == 2;
  }));
  XCTAssertEqualObjects(expectedAppliedChangesForInsertion(NSMakeRange(0, 2)), _announcedChanges[0]);
  XCTAssertEqualObjects(expectedAppliedChangesForInsertion(NSMakeRange(2, 2)), _announcedChanges[1]);
}

- (void)testSplitChangesetIsAppliedAsynchronously
{
  CKDataSource *const dataSource = dataSourceWithSplitChangesetOptions([self class], {
    .enabled = YES,
    .viewportBoundingSize = { .width = 10, .height = 20 },
    .layoutAxis = CKDataSourceLayoutAxisVertical,
  });
  [dataSource addListener:self];

  [dataSource applyChangeset:initialInsertionChangeset(4, {.width = 10, .height = 10}) mode:CKUpdateModeSynchronous userInfo:nil];
  XCTAssertEqual(1, _announcedChanges.count);
  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL{
    return _announcedChanges.count == 2;
  }));
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
  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL{
    return _announcedChanges.count == 2;
  }));
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
  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL{
    return _announcedChanges.count == 2;
  }));
  XCTAssertEqualObjects(userInfo, _announcedChanges[0].userInfo);
  XCTAssertEqualObjects(userInfo, _announcedChanges[1].userInfo);
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
  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL{
    return _announcedChanges.count == 2;
  }));
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
  [[[[CKDataSourceChangesetBuilder dataSourceChangeset]
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
  [[[[CKDataSourceChangesetBuilder dataSourceChangeset]
     withUpdatedItems:@{
                        [NSIndexPath indexPathForRow:0 inSection:0]: sizeValue(10, 10),
                        }]
    withInsertedItems:@{
                        [NSIndexPath indexPathForRow:1 inSection:0]: sizeValue(10, 10),
                        [NSIndexPath indexPathForRow:2 inSection:0]: sizeValue(10, 10),
                        }]
   build];
  [dataSource applyChangeset:updateChangeset mode:CKUpdateModeSynchronous userInfo:nil];
  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL{
    return _announcedChanges.count == 3;
  }));
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
  [[[[CKDataSourceChangesetBuilder dataSourceChangeset]
     withRemovedItems:[NSSet setWithObject:[NSIndexPath indexPathForRow:0 inSection:0]]]
    withInsertedItems:@{
                        [NSIndexPath indexPathForRow:0 inSection:0]: sizeValue(10, 20),
                        [NSIndexPath indexPathForRow:1 inSection:0]: sizeValue(10, 20),
                        }]
   build];
  [dataSource applyChangeset:removalChangeset mode:CKUpdateModeSynchronous userInfo:nil];
  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL{
    return _announcedChanges.count == 3;
  }));
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

- (void)testDataSourceDoesNotSplitUpdateChangesetsWhenOptionDisabled
{
  CKDataSource *const dataSource = dataSourceWithSplitChangesetOptions([self class], {
    .enabled = YES,
    .viewportBoundingSize = { .width = 10, .height = 20 },
    .layoutAxis = CKDataSourceLayoutAxisVertical,
  });
  [dataSource addListener:self];

  [dataSource applyChangeset:initialInsertionChangeset(4, {.width = 10, .height = 10}) mode:CKUpdateModeSynchronous userInfo:nil];
  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL{
    return _announcedChanges.count == 2;
  }));

  [dataSource applyChangeset:updateChangeset(NSMakeRange(0, 4), {.width = 10, .height = 20}) mode:CKUpdateModeSynchronous userInfo:nil];

  XCTAssertEqual(3, _announcedChanges.count);
  XCTAssertEqualObjects(expectedAppliedChangesForInsertion(NSMakeRange(0, 2)), _announcedChanges[0]);
  XCTAssertEqualObjects(expectedAppliedChangesForInsertion(NSMakeRange(2, 2)), _announcedChanges[1]);
  XCTAssertEqualObjects(expectedAppliedChangesForUpdate(NSMakeRange(0, 4)), _announcedChanges[2]);
}

- (void)testDataSourceSplitsUpdateChangesetsWhenOptionEnabled
{
  CKDataSource *const dataSource = dataSourceWithSplitChangesetOptions([self class], {
    .enabled = YES,
    .splitUpdates = YES,
    .viewportBoundingSize = { .width = 10, .height = 20 },
    .layoutAxis = CKDataSourceLayoutAxisVertical,
  });
  [dataSource addListener:self];

  [dataSource applyChangeset:initialInsertionChangeset(4, {.width = 10, .height = 10}) mode:CKUpdateModeSynchronous userInfo:nil];
  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL{
    return _announcedChanges.count == 2;
  }));
  [dataSource applyChangeset:updateChangeset(NSMakeRange(0, 4), {.width = 10, .height = 20}) mode:CKUpdateModeSynchronous userInfo:nil];

  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL{
    return _announcedChanges.count == 4;
  }));
  XCTAssertEqualObjects(expectedAppliedChangesForInsertion(NSMakeRange(0, 2)), _announcedChanges[0]);
  XCTAssertEqualObjects(expectedAppliedChangesForInsertion(NSMakeRange(2, 2)), _announcedChanges[1]);
  XCTAssertEqualObjects(expectedAppliedChangesForUpdate(NSMakeRange(0, 1)), _announcedChanges[2]);
  XCTAssertEqualObjects(expectedAppliedChangesForUpdate(NSMakeRange(1, 3)), _announcedChanges[3]);
}

- (void)testDataSourceSplitsChangesetCorrectlyForNonZeroOffset
{
  CKDataSource *const dataSource = dataSourceWithSplitChangesetOptions([self class], {
    .enabled = YES,
    .splitUpdates = YES,
    .viewportBoundingSize = { .width = 10, .height = 20 },
    .layoutAxis = CKDataSourceLayoutAxisVertical,
  });
  [dataSource addListener:self];
  [dataSource setViewport:{
    .contentOffset = { .x = 0, .y = 10 },
  }];

  [dataSource applyChangeset:initialInsertionChangeset(4, {.width = 10, .height = 10}) mode:CKUpdateModeSynchronous userInfo:nil];
  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL{
    return _announcedChanges.count == 2;
  }));

  [dataSource applyChangeset:updateChangeset(NSMakeRange(0, 4), {.width = 10, .height = 10}) mode:CKUpdateModeSynchronous userInfo:nil];

  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL{
    return _announcedChanges.count == 4;
  }));

  CKDataSourceAppliedChanges *const expectedAppliedChanges1 =
  [[CKDataSourceAppliedChanges alloc]
   initWithUpdatedIndexPaths:nil
   removedIndexPaths:nil
   removedSections:nil
   movedIndexPaths:nil
   insertedSections:[NSIndexSet indexSetWithIndex:0]
   insertedIndexPaths:[NSSet setWithObjects:[NSIndexPath indexPathForItem:0 inSection:0], [NSIndexPath indexPathForItem:1 inSection:0], [NSIndexPath indexPathForItem:2 inSection:0], nil]
   userInfo:nil];
  XCTAssertEqualObjects(expectedAppliedChanges1, _announcedChanges[0]);

  CKDataSourceAppliedChanges *const expectedAppliedChanges2 =
  [[CKDataSourceAppliedChanges alloc]
   initWithUpdatedIndexPaths:nil
   removedIndexPaths:nil
   removedSections:nil
   movedIndexPaths:nil
   insertedSections:nil
   insertedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:3 inSection:0]]
   userInfo:nil];
  XCTAssertEqualObjects(expectedAppliedChanges2, _announcedChanges[1]);

  CKDataSourceAppliedChanges *const expectedAppliedChanges3 =
  [[CKDataSourceAppliedChanges alloc]
   initWithUpdatedIndexPaths:[NSSet setWithObjects:[NSIndexPath indexPathForItem:1 inSection:0], [NSIndexPath indexPathForItem:2 inSection:0], nil]
   removedIndexPaths:nil
   removedSections:nil
   movedIndexPaths:nil
   insertedSections:nil
   insertedIndexPaths:nil
   userInfo:nil];
  XCTAssertEqualObjects(expectedAppliedChanges3, _announcedChanges[2]);

  CKDataSourceAppliedChanges *const expectedAppliedChanges4 =
  [[CKDataSourceAppliedChanges alloc]
   initWithUpdatedIndexPaths:[NSSet setWithObjects:[NSIndexPath indexPathForItem:0 inSection:0], [NSIndexPath indexPathForItem:3 inSection:0], nil]
   removedIndexPaths:nil
   removedSections:nil
   movedIndexPaths:nil
   insertedSections:nil
   insertedIndexPaths:nil
   userInfo:nil];
  XCTAssertEqualObjects(expectedAppliedChanges4, _announcedChanges[3]);
}

- (void)testDataSourceDoesNotProcessDeferredUpdateWhenItemIsRemoved
{
  CKDataSource *const dataSource = dataSourceWithSplitChangesetOptions([self class], {
    .enabled = YES,
    .splitUpdates = YES,
    .viewportBoundingSize = { .width = 10, .height = 20 },
    .layoutAxis = CKDataSourceLayoutAxisVertical,
  });
  [dataSource addListener:self];

  [dataSource applyChangeset:initialInsertionChangeset(4, {.width = 10, .height = 10}) mode:CKUpdateModeSynchronous userInfo:nil];
  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL{
    return _announcedChanges.count == 2;
  }));

  CKDataSourceChangeset *const updateWithRemovalChangeset =
  [[[[CKDataSourceChangesetBuilder
     dataSourceChangeset]
    withUpdatedItems:@{[NSIndexPath indexPathForItem:3 inSection:0]: [NSValue valueWithCGSize:{.width = 10, .height = 10}]}]
   withRemovedItems:[NSSet setWithObject:[NSIndexPath indexPathForItem:3 inSection:0]]]
   build];
  [dataSource applyChangeset:updateWithRemovalChangeset mode:CKUpdateModeSynchronous userInfo:nil];

  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL{
    return _announcedChanges.count == 3;
  }));
  XCTAssertEqualObjects(expectedAppliedChangesForInsertion(NSMakeRange(0, 2)), _announcedChanges[0]);
  XCTAssertEqualObjects(expectedAppliedChangesForInsertion(NSMakeRange(2, 2)), _announcedChanges[1]);
  CKDataSourceAppliedChanges *expectedRemovalChanges =
  [[CKDataSourceAppliedChanges alloc]
   initWithUpdatedIndexPaths:nil
   removedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:3 inSection:0]]
   removedSections:nil
   movedIndexPaths:nil
   insertedSections:nil
   insertedIndexPaths:nil
   userInfo:nil];
  XCTAssertEqualObjects(expectedRemovalChanges, _announcedChanges[2]);
}

- (void)testDataSourceDoesNotProcessDeferredUpdateWhenSectionIsRemoved
{
  CKDataSource *const dataSource = dataSourceWithSplitChangesetOptions([self class], {
    .enabled = YES,
    .splitUpdates = YES,
    .viewportBoundingSize = { .width = 10, .height = 20 },
    .layoutAxis = CKDataSourceLayoutAxisVertical,
  });
  [dataSource addListener:self];

  [dataSource applyChangeset:initialInsertionChangeset(4, {.width = 10, .height = 10}) mode:CKUpdateModeSynchronous userInfo:nil];
  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL{
    return _announcedChanges.count == 2;
  }));

  CKDataSourceChangeset *const updateWithRemovalChangeset =
  [[[[CKDataSourceChangesetBuilder
      dataSourceChangeset]
     withUpdatedItems:@{[NSIndexPath indexPathForItem:3 inSection:0]: [NSValue valueWithCGSize:{.width = 10, .height = 10}]}]
    withRemovedSections:[NSIndexSet indexSetWithIndex:0]]
   build];
  [dataSource applyChangeset:updateWithRemovalChangeset mode:CKUpdateModeSynchronous userInfo:nil];

  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL{
    return _announcedChanges.count == 3;
  }));
  XCTAssertEqualObjects(expectedAppliedChangesForInsertion(NSMakeRange(0, 2)), _announcedChanges[0]);
  XCTAssertEqualObjects(expectedAppliedChangesForInsertion(NSMakeRange(2, 2)), _announcedChanges[1]);
  CKDataSourceAppliedChanges *expectedRemovalChanges =
  [[CKDataSourceAppliedChanges alloc]
   initWithUpdatedIndexPaths:nil
   removedIndexPaths:nil
   removedSections:[NSIndexSet indexSetWithIndex:0]
   movedIndexPaths:nil
   insertedSections:nil
   insertedIndexPaths:nil
   userInfo:nil];
  XCTAssertEqualObjects(expectedRemovalChanges, _announcedChanges[2]);
}

- (void)testDataSourceShiftsUpdatedChangesetIndicesWhenItemsAreRemoved
{
  CKDataSource *const dataSource = dataSourceWithSplitChangesetOptions([self class], {
    .enabled = YES,
    .splitUpdates = YES,
    .viewportBoundingSize = { .width = 10, .height = 20 },
    .layoutAxis = CKDataSourceLayoutAxisVertical,
  });
  [dataSource addListener:self];

  [dataSource applyChangeset:initialInsertionChangeset(4, {.width = 10, .height = 10}) mode:CKUpdateModeSynchronous userInfo:nil];
  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL{
    return _announcedChanges.count == 2;
  }));

  CKDataSourceChangeset *const updateWithRemovalChangeset =
  [[[[CKDataSourceChangesetBuilder
      dataSourceChangeset]
     withUpdatedItems:@{[NSIndexPath indexPathForItem:2 inSection:0]: [NSValue valueWithCGSize:{.width = 10, .height = 10}]}]
    withRemovedItems:[NSSet setWithObject:[NSIndexPath indexPathForItem:0 inSection:0]]]
   build];
  [dataSource applyChangeset:updateWithRemovalChangeset mode:CKUpdateModeSynchronous userInfo:nil];

  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL{
    return _announcedChanges.count == 4;
  }));
  XCTAssertEqualObjects(expectedAppliedChangesForInsertion(NSMakeRange(0, 2)), _announcedChanges[0]);
  XCTAssertEqualObjects(expectedAppliedChangesForInsertion(NSMakeRange(2, 2)), _announcedChanges[1]);
  CKDataSourceAppliedChanges *const expectedRemovalChanges =
  [[CKDataSourceAppliedChanges alloc]
   initWithUpdatedIndexPaths:nil
   removedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:0 inSection:0]]
   removedSections:nil
   movedIndexPaths:nil
   insertedSections:nil
   insertedIndexPaths:nil
   userInfo:nil];
  XCTAssertEqualObjects(expectedRemovalChanges, _announcedChanges[2]);

  CKDataSourceAppliedChanges *const expectedUpdateChanges =
  [[CKDataSourceAppliedChanges alloc]
   initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:1 inSection:0]]
   removedIndexPaths:nil
   removedSections:nil
   movedIndexPaths:nil
   insertedSections:nil
   insertedIndexPaths:nil
   userInfo:nil];
  XCTAssertEqualObjects(expectedUpdateChanges, _announcedChanges[3]);
}

- (void)testDataSourceShiftsUpdatedChangesetIndicesWhenSectionsAreRemoved
{
  CKDataSource *const dataSource = dataSourceWithSplitChangesetOptions([self class], {
    .enabled = YES,
    .splitUpdates = YES,
    .viewportBoundingSize = { .width = 10, .height = 10 },
    .layoutAxis = CKDataSourceLayoutAxisVertical,
  });
  [dataSource addListener:self];

  CKDataSourceChangeset *const insertionChangeset =
  [[[[CKDataSourceChangesetBuilder dataSourceChangeset]
     withInsertedSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)]]
    withInsertedItems:@{
                        [NSIndexPath indexPathForItem:0 inSection:0]: [NSValue valueWithCGSize:{.width = 10, .height = 10}],
                        [NSIndexPath indexPathForItem:0 inSection:1]: [NSValue valueWithCGSize:{.width = 10, .height = 10}]
                        }]
   build];
  [dataSource applyChangeset:insertionChangeset mode:CKUpdateModeSynchronous userInfo:nil];
  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL{
    return _announcedChanges.count == 2;
  }));

  CKDataSourceChangeset *const updateWithRemovalChangeset =
  [[[[CKDataSourceChangesetBuilder
      dataSourceChangeset]
     withUpdatedItems:@{[NSIndexPath indexPathForItem:0 inSection:1]: [NSValue valueWithCGSize:{.width = 10, .height = 10}]}]
    withRemovedSections:[NSIndexSet indexSetWithIndex:0]]
   build];
  [dataSource applyChangeset:updateWithRemovalChangeset mode:CKUpdateModeSynchronous userInfo:nil];

  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL{
    return _announcedChanges.count == 4;
  }));
  CKDataSourceAppliedChanges *const expectedRemovalChanges =
  [[CKDataSourceAppliedChanges alloc]
   initWithUpdatedIndexPaths:nil
   removedIndexPaths:nil
   removedSections:[NSIndexSet indexSetWithIndex:0]
   movedIndexPaths:nil
   insertedSections:nil
   insertedIndexPaths:nil
   userInfo:nil];
  XCTAssertEqualObjects(expectedRemovalChanges, _announcedChanges[2]);

  CKDataSourceAppliedChanges *const expectedUpdateChanges =
  [[CKDataSourceAppliedChanges alloc]
   initWithUpdatedIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:0 inSection:0]]
   removedIndexPaths:nil
   removedSections:nil
   movedIndexPaths:nil
   insertedSections:nil
   insertedIndexPaths:nil
   userInfo:nil];
  XCTAssertEqualObjects(expectedUpdateChanges, _announcedChanges[3]);
}

- (void)testDataSourceStateAfterApplyingSplitUpdateChangesetContainsCorrectModels
{
  CKDataSource *const dataSource = dataSourceWithSplitChangesetOptions([self class], {
    .enabled = YES,
    .splitUpdates = YES,
    .viewportBoundingSize = { .width = 10, .height = 10 },
    .layoutAxis = CKDataSourceLayoutAxisVertical,
  });
  [dataSource addListener:self];

  CKDataSourceChangeset *const insertionChangeset =
  [[[[CKDataSourceChangesetBuilder dataSourceChangeset]
     withInsertedSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)]]
    withInsertedItems:@{
                        [NSIndexPath indexPathForItem:0 inSection:0]: [NSValue valueWithCGSize:{.width = 10, .height = 10}],
                        [NSIndexPath indexPathForItem:0 inSection:1]: [NSValue valueWithCGSize:{.width = 10, .height = 10}]
                        }]
   build];
  [dataSource applyChangeset:insertionChangeset mode:CKUpdateModeSynchronous userInfo:nil];
  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL{
    return _announcedChanges.count == 2;
  }));

  CKDataSourceChangeset *const updateWithInsertionChangeset =
  [[[[CKDataSourceChangesetBuilder
      dataSourceChangeset]
     withInsertedItems:@{[NSIndexPath indexPathForItem:1 inSection:1]: [NSValue valueWithCGSize:{.width = 10, .height = 10}]}]
     withUpdatedItems:@{[NSIndexPath indexPathForItem:0 inSection:1]: [NSValue valueWithCGSize:{.width = 10, .height = 10}]}]
   build];
  [dataSource applyChangeset:updateWithInsertionChangeset mode:CKUpdateModeSynchronous userInfo:nil];

  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL{
    return _announcedChanges.count == 4;
  }));

  NSValue *const expectedModel = [NSValue valueWithCGSize:{.width = 10, .height = 10}];
  [_currentDataSourceState enumerateObjectsUsingBlock:^(CKDataSourceItem *item, NSIndexPath *indexPath, BOOL *stop) {
    XCTAssertEqualObjects(expectedModel, item.model);
  }];
}

static CKDataSource *dataSourceWithSplitChangesetOptions(Class<CKComponentProvider> componentProvider, const CKDataSourceSplitChangesetOptions &splitChangesetOptions)
{
  CKDataSourceConfiguration *const config =
  [[CKDataSourceConfiguration alloc]
   initWithComponentProvider:componentProvider
   context:nil
   sizeRange:{}
   options:{.splitChangesetOptions = splitChangesetOptions}
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
  return [[[[CKDataSourceChangesetBuilder dataSourceChangeset]
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
  return [[[CKDataSourceChangesetBuilder dataSourceChangeset] withInsertedItems:items] build];
}

static CKDataSourceChangeset *updateChangeset(NSRange range, CGSize size)
{
  NSMutableDictionary<NSIndexPath *, NSValue *> *const items = [NSMutableDictionary<NSIndexPath *, NSValue *> dictionaryWithCapacity:range.length];
  for (NSUInteger i = 0; i < range.length; i++) {
    items[[NSIndexPath indexPathForItem:i + range.location inSection:0]] = [NSValue valueWithCGSize:size];
  }
  return [[[CKDataSourceChangesetBuilder dataSourceChangeset] withUpdatedItems:items] build];
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

static CKDataSourceAppliedChanges *expectedAppliedChangesForUpdate(NSRange range)
{
  NSMutableSet<NSIndexPath *> *const updatedIndexPaths = [NSMutableSet<NSIndexPath *> setWithCapacity:range.length];
  for (NSUInteger i = 0; i < range.length; i++) {
    [updatedIndexPaths addObject:[NSIndexPath indexPathForItem:range.location + i inSection:0]];
  }
  return [[CKDataSourceAppliedChanges alloc]
          initWithUpdatedIndexPaths:updatedIndexPaths
          removedIndexPaths:nil
          removedSections:nil
          movedIndexPaths:nil
          insertedSections:nil
          insertedIndexPaths:nil
          userInfo:nil];
}

static NSValue *sizeValue(CGFloat width, CGFloat height)
{
  return [NSValue valueWithCGSize:{.width = width, .height = height}];
}

#pragma mark - CKDataSourceListener

- (void)dataSource:(CKDataSource *)dataSource
     didModifyPreviousState:(CKDataSourceState *)previousState
                  withState:(CKDataSourceState *)state
          byApplyingChanges:(CKDataSourceAppliedChanges *)changes
{
  [_announcedChanges addObject:changes];
  _currentDataSourceState = state;
}

- (void)dataSource:(CKDataSource *)dataSource
 willApplyDeferredChangeset:(CKDataSourceChangeset *)deferredChangeset {}

@end
