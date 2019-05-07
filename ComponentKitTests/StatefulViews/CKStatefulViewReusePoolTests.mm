/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import <ComponentKitTestHelpers/CKTestRunLoopRunning.h>

#import <ComponentKit/CKStatefulViewReusePool.h>

#import "CKTestStatefulViewComponent.h"

@interface CKStatefulViewReusePoolTests : XCTestCase
@end

@interface CKOtherStatefulViewComponentController : CKStatefulViewComponentController
@end

@interface CKStatefulViewComponentWithMaximumController : CKStatefulViewComponentController
@end
@implementation CKStatefulViewComponentWithMaximumController

+ (NSInteger)maximumPoolSize:(id)context
{
  return 1;
}

@end

@interface EnqueueOnDealloc: NSObject
+ (instancetype)newWithPool:(CKStatefulViewReusePool *)pool;
@end

@implementation CKStatefulViewReusePoolTests

- (void)testDequeueingFromEmptyPoolReturnsNil
{
  CKStatefulViewReusePool *pool = [[CKStatefulViewReusePool alloc] init];
  UIView *container = [[UIView alloc] init];
  XCTAssertNil([pool dequeueStatefulViewForControllerClass:[CKTestStatefulViewComponentController class]
                                       preferredSuperview:container
                                                  context:nil], @"Didn't expect to vend view from empty pool");
}

- (void)testEnqueueingViewThenDequeueingReturnsSameView
{
  __block BOOL calledBlock = NO;
  CKStatefulViewReusePool *pool = [[CKStatefulViewReusePool alloc] init];
  CKTestStatefulView *view = [[CKTestStatefulView alloc] init];
  [pool enqueueStatefulView:view
         forControllerClass:[CKTestStatefulViewComponentController class]
                    context:nil
         mayRelinquishBlock:^BOOL{
           calledBlock = YES;
           return YES;
         }];
  CKRunRunLoopUntilBlockIsTrue(^BOOL{
    return calledBlock;
  });
  UIView *container = [[UIView alloc] init];
  UIView *dequeuedView = [pool dequeueStatefulViewForControllerClass:[CKTestStatefulViewComponentController class]
                                                  preferredSuperview:container
                                                             context:nil];
  XCTAssertEqualObjects(dequeuedView, view, @"Expected enqueued view to be returned");
}

- (void)testEnqueueingViewThenDequeueingWhileRefusingToRelinquishReturnsNil
{
  __block BOOL calledBlock = NO;
  CKStatefulViewReusePool *pool = [[CKStatefulViewReusePool alloc] init];
  CKTestStatefulView *view = [[CKTestStatefulView alloc] init];
  [pool enqueueStatefulView:view
         forControllerClass:[CKTestStatefulViewComponentController class]
                    context:nil
         mayRelinquishBlock:^BOOL{
           calledBlock = YES;
           return NO;
         }];

  CKRunRunLoopUntilBlockIsTrue(^BOOL{
    return calledBlock;
  });

  UIView *container = [[UIView alloc] init];
  UIView *dequeuedView = [pool dequeueStatefulViewForControllerClass:[CKTestStatefulViewComponentController class]
                                                  preferredSuperview:container
                                                             context:nil];
  XCTAssertTrue(calledBlock && dequeuedView == nil, @"Expected dequeued view to be nil");
}

- (void)testEnqueueingViewThenDequeueingWithDifferentControllerClassReturnsNil
{
  CKStatefulViewReusePool *pool = [[CKStatefulViewReusePool alloc] init];
  CKTestStatefulView *view = [[CKTestStatefulView alloc] init];
  [pool enqueueStatefulView:view
         forControllerClass:[CKTestStatefulViewComponentController class]
                    context:nil
         mayRelinquishBlock:^BOOL{
           return YES;
         }];
  UIView *container = [[UIView alloc] init];
  XCTAssertNil([pool dequeueStatefulViewForControllerClass:[CKOtherStatefulViewComponentController class]
                                       preferredSuperview:container
                                                  context:nil], @"Didn't expect to vend view, controller mismatch");
}

- (void)testEnqueueingTwoViewsThenDequeueingWithPreferredSuperviewReturnsViewWithMatchingSuperview
{
  CKStatefulViewReusePool *pool = [[CKStatefulViewReusePool alloc] init];

  __block int blockCallCount = 0;

  UIView *container1 = [[UIView alloc] init];
  CKTestStatefulView *view1 = [[CKTestStatefulView alloc] init];
  [container1 addSubview:view1];
  [pool enqueueStatefulView:view1
         forControllerClass:[CKTestStatefulViewComponentController class]
                    context:nil
         mayRelinquishBlock:^BOOL{
           blockCallCount++;
           return YES;
         }];

  UIView *container2 = [[UIView alloc] init];
  CKTestStatefulView *view2 = [[CKTestStatefulView alloc] init];
  [container2 addSubview:view2];
  [pool enqueueStatefulView:view2
         forControllerClass:[CKTestStatefulViewComponentController class]
                    context:nil
         mayRelinquishBlock:^BOOL{
           blockCallCount++;
           return YES;
         }];

  CKRunRunLoopUntilBlockIsTrue(^BOOL{
    return blockCallCount == 2;
  });

  UIView *dequeuedView = [pool dequeueStatefulViewForControllerClass:[CKTestStatefulViewComponentController class]
                                                  preferredSuperview:container1
                                                             context:nil];
  XCTAssertTrue(dequeuedView == view1, @"Expected view in container1 to be returned");
}

