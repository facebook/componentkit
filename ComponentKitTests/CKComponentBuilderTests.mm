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
#import <ComponentKit/ComponentBuilder.h>

using namespace CK;

@interface CKComponentBuilderTests : XCTestCase
@end

@implementation CKComponentBuilderTests

- (void)testSettingTransitions
{
  // This should not crash for the test to pass
  __unused auto b =
  ComponentBuilder(ComponentSpecContext{})
  .animationInitial(Animation::alphaFrom(0))
  .animationFinal(Animation::alphaTo(0))
  .key(@"Key");
}

@end
