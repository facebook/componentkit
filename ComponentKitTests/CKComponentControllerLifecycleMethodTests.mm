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

#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKComponentController.h>
#import <ComponentKit/CKComponentProvider.h>
#import <ComponentKit/CKComponentScope.h>
#import <ComponentKit/CKComponentSubclass.h>

@interface CKComponentControllerLifecycleMethodTests : XCTestCase
@end

@implementation CKComponentControllerLifecycleMethodTests

static CKComponent *componentProvider(id<NSObject> model, id<NSObject>context)
{
  return [CKLifecycleTestComponent new];
}

- (void)testThatMountingComponentCallsWillAndDidMount
{
  CKComponentLifecycleTestHelper *componentLifecycleTestController = [[CKComponentLifecycleTestHelper alloc] initWithComponentProvider:componentProvider
                                                                                                                             sizeRangeProvider:nil];

  const CKComponentLifecycleTestHelperState state = [componentLifecycleTestController prepareForUpdateWithModel:nil
                                                                                                    constrainedSize:{{0,0}, {100, 100}}
                                                                                                            context:nil];
  [componentLifecycleTestController updateWithState:state];

  UIView *view = [UIView new];
  [componentLifecycleTestController attachToView:view];
  CKLifecycleTestComponentController *controller = ((CKLifecycleTestComponent *)state.componentLayout.component).controller;
  const CKLifecycleMethodCounts actual = controller.counts;
  const CKLifecycleMethodCounts expected = {.willMount = 1, .didMount = 1, .didAcquireView = 1};
  XCTAssertTrue(actual == expected, @"Expected %@ but got %@", expected.description(), actual.description());
}

- (void)testThatUnmountingComponentCallsWillAndDidUnmount
{
  CKComponentLifecycleTestHelper *componentLifecycleTestController = [[CKComponentLifecycleTestHelper alloc] initWithComponentProvider:componentProvider
                                                                                                                             sizeRangeProvider:nil];

  const CKComponentLifecycleTestHelperState state = [componentLifecycleTestController prepareForUpdateWithModel:nil
                                                                                                    constrainedSize:{{0,0}, {100, 100}}
                                                                                                            context:nil];
  [componentLifecycleTestController updateWithState:state];

  UIView *view = [UIView new];
  [componentLifecycleTestController attachToView:view];
  [componentLifecycleTestController detachFromView];

  CKLifecycleTestComponentController *controller = ((CKLifecycleTestComponent *)state.componentLayout.component).controller;
  const CKLifecycleMethodCounts actual = controller.counts;
  const CKLifecycleMethodCounts expected = {.willMount = 1, .didMount = 1, .willUnmount = 1, .didUnmount = 1, .willRelinquishView = 1, .didAcquireView = 1};
  XCTAssertTrue(actual == expected, @"Expected %@ but got %@", expected.description(), actual.description());
}

- (void)testThatUpdatingComponentWhileMountedCallsWillAndDidRemount
{
  CKComponentLifecycleTestHelper *componentLifecycleTestController = [[CKComponentLifecycleTestHelper alloc] initWithComponentProvider:componentProvider
                                                                                                                             sizeRangeProvider:nil];

  const CKComponentLifecycleTestHelperState state = [componentLifecycleTestController prepareForUpdateWithModel:nil
                                                                                                    constrainedSize:{{0,0}, {100, 100}}
                                                                                                            context:nil];
  [componentLifecycleTestController updateWithState:state];

  UIView *view = [UIView new];
  [componentLifecycleTestController attachToView:view];
  CKLifecycleTestComponent *component = (CKLifecycleTestComponent *)state.componentLayout.component;
  [component updateStateToIncludeNewAttribute];

  CKLifecycleTestComponentController *controller = (CKLifecycleTestComponentController *)component.controller;
  const CKLifecycleMethodCounts actual = controller.counts;
  const CKLifecycleMethodCounts expected = {.willMount = 1, .didMount = 1, .willRemount = 1, .didRemount = 1, .willRelinquishView = 1, .didAcquireView = 2};
  XCTAssertTrue(actual == expected, @"Expected %@ but got %@", expected.description(), actual.description());
}

- (void)testThatUpdatingComponentWhileNotMountedCallsNothing
{
  CKComponentLifecycleTestHelper *componentLifecycleTestController = [[CKComponentLifecycleTestHelper alloc] initWithComponentProvider:componentProvider
                                                                                                                             sizeRangeProvider:nil];

  const CKComponentLifecycleTestHelperState state = [componentLifecycleTestController prepareForUpdateWithModel:nil
                                                                                                    constrainedSize:{{0,0}, {100, 100}}
                                                                                                            context:nil];
  [componentLifecycleTestController updateWithState:state];

  UIView *view = [UIView new];
  [componentLifecycleTestController attachToView:view];
  [componentLifecycleTestController detachFromView];

  CKLifecycleTestComponent *component = (CKLifecycleTestComponent *)state.componentLayout.component;
  CKLifecycleTestComponentController *controller = (CKLifecycleTestComponentController *)component.controller;
  {
    const CKLifecycleMethodCounts actual = controller.counts;
    const CKLifecycleMethodCounts expected = {.willMount = 1, .didMount = 1, .willUnmount = 1, .didUnmount = 1, .willRelinquishView = 1, .didAcquireView = 1};
    XCTAssertTrue(actual == expected, @"Expected %@ but got %@", expected.description(), actual.description());
  }

  controller.counts = {};
  [component updateStateToIncludeNewAttribute];
  {
    const CKLifecycleMethodCounts actual = controller.counts;
    const CKLifecycleMethodCounts expected = {};
    XCTAssertTrue(actual == expected, @"Expected %@ but got %@", expected.description(), actual.description());
  }

  [componentLifecycleTestController attachToView:view];
  {
    const CKLifecycleMethodCounts actual = controller.counts;
    const CKLifecycleMethodCounts expected = {.willMount = 1, .didMount = 1, .didAcquireView = 1};
    XCTAssertTrue(actual == expected, @"Expected %@ but got %@", expected.description(), actual.description());
  }
}

@end
