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

/** Fires a global handler function if the object stays alive for longer than a global timeout value. */
class CKWatchdogTimer {
public:
  CKWatchdogTimer();
  ~CKWatchdogTimer();

  /** Configures the duration to wait and the action to take upon firing. Default is to do nothing. */
  static void configure(const int64_t timeoutNanoseconds, void (*handler)(void));
private:
  CKWatchdogTimer(const CKWatchdogTimer&) = delete;
  CKWatchdogTimer &operator=(const CKWatchdogTimer&) = delete;
  dispatch_source_t _timer;
};
