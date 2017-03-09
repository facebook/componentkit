/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentFlexibleSizeRangeProvider.h"

#import <ComponentKit/CKAssert.h>
#import <ComponentKit/CKMacros.h>

@implementation CKComponentFlexibleSizeRangeProvider {
  CKComponentSizeRangeFlexibility _flexibility;
}

+ (instancetype)providerWithFlexibility:(CKComponentSizeRangeFlexibility)flexibility
{
  return [[self alloc] initWithFlexibility:flexibility];
}

- (instancetype)init
{
  CK_NOT_DESIGNATED_INITIALIZER();
}

- (instancetype)initWithFlexibility:(CKComponentSizeRangeFlexibility)flexibility
{
  if (self = [super init]) {
    _flexibility = flexibility;
  }
  return self;
}

- (CKSizeRange)sizeRangeForBoundingSize:(CGSize)size
{
  switch (_flexibility) {
    case CKComponentSizeRangeFlexibleWidth:
      return CKSizeRange(CGSizeMake(0, size.height), CGSizeMake(INFINITY, size.height));
    case CKComponentSizeRangeFlexibleHeight:
      return CKSizeRange(CGSizeMake(size.width, 0), CGSizeMake(size.width, INFINITY));
    case CKComponentSizeRangeFlexibleWidthAndHeight:
      return CKSizeRange(); // Default constructor creates unconstrained range
    case CKComponentSizeRangeFlexibilityNone:
    default:
      return CKSizeRange(size, size);
  }
}

@end