- (void)testDequeueingViewDoesNotLaterDequeueTheSameViewForTheOriginalSuperview
{
  CKStatefulViewReusePool *pool = [[CKStatefulViewReusePool alloc] init];
  CKTestStatefulView *view = [[CKTestStatefulView alloc] init];

  UIView *container1 = [[UIView alloc] init];
  [container1 addSubview:view];
  [pool enqueueStatefulView:view
         forControllerClass:[CKTestStatefulViewComponentController class]
                    context:nil
         mayRelinquishBlock:^BOOL{
           return YES;
         }];

  UIView *container2 = [[UIView alloc] init];
  [pool dequeueStatefulViewForControllerClass:[CKTestStatefulViewComponentController class]
                           preferredSuperview:container2
                                      context:nil];

  XCTAssertNil([pool dequeueStatefulViewForControllerClass:[CKTestStatefulViewComponentController class]
                                       preferredSuperview:container1
                                                  context:nil], @"Didn't expect to vend view.");
}

- (void)testEnqueueingViewThenDequeueingWithDifferentContextReturnsNewView
{
  CKStatefulViewReusePool *pool = [[CKStatefulViewReusePool alloc] init];
  UIView *containerView = [[UIView alloc] init];

  UIView *firstView =[[UIView alloc] init];
  [pool enqueueStatefulView:firstView
         forControllerClass:[CKTestStatefulViewComponentController class]
                    context:@"context1"
         mayRelinquishBlock:^BOOL{
           return YES;
         }];

  UIView *dequeuedView = [pool dequeueStatefulViewForControllerClass:[CKTestStatefulViewComponentController class]
                                                     preferredSuperview:containerView
                                                                context:@"context2"];
  XCTAssertTrue(firstView != dequeuedView, @"Expected different view to be vended.");
}

- (void)testEnqueueingOneViewThatLostItSuperviewThenDequeueingWithDifferentPreferredSuperviews
{
  CKStatefulViewReusePool *pool = [[CKStatefulViewReusePool alloc] init];

  __block BOOL calledBlock = NO;
  UIView *container1 = [[UIView alloc] init];
  CKTestStatefulView *view = [[CKTestStatefulView alloc] init];
  [container1 addSubview:view];
  [pool enqueueStatefulView:view
         forControllerClass:[CKTestStatefulViewComponentController class]
                    context:nil
         mayRelinquishBlock:^BOOL{
           calledBlock = YES;
           return YES;
         }];

  CKRunRunLoopUntilBlockIsTrue(^BOOL{
    return calledBlock;
  });

  // remove the statefull view from the container
  [view removeFromSuperview];

  UIView *container2 = [[UIView alloc] init];
  UIView *dequeuedView = [pool dequeueStatefulViewForControllerClass:[CKTestStatefulViewComponentController class]
                                                  preferredSuperview:container2
                                                             context:nil];
  XCTAssertTrue(dequeuedView == view, @"Expected view in container1 to be returned");

  XCTAssertNil([pool dequeueStatefulViewForControllerClass:[CKTestStatefulViewComponentController class]
                                        preferredSuperview:container1
                                                   context:nil], @"Didn't expect to vend view from empty pool");
  XCTAssertNil([pool dequeueStatefulViewForControllerClass:[CKTestStatefulViewComponentController class]
                                        preferredSuperview:container2
                                                   context:nil], @"Didn't expect to vend view from empty pool");
}

- (void)testMaximumPoolSizeOfOneByEnqueueingTwoViewsThenDequeueingTwoViewsReturnsNewView
{
  CKStatefulViewReusePool *pool = [[CKStatefulViewReusePool alloc] init];

  __block int calledBlockCount = 0;

  UIView *container1 = [[UIView alloc] init];
  CKTestStatefulView *view1 = [[CKTestStatefulView alloc] init];
  [container1 addSubview:view1];
  [pool enqueueStatefulView:view1
         forControllerClass:[CKStatefulViewComponentWithMaximumController class]
                    context:nil
         mayRelinquishBlock:^BOOL{
           calledBlockCount++;
           return YES;
         }];
  
  UIView *container2 = [[UIView alloc] init];
  CKTestStatefulView *view2 = [[CKTestStatefulView alloc] init];
  [container2 addSubview:view2];
  [pool enqueueStatefulView:view2
         forControllerClass:[CKStatefulViewComponentWithMaximumController class]
                    context:nil
         mayRelinquishBlock:^BOOL{
           calledBlockCount++;
           return YES;
         }];

  CKRunRunLoopUntilBlockIsTrue(^BOOL{
    return calledBlockCount == 2;
  });
  
  UIView *dequeuedView1 = [pool dequeueStatefulViewForControllerClass:[CKStatefulViewComponentWithMaximumController class]
                                                  preferredSuperview:container1
                                                             context:nil];
  XCTAssertTrue(dequeuedView1 == view1, @"Expected view in container1 to be returned");
  
  UIView *dequeuedView2 = [pool dequeueStatefulViewForControllerClass:[CKStatefulViewComponentWithMaximumController class]
                                                   preferredSuperview:container2
                                                              context:nil];
  XCTAssertTrue(dequeuedView2 != view2, @"Didn't expect view in container2 to be returned");
}

