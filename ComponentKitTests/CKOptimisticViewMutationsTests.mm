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

#import "CKComponent.h"
#import "CKComponentAnimation.h"
#import "CKComponentLifecycleManager.h"
#import "CKComponentSubclass.h"
#import "CKOptimisticViewMutations.h"

@interface CKOptimisticViewMutationsTests : XCTestCase
@end

@implementation CKOptimisticViewMutationsTests

- (void)testOptimisticViewMutationIsTornDown
{
  CKComponent *blueComponent = [CKComponent newWithView:{[UIView class], {
    {@selector(setBackgroundColor:), [UIColor blueColor]},
  }} size:{}];
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

@end
