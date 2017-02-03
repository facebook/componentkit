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

#ifdef __cplusplus
extern "C" {
#endif

/**
 Runs the current thread's run loop until the block returns YES or a timeout is reached.
 @param block The block to run on the current thread's run loop before it returns YES, or a timeout is reached.
 @return YES if the block returns YES by the end of the timeout, NO otherwise.
 */
extern BOOL CKRunRunLoopUntilBlockIsTrue(BOOL (^block)(void));

#ifdef __cplusplus
}
#endif
