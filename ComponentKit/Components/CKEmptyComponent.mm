/*
*  Copyright (c) 2014-present, Facebook, Inc.
*  All rights reserved.
*
*  This source code is licensed under the BSD-style license found in the
*  LICENSE file in the root directory of this source tree. An additional grant
*  of patent rights can be found in the PATENTS file in the same directory.
*
*/

#import "CKEmptyComponent.h"

@implementation CKEmptyComponent

+ (CKComponent *)sharedInstance
{
  static dispatch_once_t onceToken;
  static CKComponent *instance;
  dispatch_once(&onceToken, ^{
    instance = [[CKEmptyComponent alloc] initWithView:{} size:{}];
  });
  return instance;
}

@end
