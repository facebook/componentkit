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

#import <ComponentKit/CKOptional.h>

using namespace CK;

@interface CKOptionalTests : XCTestCase
@end

@implementation CKOptionalTests

- (void)test_EqualityWithNone
{
  Optional<int> const a = none;

  XCTAssert(a == none);
  XCTAssert(none == a);
  XCTAssert(none == none);
  XCTAssert(Optional<int>{} == none);
  XCTAssert(none == Optional<int>{});

  auto const b = Optional<int>{2};
  XCTAssert(b != none);
  XCTAssert(none != b);
}

- (void)test_Equality
{
  auto const a = Optional<int>{2};
  auto const b = Optional<int>{3};
  auto const c = Optional<int>{};
  auto const d = Optional<int>{2};
  auto const e = Optional<int>{};

  XCTAssert(a == d);
  XCTAssert(c == e);
  XCTAssert(a != b);
  XCTAssert(a != c);
}

- (void)test_EqualityWithValues
{
  auto const a = Optional<int>{2};

  XCTAssert(a == 2);
  XCTAssert(2 == a);
  XCTAssert(a != 3);
  XCTAssert(3 != a);
}

static auto toInt(const std::string& s) -> Optional<int> {
  if (s.empty()) {
    return none;
  }
  return std::stoi(s);
}

- (void)test_FlatMap
{
  auto const a = Optional<std::string>{"123"};
  auto const b = Optional<std::string>{""};
  auto const c = Optional<std::string>{};

  XCTAssert(a.flatMap(toInt) == 123);
  XCTAssert(b.flatMap(toInt) == none);
  XCTAssert(c.flatMap(toInt) == none);
}

struct HasOptional {
  Optional<int> x;
};

- (void)test_FlatMap_PointerToMember
{
  Optional<HasOptional> const a = HasOptional { 123 };
  Optional<HasOptional> const b = HasOptional { none };

  XCTAssert(a.flatMap(&HasOptional::x) == 123);
  XCTAssert(b.flatMap(&HasOptional::x) == none);
}

- (void)test_WhenEmpty_ValuePtrIsNull
{
  auto const empty = Optional<int>{};

  if (auto const x = empty.unsafeValuePtrOrNull()) {
    XCTFail();
  }
}

- (void)test_WhenHasValue_ValuePtrPointsToValue
{
  auto const a = Optional<int>{2};

  if (auto i = a.unsafeValuePtrOrNull()) {
    XCTAssert(*i == 2);
  } else {
    XCTFail();
  }
}

@end
