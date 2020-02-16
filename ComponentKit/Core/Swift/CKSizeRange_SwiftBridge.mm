/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKSizeRange_SwiftBridge.h>
#import <ComponentKit/CKSizeRange_SwiftBridge+Internal.h>

#import <ComponentKit/CKCasting.h>

@implementation CKSizeRange_SwiftBridge {
  CKSizeRange _sizeRange;
}

- (instancetype)initWithSizeRange:(const CKSizeRange &)sizeRange
{
  self = [super init];
  _sizeRange = sizeRange;
  return self;
}

- (instancetype)init
{
  return [self initWithSizeRange:{}];
}

- (instancetype)initWithMinSize:(CGSize)minSize maxSize:(CGSize)maxSize
{
  return [self initWithSizeRange:{minSize, maxSize}];
}

- (const CKSizeRange &)sizeRange
{
  return _sizeRange;
}

- (BOOL)isEqual:(id)other
{
  if (other == nil) {
    return NO;
  } else if (other == self) {
    return YES;
  } else {
    // Intentionally treat passing a different type as a programming error
    return _sizeRange == CK::objCForceCast<CKSizeRange_SwiftBridge>(other)->_sizeRange;
  }
}

- (NSUInteger)hash
{
  return _sizeRange.hash();
}

- (NSString *)description
{
  return _sizeRange.description();
}

@end
