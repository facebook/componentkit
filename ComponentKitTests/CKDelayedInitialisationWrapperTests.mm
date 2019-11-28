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

#import <string>

#import <ComponentKit/CKDelayedInitialisationWrapper.h>

using namespace CK;

@interface CKDelayedInitialisationWrapperTests : XCTestCase
@end

@implementation CKDelayedInitialisationWrapperTests

- (void)testGettingValue
{
  CK::DelayedInitialisationWrapper<int> age;
  age = 3;
  XCTAssertEqual(age.get(), 3);
}

- (void)testGettingMutableValue
{
  CK::DelayedInitialisationWrapper<std::string> name;
  name = std::string("hell");
  auto &mutableName = name.get();
  mutableName.push_back('o');
  XCTAssertEqual(name.get(), "hello");
}

@end
