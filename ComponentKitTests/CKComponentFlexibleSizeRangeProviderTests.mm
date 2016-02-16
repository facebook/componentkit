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

#import <ComponentKit/CKComponentFlexibleSizeRangeProvider.h>

@interface CKComponentFlexibleSizeRangeProviderTests : XCTestCase

@end

static CGSize const kBoundingSize = {50, 100};

@implementation CKComponentFlexibleSizeRangeProviderTests

- (void)testNoFlexibility
{
  CKComponentFlexibleSizeRangeProvider *provider = [CKComponentFlexibleSizeRangeProvider providerWithFlexibility:CKComponentSizeRangeFlexibilityNone];
  CKSizeRange range = [provider sizeRangeForBoundingSize:kBoundingSize];

  XCTAssertTrue(CGSizeEqualToSize(range.min, kBoundingSize), @"Expect minimum size to be equal to bounding size with no flexibility.");
  XCTAssertTrue(CGSizeEqualToSize(range.max, kBoundingSize), @"Expect maximum size to be equal to bounding size with no flexibility.");
}

- (void)testFlexibleWidth
{
  CKComponentFlexibleSizeRangeProvider *provider = [CKComponentFlexibleSizeRangeProvider providerWithFlexibility:CKComponentSizeRangeFlexibleWidth];
  CKSizeRange range = [provider sizeRangeForBoundingSize:kBoundingSize];

  XCTAssertTrue(CGSizeEqualToSize(range.min, CGSizeMake(0, kBoundingSize.height)), @"Expect minimum size to be {0, boundingSize.height} with flexible width.");
  XCTAssertTrue(CGSizeEqualToSize(range.max, CGSizeMake(INFINITY, kBoundingSize.height)), @"Expect maximum size to be {INFINITY, boundingSize.height} with flexible width.");
}

- (void)testFlexibleHeight
{
  CKComponentFlexibleSizeRangeProvider *provider = [CKComponentFlexibleSizeRangeProvider providerWithFlexibility:CKComponentSizeRangeFlexibleHeight];
  CKSizeRange range = [provider sizeRangeForBoundingSize:kBoundingSize];

  XCTAssertTrue(CGSizeEqualToSize(range.min, CGSizeMake(kBoundingSize.width, 0)), @"Expect minimum size to be {boundingSize.width, 0} with flexible width.");
  XCTAssertTrue(CGSizeEqualToSize(range.max, CGSizeMake(kBoundingSize.width, INFINITY)), @"Expect maximum size to be {boundingSize.width, INFINITY} with flexible width.");
}

- (void)testFlexibleWidthAndHeight
{
  CKComponentFlexibleSizeRangeProvider *provider = [CKComponentFlexibleSizeRangeProvider providerWithFlexibility:CKComponentSizeRangeFlexibleWidthAndHeight];
  CKSizeRange range = [provider sizeRangeForBoundingSize:kBoundingSize];

  XCTAssertTrue(CGSizeEqualToSize(range.min, CGSizeZero), @"Expect minimum size to be {0, 0} with flexible width and height.");
  XCTAssertTrue(CGSizeEqualToSize(range.max, CGSizeMake(INFINITY, INFINITY)), @"Expect maximum size to be {INFINITY, INFINITY} with flexible width and height.");
}

@end
