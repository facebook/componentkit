/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#ifndef CKAnimationSpy_h
#define CKAnimationSpy_h

struct CKAnimationSpy {
  auto makeAnimation() {
    return CKComponentAnimation({
      .willRemount = ^{
        willRemountWasCalled = true;
        return willRemountCtx;
      },
      .didRemount = ^(id context){
        actualWillRemountCtx = context;
        return didRemountCtx;
      },
      .cleanup = ^(id context){
        cleanupCallCount++;
        actualDidRemountCtx = context;
      },
    });
  }

  const id willRemountCtx = [NSObject new];
  id actualWillRemountCtx = nil;
  bool willRemountWasCalled = false;
  const id didRemountCtx = [NSObject new];
  id actualDidRemountCtx = nil;
  int cleanupCallCount = 0;
};

#endif /* CKAnimationSpy_h */
