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

#import <ComponentKitTestHelpers/CKComponentLifecycleTestHelper.h>
#import <ComponentKitTestHelpers/CKLifecycleTestComponent.h>
#import <ComponentKitTestHelpers/CKTestRunLoopRunning.h>

#import <ComponentKit/CKComponentControllerEvents.h>
#import <ComponentKit/CKComponentProvider.h>
#import <ComponentKit/CKComponentSubclass.h>

#import "CKTestStatefulViewComponent.h"

@interface CKStatefulViewComponentControllerTests : XCTestCase
@end

@implementation CKStatefulViewComponentControllerTests

static CKComponent *componentProvider(id<NSObject> model, id<NSObject>context)
{
  return [CKTestStatefulViewComponent newWithColor:(UIColor *)model];
}

- (void)testMountingStatefulViewComponentCreatesStatefulView
{
  CKComponentLifecycleTestHelper *componentLifecycleTestController = [[CKComponentLifecycleTestHelper alloc] initWithComponentProvider:componentProvider
                                                                                                                             sizeRangeProvider:nil];
  const CKComponentLifecycleTestHelperState state = [componentLifecycleTestController prepareForUpdateWithModel:[UIColor blueColor]
                                                                                                    constrainedSize:{{100, 100}, {100, 100}}
                                                                                                            context:nil];
  [componentLifecycleTestController updateWithState:state];

  UIView *view = [UIView new];
  [componentLifecycleTestController attachToView:view];

  auto component = (CKTestStatefulViewComponent *)state.componentLayout.component;
  auto controller = (CKTestStatefulViewComponentController *)[component controller];
  auto statefulView = [controller statefulView];
  XCTAssertTrue([statefulView isKindOfClass:[CKTestStatefulView class]], @"Expected stateful view but couldn't find it");
  XCTAssertTrue(CGRectEqualToRect([statefulView frame], CGRectMake(0, 0, 100, 100)), @"Expected view to be sized to match component");
  XCTAssertEqualObjects([statefulView backgroundColor], [UIColor blueColor], @"Expected view to be configured");
}

- (void)testUnmountingStatefulViewComponentEventuallyRelinquishesStatefulView
{
  CKComponentLifecycleTestHelper *componentLifecycleTestController = [[CKComponentLifecycleTestHelper alloc] initWithComponentProvider:componentProvider
                                                                                                                             sizeRangeProvider:nil];
  const CKComponentLifecycleTestHelperState state = [componentLifecycleTestController prepareForUpdateWithModel:nil
                                                                                                    constrainedSize:{{100, 100}, {100, 100}}
                                                                                                            context:nil];
  [componentLifecycleTestController updateWithState:state];

  UIView *view = [UIView new];
  [componentLifecycleTestController attachToView:view];

  auto component = (CKTestStatefulViewComponent *)state.componentLayout.component;
  auto controller = (CKTestStatefulViewComponentController *)[component controller];
  XCTAssertNotNil([controller statefulView], @"Expected to have a stateful view while mounted");

  [componentLifecycleTestController detachFromView];
  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL{
    return [controller statefulView] == nil;
  }), @"Expected view to be relinquished");
}

- (void)testMountingStatefulViewComponentOnNewRootViewMovesStatefulView
{
  CKComponentLifecycleTestHelper *componentLifecycleTestController = [[CKComponentLifecycleTestHelper alloc] initWithComponentProvider:componentProvider
                                                                                                                             sizeRangeProvider:nil];
  const CKComponentLifecycleTestHelperState state = [componentLifecycleTestController prepareForUpdateWithModel:nil
                                                                                                    constrainedSize:{{100, 100}, {100, 100}}
                                                                                                            context:nil];
  [componentLifecycleTestController updateWithState:state];

  auto controller = (CKTestStatefulViewComponentController *)[(CKTestStatefulViewComponent *)state.componentLayout.component controller];

  UIView *view1 = [UIView new];
  [componentLifecycleTestController attachToView:view1];
  XCTAssertTrue([[controller statefulView] isDescendantOfView:view1], @"Expected view to be in view1");

  UIView *view2 = [UIView new];
  [componentLifecycleTestController attachToView:view2];
  XCTAssertTrue([[controller statefulView] isDescendantOfView:view2], @"Expected view to be moved to view2");
}

