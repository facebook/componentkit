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

#import <ComponentKit/CKAssociatedObject.h>

static char kTestObjectKey1 = ' ';
static char kTestObjectKey2 = ' ';

@interface CKAssociatedObjectTests : XCTestCase

@end

@implementation CKAssociatedObjectTests

- (void)test_NilIsReturnedWhenThereIsNoAssociatedObject
{
  const auto obj = [NSObject new];
  XCTAssertNil(CKGetAssociatedObject_MainThreadAffined(obj, &kTestObjectKey1));
}

- (void)test_ValueIsReturnedAfterSettingAssociatedObject
{
  const auto obj1 = [NSObject new];
  const auto obj2 = [NSObject new];
  const auto value1 = [NSObject new];
  const auto value2 = [NSObject new];
  CKSetAssociatedObject_MainThreadAffined(obj1, &kTestObjectKey1, value1);
  CKSetAssociatedObject_MainThreadAffined(obj1, &kTestObjectKey2, value2);
  CKSetAssociatedObject_MainThreadAffined(obj2, &kTestObjectKey1, value1);
  CKSetAssociatedObject_MainThreadAffined(obj2, &kTestObjectKey2, value2);
  XCTAssertEqual(CKGetAssociatedObject_MainThreadAffined(obj1, &kTestObjectKey1), value1);
  XCTAssertEqual(CKGetAssociatedObject_MainThreadAffined(obj1, &kTestObjectKey2), value2);
  XCTAssertEqual(CKGetAssociatedObject_MainThreadAffined(obj2, &kTestObjectKey1), value1);
  XCTAssertEqual(CKGetAssociatedObject_MainThreadAffined(obj2, &kTestObjectKey2), value2);
}

- (void)test_NilIsReturnedWhenValueIsSetToNil
{
  const auto obj = [NSObject new];
  const auto value = [NSObject new];
  CKSetAssociatedObject_MainThreadAffined(obj, &kTestObjectKey1, value);
  CKSetAssociatedObject_MainThreadAffined(obj, &kTestObjectKey1, nil);
  XCTAssertNil(CKGetAssociatedObject_MainThreadAffined(obj, &kTestObjectKey1));
}

- (void)test_ValueIsOverwrittenAfterSettingNewAssociatedObject
{
  const auto obj = [NSObject new];
  const auto value1 = [NSObject new];
  const auto value2 = [NSObject new];
  CKSetAssociatedObject_MainThreadAffined(obj, &kTestObjectKey1, value1);
  XCTAssertEqual(CKGetAssociatedObject_MainThreadAffined(obj, &kTestObjectKey1), value1);
  CKSetAssociatedObject_MainThreadAffined(obj, &kTestObjectKey1, value2);
  XCTAssertEqual(CKGetAssociatedObject_MainThreadAffined(obj, &kTestObjectKey1), value2);
}

- (void)test_ValueIsReleasedAfterObjectIsDeallocated
{
  __weak NSObject *weakValue = nil;
  @autoreleasepool {
    const auto obj = [NSObject new];
    const auto value = [NSObject new];
    weakValue = value;
    CKSetAssociatedObject_MainThreadAffined(obj, &kTestObjectKey1, value);
    XCTAssertEqual(CKGetAssociatedObject_MainThreadAffined(obj, &kTestObjectKey1), value);
    XCTAssertNotNil(weakValue);
  }
  XCTAssertNil(weakValue);
}

@end
