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

#import <ComponentKit/CKStatefulViewReusePool.h>

#import "CKTestStatefulViewComponent.h"

@interface CKStatefulViewReusePoolTests : XCTestCase
@end

@interface CKOtherStatefulViewComponentController : CKStatefulViewComponentController
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
  CKStatefulViewReusePool *pool = [[CKStatefulViewReusePool alloc] init];
  CKTestStatefulView *view = [[CKTestStatefulView alloc] init];
  [pool enqueueStatefulView:view
         forControllerClass:[CKTestStatefulViewComponentController class]
                    context:nil];
  UIView *container = [[UIView alloc] init];
  UIView *dequeuedView = [pool dequeueStatefulViewForControllerClass:[CKTestStatefulViewComponentController class]
                                                  preferredSuperview:container
                                                             context:nil];
  XCTAssertTrue(dequeuedView == view, @"Expected enqueued view to be returned");
}

- (void)testEnqueueingViewThenDequeueingWithDifferentControllerClassReturnsNil
{
  CKStatefulViewReusePool *pool = [[CKStatefulViewReusePool alloc] init];
  CKTestStatefulView *view = [[CKTestStatefulView alloc] init];
  [pool enqueueStatefulView:view
         forControllerClass:[CKTestStatefulViewComponentController class]
                    context:nil];
  UIView *container = [[UIView alloc] init];
  XCTAssertNil([pool dequeueStatefulViewForControllerClass:[CKOtherStatefulViewComponentController class]
                                       preferredSuperview:container
                                                  context:nil], @"Didn't expect to vend view, controller mismatch");
}

- (void)testEnqueueingTwoViewsThenDequeueingWithPreferredSuperviewReturnsViewWithMatchingSuperview
{
  CKStatefulViewReusePool *pool = [[CKStatefulViewReusePool alloc] init];

  UIView *container1 = [[UIView alloc] init];
  CKTestStatefulView *view1 = [[CKTestStatefulView alloc] init];
  [container1 addSubview:view1];
  [pool enqueueStatefulView:view1
         forControllerClass:[CKTestStatefulViewComponentController class]
                    context:nil];

  UIView *container2 = [[UIView alloc] init];
  CKTestStatefulView *view2 = [[CKTestStatefulView alloc] init];
  [container2 addSubview:view2];
  [pool enqueueStatefulView:view2
         forControllerClass:[CKTestStatefulViewComponentController class]
                    context:nil];

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
                    context:nil];

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
                    context:@"context1"];

  UIView *dequeuedView = [pool dequeueStatefulViewForControllerClass:[CKTestStatefulViewComponentController class]
                                                     preferredSuperview:containerView
                                                                context:@"context2"];
  XCTAssertTrue(firstView != dequeuedView, @"Expected different view to be vended.");
}

@end

@implementation CKOtherStatefulViewComponentController
@end
