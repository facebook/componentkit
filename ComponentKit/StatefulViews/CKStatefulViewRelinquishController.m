/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKStatefulViewRelinquishController.h"

#import "CKAssert.h"

@implementation CKStatefulViewRelinquishController
{
  BOOL _defaultDelayedRelinquishEnabled;
  BOOL _delayRelinquish;
}

+ (CKStatefulViewRelinquishController *)sharedInstance
{
  static CKStatefulViewRelinquishController *sharedInstance;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [self new];
  });
  return sharedInstance;
}

- (instancetype)init
{
  if (self = [super init]) {
    _defaultDelayedRelinquishEnabled = YES;
  }
  return self;
}

- (void)setDelayedRelinquishDefault:(BOOL)delayedRelinquishEnabled
{
  CKAssertMainThread();
  _defaultDelayedRelinquishEnabled = delayedRelinquishEnabled;
}

- (void)delayRelinquishForRunloopTurn
{
  CKAssertMainThread();
  if (_delayRelinquish) {
    return;
  }
  _delayRelinquish = YES;
  dispatch_async(dispatch_get_main_queue(), ^{
    _delayRelinquish = NO;
  });
}

- (BOOL)delayedRelinquishEnabled
{
  CKAssertMainThread();
  return _delayRelinquish ?: _defaultDelayedRelinquishEnabled;
}

@end
