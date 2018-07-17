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
#import <ComponentKit/CKInternalHelpers.h>
#import <ComponentKit/CKSizeRange.h>

@interface CKSizeRangeTests : XCTestCase

@end

@implementation CKSizeRangeTests

static bool verifySizeRange(CKSizeRange &sz,CGSize &size) {
    return CKIsGreaterThanOrEqualWithTolerance(sz.max.width, size.width)
    && CKIsGreaterThanOrEqualWithTolerance(size.width, sz.min.width)
    && CKIsGreaterThanOrEqualWithTolerance(sz.max.height,size.height)
    && CKIsGreaterThanOrEqualWithTolerance(size.height,sz.min.height);
}

- (void)testExactMatch {
    CKSizeRange sz(CGSizeMake(400, 400), CGSizeMake(400, 400));
    CGSize s = CGSizeMake(400, 400);
    XCTAssert(verifySizeRange(sz, s));
}

- (void)testRangeMatch {
    CKSizeRange sz(CGSizeMake(0, 0), CGSizeMake(INFINITY, INFINITY));
    CGSize s = CGSizeMake(400, 400);
    XCTAssert(verifySizeRange(sz, s));
}

- (void)testNaNMatch {
    CKSizeRange sz(CGSizeMake(NAN, NAN), CGSizeMake(NAN, NAN));
    CGSize s = CGSizeMake(NAN, NAN);
    XCTAssert(verifySizeRange(sz, s));
}

- (void)testVerySmallDifferenceMatch {
    CKSizeRange sz(CGSizeMake(374.99999999999994, 400), CGSizeMake(374.99999999999994, 400));
    CGSize s = CGSizeMake(375, 400);
    XCTAssert(verifySizeRange(sz, s));
}

- (void)testVerySmallDifferenceRangeMatch {
    CKSizeRange sz(CGSizeMake(0, 380), CGSizeMake(INFINITY, 400));
    CGSize s = CGSizeMake(400, 379.99999999999994);
    XCTAssert(verifySizeRange(sz, s));
}

@end
