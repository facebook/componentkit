/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKBlockSizeRangeProvider.h>

#import <ComponentKit/CKSizeRange_SwiftBridge+Internal.h>

@implementation CKBlockSizeRangeProvider {
  CKComponentSizeRangeProviderBlock _srp;
}

- (instancetype)initWithBlock:(CKComponentSizeRangeProviderBlock)srp
{
  self = [super init];
  _srp = srp;
  return self;
}

- (CKSizeRange)sizeRangeForBoundingSize:(CGSize)size
{
  auto const sr = _srp(size);
  return sr.sizeRange;
}

@end
