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

#import <limits>

#import <ComponentKit/CKDimension.h>


@interface CKDimensionTests : XCTestCase
@end

@implementation CKDimensionTests

- (void)testIntersectingOverlappingSizeRangesReturnsTheirIntersection
{
  //  range: |---------|
  //  other:      |----------|
  // result:      |----|

  CKSizeRange range = {{0,0}, {10,10}};
  CKSizeRange other = {{7,7}, {15,15}};
  CKSizeRange result = range.intersect(other);
  CKSizeRange expected = {{7,7}, {10,10}};
  XCTAssertTrue(result == expected, @"Expected %@ but got %@", expected.description(), result.description());
}

- (void)testIntersectingSizeRangeWithRangeThatContainsItReturnsSameRange
{
  //  range:    |-----|
  //  other:  |---------|
  // result:    |-----|

  CKSizeRange range = {{2,2}, {8,8}};
  CKSizeRange other = {{0,0}, {10,10}};
  CKSizeRange result = range.intersect(other);
  CKSizeRange expected = {{2,2}, {8,8}};
  XCTAssertTrue(result == expected, @"Expected %@ but got %@", expected.description(), result.description());
}

- (void)testIntersectingSizeRangeWithRangeContainedWithinItReturnsContainedRange
{
  //  range:  |---------|
  //  other:    |-----|
  // result:    |-----|

  CKSizeRange range = {{0,0}, {10,10}};
  CKSizeRange other = {{2,2}, {8,8}};
  CKSizeRange result = range.intersect(other);
  CKSizeRange expected = {{2,2}, {8,8}};
  XCTAssertTrue(result == expected, @"Expected %@ but got %@", expected.description(), result.description());
}

- (void)testIntersectingSizeRangeWithNonOverlappingRangeToRightReturnsSinglePointNearestOtherRange
{
  //  range: |-----|
  //  other:          |---|
  // result:       *

  CKSizeRange range = {{0,0}, {5,5}};
  CKSizeRange other = {{10,10}, {15,15}};
  CKSizeRange result = range.intersect(other);
  CKSizeRange expected = {{5,5}, {5,5}};
  XCTAssertTrue(result == expected, @"Expected %@ but got %@", expected.description(), result.description());
}

- (void)testIntersectingSizeRangeWithNonOverlappingRangeToLeftReturnsSinglePointNearestOtherRange
{
  //  range:          |---|
  //  other: |-----|
  // result:          *

  CKSizeRange range = {{10,10}, {15,15}};
  CKSizeRange other = {{0,0}, {5,5}};
  CKSizeRange result = range.intersect(other);
  CKSizeRange expected = {{10,10}, {10,10}};
  XCTAssertTrue(result == expected, @"Expected %@ but got %@", expected.description(), result.description());
}

@end

@interface CKRelativeDimensionTests: XCTestCase
@end

@implementation CKRelativeDimensionTests

- (void)test_ResolvingPercentageAgainstInfinity_ReturnsAutoSize
{
  const auto percentDimension = CKRelativeDimension::Percent(1);
  const auto autoSize = 42;

  XCTAssertEqual(percentDimension.resolve(autoSize, std::numeric_limits<CGFloat>::infinity()), autoSize);
}

@end
