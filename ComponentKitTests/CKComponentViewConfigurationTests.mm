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
#import <ComponentKit/CKComponentViewConfiguration.h>

@interface CKComponentViewConfigurationTests : XCTestCase
@end

@implementation CKComponentViewConfigurationTests

- (void)test_WhenAllowsImplicitAnimationsFlagIsDifferent_AreNotEqual
{
  auto const vc1 = CKComponentViewConfiguration {
    [UIView class],
    {{@selector(setBackgroundColor:), UIColor.blackColor}},
    {}
  };
  auto const vc2 = CKComponentViewConfiguration {
    [UIView class],
    {{@selector(setBackgroundColor:), UIColor.blackColor}},
    {},
    true /* blockImplicitAnimations */
  };

  XCTAssertFalse(vc1 == vc2);
}

@end
