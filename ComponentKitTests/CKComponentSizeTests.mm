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

#import <ComponentKit/CKComponent.h>


@interface CKComponentSizeTests : XCTestCase
@end

@implementation CKComponentSizeTests

- (void)testResolvingSizeWithAutoInAllFieldsReturnsUnconstrainedRange
{
  CKComponentSize s;
  CKSizeRange r = s.resolve({500, 300});
  XCTAssertEqual(r.min.width, 0.f, @"Expected no min width");
  XCTAssertEqual(r.max.width, INFINITY, @"Expected no max width");
  XCTAssertEqual(r.min.height, 0.f, @"Expected no min height");
  XCTAssertEqual(r.max.height, INFINITY, @"Expected no max height");
}

- (void)testPercentageWidthIsResolvedAgainstParentDimension
{
  CKComponentSize s = {.width = CKRelativeDimension::Percent(1.0)};
  CKSizeRange r = s.resolve({500, 300});
  XCTAssertEqual(r.min.width, 500.0f, @"Expected min of resolved range to match");
  XCTAssertEqual(r.max.width, 500.0f, @"Expected max of resolved range to match");
}

- (void)testMaxSizeClampsComponentSize
{
  CKComponentSize s = {.width = CKRelativeDimension::Percent(1.0), .maxWidth = 300};
  CKSizeRange r = s.resolve({500, 300});
  XCTAssertEqual(r.min.width, 300.0f, @"Expected max-size to clamp the width to exactly 300 pts");
  XCTAssertEqual(r.max.width, 300.0f, @"Expected max-size to clamp the width to exactly 300 pts");
}

- (void)testMinSizeOverridesMaxSizeWhenTheyConflict
{
  // Min-size overriding max-size matches CSS.
  CKComponentSize s = {.minWidth = CKRelativeDimension::Percent(0.5), .maxWidth = 300};
  CKSizeRange r = s.resolve({800, 300});
  XCTAssertEqual(r.min.width, 400.0f, @"Expected min-size to override max-size");
  XCTAssertEqual(r.max.width, 400.0f, @"Expected min-size to override max-size");
}

- (void)testMinSizeAloneResultsInRangeUnconstrainedToInfinity
{
  CKComponentSize s = {.minWidth = 100};
  CKSizeRange r = s.resolve({800, 300});
  XCTAssertEqual(r.min.width, 100.0f, @"Expected min width to be passed through");
  XCTAssertEqual(r.max.width, INFINITY, @"Expected max width to be infinity since no maxWidth was specified");
}

- (void)testMaxSizeAloneResultsInRangeUnconstrainedFromZero
{
  CKComponentSize s = {.maxWidth = 100};
  CKSizeRange r = s.resolve({800, 300});
  XCTAssertEqual(r.min.width, 0.0f, @"Expected min width to be zero");
  XCTAssertEqual(r.max.width, 100.0f, @"Expected max width to be passed through");
}

- (void)testMinSizeAndMaxSizeResolveToARangeWhenTheyAreNotInConflict
{
  CKComponentSize s = {.minWidth = 100, .maxWidth = 300};
  CKSizeRange r = s.resolve({800, 300});
  XCTAssertEqual(r.min.width, 100.0f, @"Expected min-size to be passed to size range");
  XCTAssertEqual(r.max.width, 300.0f, @"Expected max-size to be passed to size range");
}

- (void)testWhenWidthFallsBetweenMinAndMaxWidthsItReturnsARangeWithExactlyThatWidth
{
  CKComponentSize s = {.minWidth = 100, .width = 200, .maxWidth = 300};
  CKSizeRange r = s.resolve({800, 300});
  XCTAssertEqual(r.min.width, 200.0f, @"Expected min-size to be width");
  XCTAssertEqual(r.max.width, 200.0f, @"Expected max-size to be width");
}

- (void)testWhenResolvedExactSizeIsNanOrInfinity
{
  CKComponentSize s = {
    .minWidth = 100, .minHeight = 100,
    .maxWidth = 300, .maxHeight = 300,
    .width = INFINITY, .height = INFINITY
  };
  
  CKSizeRange r = s.resolve({800, 300});
  XCTAssertEqual(r.min.width, 100.0f, @"Expected min width to be passed through");
  XCTAssertEqual(r.min.height, 100.0f, @"Expected min height to be passed through");
  XCTAssertEqual(r.max.width, 300.0f, @"Expected max width to be passed through");
  XCTAssertEqual(r.max.height, 300.0f, @"Expected max height to be passed through");
}

@end
