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

/** The update mode is used to inform ComponentKit how to apply changes. */
typedef NS_ENUM(NSInteger, CKUpdateMode) {
  /** Apply the update off the main thread. */
  CKUpdateModeAsynchronous,
  /**
   Apply the update on the main thread.
   The synchronous update mode will not immediately block the executing thread when apply updates. Instead ComponentKit
   will schedule the update to be performed on the next tick of the main thread's run loop.
   */
  CKUpdateModeSynchronous,
};