#pragma mark - Pending pool tests

- (void)testEnqueueingViewThenDequeueingWithPendingEnabledReturnsSameViewImmediately
{
  __block BOOL calledBlock = NO;
  CKStatefulViewReusePool *pool = [[CKStatefulViewReusePool alloc] init];

  // Warm up the pool so that pending reuse will occur
  [pool enqueueStatefulView:[[CKTestStatefulView alloc] init]
         forControllerClass:[CKTestStatefulViewComponentController class]
                    context:nil
         mayRelinquishBlock:^BOOL{
           calledBlock = YES;
           return YES;
         }];

  CKRunRunLoopUntilBlockIsTrue(^BOOL{
    return calledBlock;
  });

  [pool dequeueStatefulViewForControllerClass:[CKTestStatefulViewComponentController class]
                           preferredSuperview:nil
                                      context:nil];

  calledBlock = NO;
  CKTestStatefulView *view = [[CKTestStatefulView alloc] init];
  [pool enqueueStatefulView:view
         forControllerClass:[CKTestStatefulViewComponentController class]
                    context:nil
         mayRelinquishBlock:^BOOL{
           calledBlock = YES;
           return YES;
         }];

  UIView *container = [[UIView alloc] init];
  UIView *dequeuedView = [pool dequeueStatefulViewForControllerClass:[CKTestStatefulViewComponentController class]
                                                  preferredSuperview:container
                                                             context:nil];
  XCTAssertTrue(calledBlock);
  XCTAssertEqualObjects(dequeuedView, view, @"Expected enqueued view to be returned");
}

- (void)testEnqueueingViewThenDequeueingWhileRefusingToRelinquishWithPendingEnabledReturnsNilImmediately
{
  __block BOOL calledBlock = NO;
  CKStatefulViewReusePool *pool = [[CKStatefulViewReusePool alloc] init];

  // Warm up the pool so that pending reuse will occur
  [pool enqueueStatefulView:[[CKTestStatefulView alloc] init]
         forControllerClass:[CKTestStatefulViewComponentController class]
                    context:nil
         mayRelinquishBlock:^BOOL{
           calledBlock = YES;
           return YES;
         }];

  CKRunRunLoopUntilBlockIsTrue(^BOOL{
    return calledBlock;
  });

  [pool dequeueStatefulViewForControllerClass:[CKTestStatefulViewComponentController class]
                           preferredSuperview:nil
                                      context:nil];

  calledBlock = NO;
  CKTestStatefulView *view = [[CKTestStatefulView alloc] init];
  [pool enqueueStatefulView:view
         forControllerClass:[CKTestStatefulViewComponentController class]
                    context:nil
         mayRelinquishBlock:^BOOL{
           calledBlock = YES;
           return NO;
         }];

  UIView *container = [[UIView alloc] init];
  UIView *dequeuedView = [pool dequeueStatefulViewForControllerClass:[CKTestStatefulViewComponentController class]
                                                  preferredSuperview:container
                                                             context:nil];
  XCTAssertTrue(calledBlock);
  XCTAssertTrue(dequeuedView == nil, @"Expected dequeued view to be nil");
}

- (void)test_WhenPurgingPendingPoolLeadsToEnqueueing_DoesNotCrash {
  for (auto i = 0; i < 10000; i++) {
    auto pool = [CKStatefulViewReusePool new];
    auto eod = [EnqueueOnDealloc newWithPool:pool];
    [pool enqueueStatefulView:[CKTestStatefulView new]
           forControllerClass:[CKTestStatefulViewComponentController class]
                      context:nil
           mayRelinquishBlock:^{
             // Capturing what would be the only strong reference to eod when the block runs.
             // This will cause eod to be released after the block returns.
             (void)eod.class;
             return YES;
           }];
    eod = nil;
  }
}

@end

@implementation CKOtherStatefulViewComponentController
@end

@implementation EnqueueOnDealloc {
  CKStatefulViewReusePool *_pool;
}

+ (instancetype)newWithPool:(CKStatefulViewReusePool *)pool {
  auto obj = [super new];
  obj->_pool = pool;
  return obj;
}

- (void)dealloc {
  [_pool enqueueStatefulView:[CKTestStatefulView new]
          forControllerClass:[CKTestStatefulViewComponentController class]
                     context:nil
          mayRelinquishBlock:^{
                       return YES;
                     }];
}

@end
