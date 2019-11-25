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

#include <string>
#include <unordered_map>

#import <ComponentKit/CKDictionary.h>

@interface CKDictionaryTests : XCTestCase
@end

struct NonCopyable {
  int x;

  NonCopyable(const NonCopyable &) = delete;
  NonCopyable(NonCopyable &&) = default;
};

@implementation CKDictionaryTests

- (void)test_Empty
{
  auto const d = CK::Dictionary<int, int>{};

  XCTAssert(d.empty());
}

- (void)test_InitialisationAndEnumeration
{
  auto const d = CK::Dictionary<std::string, int>{
    {"A", 0},
    {"B", 1},
//    {"A", 2}
  };

  XCTAssertEqual(d.size(), 2);
  auto expected = std::unordered_map<std::string, int>{
    {"A", 0},
    {"B", 1}
  };
  for (auto const &kv : d) {
    XCTAssertEqual(expected[kv.first], kv.second);
  }
}

- (void)test_RetrievalOfExistingElement
{
  auto d = CK::Dictionary<std::string, int>{
    {"A", 0},
    {"B", 1}
  };

  XCTAssertEqual(d["A"], 0);
}

- (void)test_MutationOfExistingElement
{
  auto d = CK::Dictionary<std::string, int>{
    {"A", 0},
    {"B", 1}
  };

  d["B"] = 2;

  XCTAssertEqual(d["B"], 2);
}

- (void)test_MutationOfNewElement
{
  auto d = CK::Dictionary<std::string, int>{
    {"A", 0}
  };

  d["B"] = 2;

  XCTAssertEqual(d["B"], 2);
}

- (void)test_MutationOfNonCopyable
{
  auto d = CK::Dictionary<std::string, NonCopyable>{};

  d["A"].x = 42;

  XCTAssertEqual(d["A"].x, 42);
}

@end