- (void)testUpdatingStatefulViewComponentSizeUpdatesStatefulViewSize
{
  CKComponentLifecycleTestHelper *componentLifecycleTestController = [[CKComponentLifecycleTestHelper alloc] initWithComponentProvider:componentProvider
                                                                                                                             sizeRangeProvider:nil];
  const CKComponentLifecycleTestHelperState state = [componentLifecycleTestController prepareForUpdateWithModel:nil
                                                                                                    constrainedSize:{{100, 100}, {100, 100}}
                                                                                                            context:nil];
  [componentLifecycleTestController updateWithState:state];
  UIView *view = [UIView new];
  [componentLifecycleTestController attachToView:view];
  auto controller = (CKTestStatefulViewComponentController *)[(CKTestStatefulViewComponent *)state.componentLayout.component controller];

  [componentLifecycleTestController updateWithState:[componentLifecycleTestController prepareForUpdateWithModel:nil
                                                                                                constrainedSize:{{50, 50}, {50, 50}}
                                                                                                        context:nil]];
  XCTAssertTrue(CGRectEqualToRect([[controller statefulView] frame], CGRectMake(0, 0, 50, 50)), @"Stateful view size should be updated to match new size");
}

- (void)testUpdatingStatefulViewComponentColorUpdatesStatefulViewColor
{
  CKComponentLifecycleTestHelper *componentLifecycleTestController = [[CKComponentLifecycleTestHelper alloc] initWithComponentProvider:componentProvider
                                                                                                                             sizeRangeProvider:nil];
  const CKComponentLifecycleTestHelperState state = [componentLifecycleTestController prepareForUpdateWithModel:[UIColor whiteColor]
                                                                                                    constrainedSize:{{0, 0}, {100, 100}}
                                                                                                            context:nil];
  [componentLifecycleTestController updateWithState:state];
  UIView *view = [UIView new];
  [componentLifecycleTestController attachToView:view];
  auto controller = (CKTestStatefulViewComponentController *)[(CKTestStatefulViewComponent *)state.componentLayout.component controller];

  [componentLifecycleTestController updateWithState:[componentLifecycleTestController prepareForUpdateWithModel:[UIColor redColor]
                                                                                                constrainedSize:{{100, 100}, {100, 100}}
                                                                                                        context:nil]];
  XCTAssertEqualObjects([[controller statefulView] backgroundColor], [UIColor redColor], @"Stateful view size should be updated to match new color");
}

- (void)testInvalidatingStatefulViewComponentEventuallyRelinquishesStatefulView
{
  CKComponentLifecycleTestHelper *componentLifecycleTestController =
    [[CKComponentLifecycleTestHelper alloc] initWithComponentProvider:componentProvider sizeRangeProvider:nil];
  const CKComponentLifecycleTestHelperState state =
    [componentLifecycleTestController prepareForUpdateWithModel:nil
                                                constrainedSize:{{0,0}, {100, 100}}
                                                        context:nil];
  [componentLifecycleTestController attachToView:[UIView new]];
  [componentLifecycleTestController updateWithState:state];

  auto component = (CKTestStatefulViewComponent *)state.componentLayout.component;
  auto controller = (CKTestStatefulViewComponentController *)[component controller];
  XCTAssertNotNil([controller statefulView], @"Expected to have a stateful view while mounted");

  [componentLifecycleTestController detachFromView];
  CKComponentScopeRootAnnounceControllerInvalidation([componentLifecycleTestController state].scopeRoot);
  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL{
    return [controller statefulView] == nil;
  }), @"Expected view to be relinquished");
}

@end
