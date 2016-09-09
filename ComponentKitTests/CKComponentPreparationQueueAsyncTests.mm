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

#import <ComponentKit/CKComponentPreparationQueue.h>
#import <ComponentKit/CKComponentPreparationQueueInternal.h>

#import <ComponentKitTestLib/CKTestRunLoopRunning.h>

using namespace CK::ArrayController;

#pragma mark - Helpers

// Creates a simple input item.
static CKComponentPreparationInputItem *fbcpq_passthroughInputItem(NSString *UUID)
{
  return [[CKComponentPreparationInputItem alloc] initWithReplacementModel:nil
                                                          lifecycleManager:nil
                                                           constrainedSize:CKSizeRange()
                                                                   oldSize:{0, 0}
                                                                      UUID:UUID
                                                           sourceIndexPath:nil
                                                      destinationIndexPath:nil
                                                                changeType:CKArrayControllerChangeTypeUnknown
                                                               passthrough:YES
                                                                   context:nil];
}

// Returns the number of output items in an array with a UUID matching the one given.
static NSUInteger fbcpq_countOfOutputItemsWithUUID(NSArray *outputItems, NSString *UUID)
{
  return [[outputItems indexesOfObjectsPassingTest:^BOOL(CKComponentPreparationOutputItem *item, NSUInteger idx, BOOL *stop) {
    return [[item UUID] isEqualToString:UUID];
  }] count];
}

#pragma mark - Tests

@interface CKComponentPreparationQueueAsyncTests : XCTestCase
@end

@implementation CKComponentPreparationQueueAsyncTests

- (void)testMultipleObjectBatch
{
  // Arrange: Create a preparation queue and a batch containing two input items.
  CKComponentPreparationQueue *queue = [[CKComponentPreparationQueue alloc] initWithQueueWidth:1];
  CKComponentPreparationInputBatch inputBatch;
  inputBatch.items.push_back(fbcpq_passthroughInputItem(@"one"));
  inputBatch.items.push_back(fbcpq_passthroughInputItem(@"two"));

  // Act: Enqueue the batch of two items, and a block callback that should run when the
  //      two items have finished being prepared as output items. Block until the callback has been run.
  __block NSArray *outputBatch = nil;
  [queue enqueueBatch:inputBatch
                block:^(const Sections &sections, PreparationBatchID ID, NSArray *batch, BOOL isContiguousTailInsertiong) {
                  outputBatch = batch;
                }];
  CKRunRunLoopUntilBlockIsTrue(^BOOL{ return outputBatch != nil; });

  // Assert
  XCTAssertEqual([outputBatch count], (NSUInteger)2,
                 @"The output batch should contain as many items as the input batch");
  XCTAssertEqual(fbcpq_countOfOutputItemsWithUUID(outputBatch, @"one"), (NSUInteger)1,
                 @"The output batch should contain one output item with a UUID of 'one', matching the input item");
  XCTAssertEqual(fbcpq_countOfOutputItemsWithUUID(outputBatch, @"two"), (NSUInteger)1,
                 @"The output batch should contain one output item with a UUID of 'two', matching the input item");
}

@end
