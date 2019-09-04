/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentCreationValidation.h"

#import <objc/runtime.h>

#if CK_ASSERTIONS_ENABLED
@implementation CKComponentCreationValidationContext

- (instancetype)initWithSource:(CKComponentCreationValidationSource)source
{
  if (self = [super init]) {
    _source = source;
  }
  return self;
}

@end

BOOL CKIsRunningInTest()
{
  static BOOL isTest = NO;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    isTest = objc_lookUpClass("XCTest") != nil;
  });
  return isTest;
}
#endif
