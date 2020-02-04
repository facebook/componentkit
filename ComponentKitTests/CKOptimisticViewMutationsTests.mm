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

#import <ComponentKit/CKButtonComponent.h>
#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKComponentAnimation.h>
#import <ComponentKit/CKComponentSubclass.h>
#import <ComponentKit/CKOptimisticViewMutations.h>

@interface CKOptimisticViewMutationsTests : XCTestCase
@end

@implementation CKOptimisticViewMutationsTests

- (void)testOptimisticViewMutationIsTornDown
{
  CKComponent *blueComponent =
  CK::ComponentBuilder()
      .viewClass([UIView class])
      .backgroundColor([UIColor blueColor])
      .build();
  CKComponentLifecycleTestHelper *componentLifecycleTestController = [[CKComponentLifecycleTestHelper alloc] initWithComponentProvider:nullptr
                                                                                                                             sizeRangeProvider:nil];
  [componentLifecycleTestController updateWithState:{
    .componentLayout = [blueComponent layoutThatFits:{{0, 0}, {10, 10}} parentSize:kCKComponentParentSizeUndefined]
  }];

  UIView *containerView = [UIView new];
  [componentLifecycleTestController attachToView:containerView];

  UIView *view = [blueComponent viewContext].view;
  XCTAssertEqualObjects(view.backgroundColor, [UIColor blueColor], @"Expected blue view");

  CKPerformOptimisticViewMutation(view, @"backgroundColor", [UIColor redColor]);
  XCTAssertEqualObjects(view.backgroundColor, [UIColor redColor], @"Expected optimistic red mutation");

  // detaching and reattaching to the view should reset it back to blue.
  [componentLifecycleTestController detachFromView];
  [componentLifecycleTestController attachToView:containerView];
  XCTAssertEqualObjects(view.backgroundColor, [UIColor blueColor], @"Expected blue to be reset by OptimisticViewMutation");
}

- (void)testTwoSequentialOptimisticViewMutationsAreTornDown
{
  CKComponent *blueComponent =
  CK::ComponentBuilder()
      .viewClass([UIView class])
      .backgroundColor([UIColor blueColor])
      .build();
  CKComponentLifecycleTestHelper *componentLifecycleTestController = [[CKComponentLifecycleTestHelper alloc] initWithComponentProvider:nullptr
                                                                                                                             sizeRangeProvider:nil];
  [componentLifecycleTestController updateWithState:{
    .componentLayout = [blueComponent layoutThatFits:{{0, 0}, {10, 10}} parentSize:kCKComponentParentSizeUndefined]
  }];

  UIView *containerView = [UIView new];
  [componentLifecycleTestController attachToView:containerView];

  UIView *view = [blueComponent viewContext].view;
  XCTAssertEqualObjects(view.backgroundColor, [UIColor blueColor], @"Expected blue view");

  CKPerformOptimisticViewMutation(view, @"backgroundColor", [UIColor redColor]);
  CKPerformOptimisticViewMutation(view, @"backgroundColor", [UIColor yellowColor]);
  XCTAssertEqualObjects(view.backgroundColor, [UIColor yellowColor], @"Expected view to yellow after second optimistic mutation");

  // detaching and reattaching to the view should reset it back to blue.
  [componentLifecycleTestController detachFromView];
  [componentLifecycleTestController attachToView:containerView];
  XCTAssertEqualObjects(view.backgroundColor, [UIColor blueColor], @"Expected blue to be reset by OptimisticViewMutation");
}

- (void)testFunctionBasedViewMutationsAreAppliedAndTornDownCorrectly
{
  CKButtonComponent *buttonComponent =
  [CKButtonComponent
   newWithAction:nullptr
   options:{
     .titles = @"Original",
   }
  ];
  CKComponentLifecycleTestHelper *componentLifecycleTestController = [[CKComponentLifecycleTestHelper alloc] initWithComponentProvider:nullptr
                                                                                                                             sizeRangeProvider:nil];
  [componentLifecycleTestController updateWithState:{
    .componentLayout = [buttonComponent layoutThatFits:{{0, 0}, {10, 10}} parentSize:kCKComponentParentSizeUndefined]
  }];

  UIView *containerView = [UIView new];
  [componentLifecycleTestController attachToView:containerView];

  UIButton *view = (UIButton *)[buttonComponent viewContext].view;
  XCTAssertEqualObjects([view titleForState:UIControlStateNormal], @"Original");

  CKPerformOptimisticViewMutation(view, &buttonTitleGetter, &buttonTitleSetter, @"NewValue");
  XCTAssertEqualObjects([view titleForState:UIControlStateNormal], @"NewValue");

  // detaching and reattaching to the view should reset it back to blue.
  [componentLifecycleTestController detachFromView];
  [componentLifecycleTestController attachToView:containerView];
  XCTAssertEqualObjects([view titleForState:UIControlStateNormal], @"Original", @"Expected title to be reset by OptimisticViewMutation");
}

static id buttonTitleGetter(UIView *button, id context)
{
  return [(UIButton *)button titleForState:UIControlStateNormal];
}

static void buttonTitleSetter(UIView *button, id value, id context)
{
  [(UIButton *)button setTitle:value forState:UIControlStateNormal];
}

@end
