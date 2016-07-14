/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <stdlib.h>
#import <vector>

#import <XCTest/XCTest.h>
#import "ComponentUtilities.h"

@interface CKVectorChainingTests : XCTestCase
@end

@implementation CKVectorChainingTests

- (void)test_emptyVectors
{
  std::vector<int> a;
  std::vector<int> b;
  std::vector<int> emptyVector;
  XCTAssertTrue(CK::chain(a,b) == emptyVector);
}

- (void)test_firstVectorEmpty
{
  std::vector<int> a;
  std::vector<int> b = {1,2,3};
  XCTAssertTrue(CK::chain(a,b) == b);
}

- (void)test_secondVectorEmpty
{
  std::vector<int> a = {1,2,3};
  std::vector<int> b;
  XCTAssertTrue(CK::chain(a,b) == a);
}

- (void)test_chainingTwoVectors
{
  std::vector<int> a = {1,2,3};
  std::vector<int> b = {4,5,6};
  std::vector<int> c = {1,2,3,4,5,6};
  XCTAssertTrue(CK::chain(a,b) == c);
}

- (void)test_chainingVectorWithItself
{
  std::vector<int> a = {1,2,3};
  std::vector<int> aa = {1,2,3,1,2,3};
  XCTAssertTrue(CK::chain(a,a) == aa);
}

- (void)test_chainingVectorsOfDifferentLengths
{
  std::vector<int> a = {1,2,3};
  std::vector<int> b = {4,5,6,7,8};
  std::vector<int> c = {1,2,3,4,5,6,7,8};
  XCTAssertTrue(CK::chain(a,b) == c);
}

- (void)test_chainingCallsToChain
{
  std::vector<int> a = {1,2,3};
  std::vector<int> b = {4,5,6};
  std::vector<int> c = {7,8,9};
  std::vector<int> d = {1,2,3,4,5,6,7,8,9};
  XCTAssertTrue(CK::chain(CK::chain(a, b), c) == d);
}

@end

@interface CKVectorInterspersingTests : XCTestCase
@end

@implementation CKVectorInterspersingTests

- (void)test_emptyVector
{
  std::vector<int> a = {};
  std::vector<int> expected = {};
  XCTAssertTrue(CK::intersperse(a, ^int{ return 0; }, [](const int t){return true;}) == expected);
}

- (void)test_intersperseSingleItem_allowItem
{
  std::vector<int> a = {1};
  std::vector<int> expected = {1};
  XCTAssertTrue(CK::intersperse(a, ^int{ return 4; }, [](const int t){return true;}) == expected);
}

- (void)test_interspersSingleItem_denyItem
{
  std::vector<int> a = {1};
  std::vector<int> expected = {};
  XCTAssertTrue(CK::intersperse(a, ^int{ return 4; }, [](const int t){return false;}) == expected);
}

- (void)test_intersperseMultipleItems_allowAll
{
  std::vector<int> a = {1,2,3};
  std::vector<int> expected = {1,4,2,4,3};
  XCTAssertTrue(CK::intersperse(a, ^int{ return 4; }, [](const int t){return true;}) == expected);
}

- (void)test_intersperseMultipleItems_denyAll
{
  std::vector<int> a = {1,2,3};
  std::vector<int> expected = {};
  XCTAssertTrue(CK::intersperse(a, ^int{ return 4; }, [](const int t){return false;}) == expected);
}

- (void)test_intersperseMultipleItems_allowSome
{
  std::vector<int> a = {1,2,3,4,5,6};
  std::vector<int> expected = {2,4,4,4,6};
  XCTAssertTrue(CK::intersperse(a, ^int{ return 4; }, [](const int t){return t % 2 == 0;}) == expected);
}

- (void)test_intersperseTwice
{
  std::vector<int> a = {1,2,3};
  std::vector<int> b = CK::intersperse(a, ^int{ return 4; }, [](const int t){return true;});
  std::vector<int> expected = {1,5,4,5,2,5,4,5,3};
  XCTAssertTrue(CK::intersperse(b, ^int{ return 5; }, [](const int t){return true;}) == expected);
}

@end
