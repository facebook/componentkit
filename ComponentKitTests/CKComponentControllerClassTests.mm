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

#import <ComponentKit/CKComponentController.h>
#import <ComponentKit/CKComponentSubclass.h>

@interface CKComponentControllerClassTests : XCTestCase
@end

// We have different component classes to work around the static cache for component controller classes
@interface ComponentWithAnimations: CKComponent
@end

@interface AnotherComponentWithAnimations: CKComponent
@end

@implementation CKComponentControllerClassTests

- (void)test_WhenComponentHasAnimations_UsesBaseControllerClass
{
  XCTAssertEqualObjects([ComponentWithAnimations controllerClass], [CKComponentController class]);
}

- (void)test_WhenComponentHasAnimationsButNotHandledInController_ReturnsNil
{
  const auto controllerCtx = [CKComponentControllerContext newWithHandleAnimationsInController:NO];
  const CKComponentContext<CKComponentControllerContext> ctx {controllerCtx};

  XCTAssertEqualObjects([AnotherComponentWithAnimations controllerClass], Nil);
}

@end

@implementation ComponentWithAnimations
- (std::vector<CKComponentAnimation>)animationsOnInitialMount { return {}; }
@end

@implementation AnotherComponentWithAnimations
- (std::vector<CKComponentAnimation>)animationsFromPreviousComponent:(CKComponent *)previousComponent
{
  return {};
}
@end
