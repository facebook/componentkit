/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKWatchdogTimer.h"

#import <UIKit/UIKit.h>
#include <mach/mach_time.h>

#import "CKMutex.h"

/** Protects timeoutNanoseconds and handler */
static CK::StaticMutex mutex = CK_MUTEX_INITIALIZER;
static uint64_t timeoutNanoseconds = 0;
static void (*handler)(void) = nullptr;

static dispatch_source_t newTimer()
{
  uint64_t localTimeoutNanoseconds;
  {
    CK::StaticMutexLocker l(mutex);
    localTimeoutNanoseconds = timeoutNanoseconds;
  }
  if (localTimeoutNanoseconds == 0) {
    return nil; // Avoid cost of creating the timer altogether.
  }

  // Main thread only; as measured by mach_absolute_time
  static uint64_t lastBackgroundingTimestamp = 0;
  static id backgroundObserver;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    lastBackgroundingTimestamp = mach_absolute_time();
    backgroundObserver =
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                    lastBackgroundingTimestamp = mach_absolute_time();
                                                  }];
  });

  const uint64_t timerCreationTimestamp = mach_absolute_time();
  dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
  dispatch_source_set_event_handler(timer, ^{
    CKCAssertMainThread();
    // Don't fire the handler if the app backgrounded after scheduling the timer since that suspends app's CPU
    if (lastBackgroundingTimestamp < timerCreationTimestamp) {
      void (*localHandler)(void);
      {
        CK::StaticMutexLocker l(mutex);
        localHandler = handler;
      }
      if (localHandler) {
        localHandler();
      }
    }
    // Prevent further invocations of the timer.
    dispatch_source_cancel(timer);
  });
  dispatch_source_set_timer(timer,
                            // Fire after the timeout has expired.
                            dispatch_time(DISPATCH_TIME_NOW, localTimeoutNanoseconds),
                            // Repeat at some high interval; in practice it's canceled when it fires the first time.
                            NSEC_PER_SEC * 1000,
                            // High leeway for efficiency as we don't need to be exact.
                            NSEC_PER_SEC);
  dispatch_resume(timer);
  return timer;
}

CKWatchdogTimer::CKWatchdogTimer()
: _timer(newTimer()) {}

CKWatchdogTimer::~CKWatchdogTimer()
{
  if (_timer) {
    dispatch_source_cancel(_timer);
  }
}

void CKWatchdogTimer::configure(const int64_t newTimeoutNanoseconds, void (*newHandler)(void))
{
  CK::StaticMutexLocker l(mutex);
  timeoutNanoseconds = newTimeoutNanoseconds;
  handler = newHandler;
}
