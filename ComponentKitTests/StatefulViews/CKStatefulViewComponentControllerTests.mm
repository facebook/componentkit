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

#import <ComponentKit/CKComponentLifecycleManager.h>
#import <ComponentKit/CKComponentProvider.h>
#import <ComponentKit/CKComponentSubclass.h>

#import <ComponentKitTestLib/CKComponentTestRootScope.h>

#import "CKTestRunLoopRunning.h"

#import "CKTestStatefulViewComponent.h"

@interface CKStatefulViewComponentControllerTests : XCTestCase <CKComponentProvider>
@end

@implementation CKStatefulViewComponentControllerTests

+ (CKComponent *)componentForModel:(id<NSObject>)model context:(id<NSObject>)context
{
  return [CKTestStatefulViewComponent newWithColor:(UIColor *)model];
}

- (void)testMountingStatefulViewComponentCreatesStatefulView
{
  CKComponentLifecycleManager *m = [[CKComponentLifecycleManager alloc] initWithComponentProvider:[self class]];
  const CKComponentLifecycleManagerState state = [m prepareForUpdateWithModel:[UIColor blueColor] constrainedSize:{{100, 100}, {100, 100}} context:nil];
  [m updateWithState:state];

  UIView *container = [[UIView alloc] init];
  [m attachToView:container];

  auto component = (CKTestStatefulViewComponent *)state.layout.component;
  auto controller = (CKTestStatefulViewComponentController *)[component controller];
  auto statefulView = [controller statefulView];
  XCTAssertTrue([statefulView isKindOfClass:[CKTestStatefulView class]], @"Expected stateful view but couldn't find it");
  XCTAssertTrue(CGRectEqualToRect([statefulView frame], CGRectMake(0, 0, 100, 100)), @"Expected view to be sized to match component");
  XCTAssertEqualObjects([statefulView backgroundColor], [UIColor blueColor], @"Expected view to be configured");
}

- (void)testUnmountingStatefulViewComponentEventuallyRelinquishesStatefulView
{
  CKComponentLifecycleManager *m = [[CKComponentLifecycleManager alloc] initWithComponentProvider:[self class]];
  const CKComponentLifecycleManagerState state = [m prepareForUpdateWithModel:nil constrainedSize:{{100, 100}, {100, 100}} context:nil];
  [m updateWithState:state];

  UIView *container = [[UIView alloc] init];
  [m attachToView:container];

  auto component = (CKTestStatefulViewComponent *)state.layout.component;
  auto controller = (CKTestStatefulViewComponentController *)[component controller];
  XCTAssertNotNil([controller statefulView], @"Expected to have a stateful view while mounted");

  [m detachFromView];
  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL{
    return [controller statefulView] == nil;
  }), @"Expected view to be relinquished");
}

- (void)testMountingStatefulViewComponentOnNewRootViewMovesStatefulView
{
  CKComponentLifecycleManager *m = [[CKComponentLifecycleManager alloc] initWithComponentProvider:[self class]];
  const CKComponentLifecycleManagerState state = [m prepareForUpdateWithModel:nil constrainedSize:{{100, 100}, {100, 100}} context:nil];
  [m updateWithState:state];

  auto controller = (CKTestStatefulViewComponentController *)[(CKTestStatefulViewComponent *)state.layout.component controller];

  UIView *container1 = [[UIView alloc] init];
  [m attachToView:container1];
  XCTAssertTrue([[controller statefulView] isDescendantOfView:container1], @"Expected view to be in container1");

  UIView *container2 = [[UIView alloc] init];
  [m attachToView:container2];
  XCTAssertTrue([[controller statefulView] isDescendantOfView:container2], @"Expected view to be moved to container2");
}

- (void)testUpdatingStatefulViewComponentSizeUpdatesStatefulViewSize
{
  CKComponentLifecycleManager *m = [[CKComponentLifecycleManager alloc] initWithComponentProvider:[self class]];
  const CKComponentLifecycleManagerState state = [m prepareForUpdateWithModel:nil constrainedSize:{{100, 100}, {100, 100}} context:nil];
  [m updateWithState:state];
  UIView *container = [[UIView alloc] init];
  [m attachToView:container];
  auto controller = (CKTestStatefulViewComponentController *)[(CKTestStatefulViewComponent *)state.layout.component controller];

  [m updateWithState:[m prepareForUpdateWithModel:nil constrainedSize:{{50, 50}, {50, 50}} context:nil]];
  XCTAssertTrue(CGRectEqualToRect([[controller statefulView] frame], CGRectMake(0, 0, 50, 50)), @"Stateful view size should be updated to match new size");
}

- (void)testUpdatingStatefulViewComponentColorUpdatesStatefulViewColor
{
  CKComponentLifecycleManager *m = [[CKComponentLifecycleManager alloc] initWithComponentProvider:[self class]];
  const CKComponentLifecycleManagerState state = [m prepareForUpdateWithModel:[UIColor whiteColor] constrainedSize:{{0, 0}, {100, 100}} context:nil];
  [m updateWithState:state];
  UIView *container = [[UIView alloc] init];
  [m attachToView:container];
  auto controller = (CKTestStatefulViewComponentController *)[(CKTestStatefulViewComponent *)state.layout.component controller];

  [m updateWithState:[m prepareForUpdateWithModel:[UIColor redColor] constrainedSize:{{100, 100}, {100, 100}} context:nil]];
  XCTAssertEqualObjects([[controller statefulView] backgroundColor], [UIColor redColor], @"Stateful view size should be updated to match new color");
}

@end
