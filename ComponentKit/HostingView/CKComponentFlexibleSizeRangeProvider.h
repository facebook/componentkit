/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <Foundation/Foundation.h>

#import <ComponentKit/CKComponentSizeRangeProviding.h>

typedef NS_ENUM(NSInteger, CKComponentSizeRangeFlexibility) {
  CKComponentSizeRangeFlexibilityNone = 0,     /** {w, h} -> {{w, h}, {w, h}} */
  CKComponentSizeRangeFlexibleWidth,           /** {w, h} -> {{0, h}, {inf, h}} */
  CKComponentSizeRangeFlexibleHeight,          /** {w, h} -> {{w, 0}, {w, inf}} */
  CKComponentSizeRangeFlexibleWidthAndHeight,  /** {w, h} -> {{0, 0}, {inf, inf}} */
};

/**
 Concrete implementation of `CKComponentSizeRangeProvider` that implements the most
 common sizing behaviours where none, either, or both of the dimensions can be constrained
 to the view's bounding dimensions.
 */
@interface CKComponentFlexibleSizeRangeProvider : NSObject <CKComponentSizeRangeProviding>

/**
 Returns a new instance of the receiver that calculates size ranges based on the
 specified `flexibility` mode.
 */
+ (instancetype)providerWithFlexibility:(CKComponentSizeRangeFlexibility)flexibility;

@end
