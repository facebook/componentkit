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

#include <iostream>
#include <string>

#import <ComponentKit/CKVariant.h>

using namespace CK;

@interface CKVariantTests : XCTestCase
@end

@implementation CKVariantTests

static int numDestructorCalls = 0;

struct DestructionTracker {
  ~DestructionTracker() {
    ++numDestructorCalls;
  }
};

- (void)setUp
{
  [super setUp];
  numDestructorCalls = 0;
}

- (void)test_DestructionOfCustomType
{
  auto dt = DestructionTracker{};
  {
    __unused auto const v = Variant<int, DestructionTracker>{dt};
  }

  XCTAssertEqual(numDestructorCalls, 1);
}

- (void)test_QueryingType
{
  Variant<int, double> v{42};
  XCTAssert(v.is<int>());
  XCTAssertFalse(v.is<double>());
}

- (void)test_GenericVisiting
{
  auto const v = Variant<int, double>{36.5};

  v.match([](auto &x) {
    std::cout << x << '\n';
  });
}

- (void)test_OverloadedVisiting
{
  auto const s = std::string{"Hello"};
  auto const v = Variant<int, std::string>{s};
  v.match([self](int x) { XCTFail(); },
          [self](const std::string &str) { XCTAssert(str == "Hello"); });
}

- (void)test_VisitingWithDefault
{
  auto const v = Variant<int, double, std::string>{42};
  v.match([self](int x) { XCTAssertEqual(x, 42); },
          [self](const auto &) { XCTFail(); });
}

- (void)test_VisitingWithResult
{
  auto const s = std::string{"Hello"};
  auto const v = Variant<int, std::string>{s};

  auto const r = v.match([](const std::string &str) { return str; },
                         [](const auto &) { return std::string{}; });

  XCTAssert(r == "Hello");
}

- (void)test_MutatingAssociatedValues
{
  auto v = Variant<int, std::string>{42};

  v.match([](int &x) { x = 43; },
          [](auto &) {});

  v.match([&](int x) { XCTAssertEqual(x, 43); },
          [&](const auto &) { XCTFail(); });
}

- (void)test_EqualityToValue
{
  auto const s = std::string{"Hello"};
  auto const v = Variant<int, std::string>{s};

  XCTAssertFalse(v == 42);
  XCTAssertFalse(v == std::string{"World"});
  XCTAssert(v == s);
}

- (void)test_Equality
{
  auto const v1 = Variant<int, std::string>{std::string{"Hello"}};
  auto const v2 = Variant<int, std::string>{42};

  XCTAssertFalse(v1 == v2);

  auto const v3 = Variant<int, std::string>{std::string{"Hello"}};
  auto const v4 = Variant<int, std::string>{std::string{"World"}};

  XCTAssert(v1 == v3);
  XCTAssertFalse(v3 == v4);
}

struct Empty {};
struct Loading {};
struct Data {
  std::string message;
};
struct ObjcObject {
  NSObject *s;
};

- (void)test_MatchingCustomTypes
{
  auto const msg = std::string{"Hello"};
  auto const state = Variant<Empty, Loading, Data>{Data{msg}};

  state.match([](Empty) {},
              [](Loading) {},
              [](const Data &d) { std::cout << d.message << '\n'; });
}

static NSInteger getRetainCount(__unsafe_unretained id object) {
  if (object == nil) {
    return 0;
  } else {
    return CFGetRetainCount((__bridge CFTypeRef)object);
  }
}

- (void)test_CopyMoveCtorOperatorEqual
{
  auto object = [NSObject new];

  // referenced in object
  XCTAssertEqual(getRetainCount(object), 1);

  {
    Variant<Empty, ObjcObject> b;

    {
      Variant<Empty, ObjcObject> a = ObjcObject{object};
      // referenced in object & a
      XCTAssertEqual(getRetainCount(object), 2);

      b = a;

      // referenced in object, a & b
      XCTAssertEqual(getRetainCount(object), 3);
    }

    // a gets deleted, referenced in object & b
    XCTAssertEqual(getRetainCount(object), 2);
  }

  // b gets deleted, referenced in object
  XCTAssertEqual(getRetainCount(object), 1);
}

static void parseInt(int& c) {
  c = 43;
}

- (void)test_FunctionPointer
{
  Variant<int, char> v = 42;

  v.match(&parseInt, [self](const char& c){
    XCTFail(@"Char is not the value we hold");
  });

  // If the handler was called the value should have changed
  XCTAssertEqual(v, 43);
}

@end
