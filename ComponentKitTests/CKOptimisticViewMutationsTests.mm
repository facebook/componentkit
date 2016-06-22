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

#import <ComponentKit/CKButtonComponent.h>
#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKComponentAnimation.h>
#import <ComponentKit/CKComponentLifecycleManager.h>
#import <ComponentKit/CKComponentSubclass.h>
#import <ComponentKit/CKOptimisticViewMutations.h>

@interface CKOptimisticViewMutationsTests : XCTestCase
@end

@implementation CKOptimisticViewMutationsTests

- (void)testOptimisticViewMutationIsTornDown
{
  CKComponent *blueComponent =
  [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{}];
  CKComponentLifecycleManager *clm = [[CKComponentLifecycleManager alloc] init];
  [clm updateWithState:{
    .layout = [blueComponent layoutThatFits:{{0, 0}, {10, 10}} parentSize:kCKComponentParentSizeUndefined]
  }];

  UIView *container = [[UIView alloc] init];
  [clm attachToView:container];

  UIView *view = [blueComponent viewContext].view;
  XCTAssertEqualObjects(view.backgroundColor, [UIColor blueColor], @"Expected blue view");

  CKPerformOptimisticViewMutation(view, @"backgroundColor", [UIColor redColor]);
  XCTAssertEqualObjects(view.backgroundColor, [UIColor redColor], @"Expected optimistic red mutation");

  // detaching and reattaching to the view should reset it back to blue.
  [clm detachFromView];
  [clm attachToView:container];
  XCTAssertEqualObjects(view.backgroundColor, [UIColor blueColor], @"Expected blue to be reset by OptimisticViewMutation");
}

- (void)testTwoSequentialOptimisticViewMutationsAreTornDown
{
  CKComponent *blueComponent =
  [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{}];
  CKComponentLifecycleManager *clm = [[CKComponentLifecycleManager alloc] init];
  [clm updateWithState:{
    .layout = [blueComponent layoutThatFits:{{0, 0}, {10, 10}} parentSize:kCKComponentParentSizeUndefined]
  }];

  UIView *container = [[UIView alloc] init];
  [clm attachToView:container];

  UIView *view = [blueComponent viewContext].view;
  XCTAssertEqualObjects(view.backgroundColor, [UIColor blueColor], @"Expected blue view");

  CKPerformOptimisticViewMutation(view, @"backgroundColor", [UIColor redColor]);
  CKPerformOptimisticViewMutation(view, @"backgroundColor", [UIColor yellowColor]);
  XCTAssertEqualObjects(view.backgroundColor, [UIColor yellowColor], @"Expected view to yellow after second optimistic mutation");

  // detaching and reattaching to the view should reset it back to blue.
  [clm detachFromView];
  [clm attachToView:container];
  XCTAssertEqualObjects(view.backgroundColor, [UIColor blueColor], @"Expected blue to be reset by OptimisticViewMutation");
}

- (void)testFunctionBasedViewMutationsAreAppliedAndTornDownCorrectly
{
  CKButtonComponent *button =
  [CKButtonComponent
   newWithTitles:{{UIControlStateNormal, @"Original"}}
   titleColors:{}
   images:{}
   backgroundImages:{}
   titleFont:nil
   selected:NO
   enabled:YES
   action:NULL
   size:{}
   attributes:{}
   accessibilityConfiguration:{}];
   CKComponentLifecycleManager *clm = [[CKComponentLifecycleManager alloc] init];
  [clm updateWithState:{
    .layout = [button layoutThatFits:{{0, 0}, {10, 10}} parentSize:kCKComponentParentSizeUndefined]
  }];

  UIView *container = [[UIView alloc] init];
  [clm attachToView:container];

  UIButton *view = (UIButton *)[button viewContext].view;
  XCTAssertEqualObjects([view titleForState:UIControlStateNormal], @"Original");

  CKPerformOptimisticViewMutation(view, &buttonTitleGetter, &buttonTitleSetter, @"NewValue");
  XCTAssertEqualObjects([view titleForState:UIControlStateNormal], @"NewValue");

  // detaching and reattaching to the view should reset it back to blue.
  [clm detachFromView];
  [clm attachToView:container];
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
