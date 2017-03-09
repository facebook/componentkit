/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKTestRunLoopRunning.h"

#import <atomic>

#import <QuartzCore/QuartzCore.h>

// Poll the condition 1000 times a second.
static CFTimeInterval kSingleRunLoopTimeout = 0.001;

// Time out after 30 seconds.
static CFTimeInterval kTimeoutInterval = 30.0f;

BOOL CKRunRunLoopUntilBlockIsTrue(BOOL (^block)(void))
{
  CFTimeInterval timeoutDate = CACurrentMediaTime() + kTimeoutInterval;
  BOOL passed = NO;
  while (true) {
    std::atomic_thread_fence(std::memory_order_seq_cst);
    passed = block();
    std::atomic_thread_fence(std::memory_order_seq_cst);
    if (passed) {
      break;
    }
    CFTimeInterval now = CACurrentMediaTime();
    if (now > timeoutDate) {
      break;
    }
    // Run until the poll timeout or until timeoutDate, whichever is first.
    CFTimeInterval runLoopTimeout = MIN(kSingleRunLoopTimeout, timeoutDate - now);
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, runLoopTimeout, true);
  }
  return passed;
}
