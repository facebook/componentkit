/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#pragma once

#if !defined(NS_BLOCK_ASSERTIONS)
#define CK_ASSERTIONS_ENABLED 1
#else
#define CK_ASSERTIONS_ENABLED 0
#endif

#define RCAssert(condition, description, ...) NSAssert(condition, description, ##__VA_ARGS__)
#define RCCAssert(condition, description, ...) NSCAssert(condition, description, ##__VA_ARGS__)

#define RCAssertNil(condition, description, ...) RCAssert(!(condition), (description), ##__VA_ARGS__)
#define RCCAssertNil(condition, description, ...) RCCAssert(!(condition), (description), ##__VA_ARGS__)

#define RCAssertNotNil(condition, description, ...) RCAssert((condition), (description), ##__VA_ARGS__)
#define RCCAssertNotNil(condition, description, ...) RCCAssert((condition), (description), ##__VA_ARGS__)

#define RCAssertTrue(condition) RCAssert((condition), nil, nil)
#define RCCAssertTrue(condition) RCCAssert((condition), nil, nil)

#define RCAssertFalse(condition) RCAssert(!(condition), nil, nil)
#define RCCAssertFalse(condition) RCCAssert(!(condition), nil, nil)

#define RCAssertMainThread() RCAssert([NSThread isMainThread], @"This method must be called on the main thread")
#define RCCAssertMainThread() RCCAssert([NSThread isMainThread], @"This method must be called on the main thread")

#define RCFailAssert(description, ...) RCAssert(NO, (description), ##__VA_ARGS__)
#define RCCFailAssert(description, ...) RCCAssert(NO, (description), ##__VA_ARGS__)

#define RCFailAssertWithCategory(category, description, ...) RCAssertWithCategory(NO, category, (description), ##__VA_ARGS__)
#define RCCFailAssertWithCategory(category, description, ...) RCCAssertWithCategory(NO, category, (description), ##__VA_ARGS__)

#define RCAssertWithCategory(condition, category, description, ...) \
do { \
  if (!(condition)) { \
    NSMutableString *__ckError_loggingString = [NSMutableString stringWithFormat:@"[%@] Error: ",(category)]; \
    [__ckError_loggingString appendFormat:(description), ##__VA_ARGS__]; \
    RCAssert((condition), __ckError_loggingString);\
  } \
} while(0)

#define RCCAssertWithCategory(condition, category, description, ...) \
do { \
  if (!(condition)) { \
    NSMutableString *__ckError_loggingString = [NSMutableString stringWithFormat:@"[%@] Error: ",(category)]; \
    [__ckError_loggingString appendFormat:(description), ##__VA_ARGS__]; \
    RCCAssert((condition), __ckError_loggingString);\
  } \
} while(0)

#define RCWarnWithCategory(condition, category, description, ...) \
do { \
  if (!(condition)) { \
    NSMutableString *__ckWarning_loggingString = [NSMutableString stringWithFormat:@"[%@] Warning: ",(category)]; \
    [__ckWarning_loggingString appendFormat:(description), ##__VA_ARGS__]; \
    NSLog(@"%@",__ckWarning_loggingString); \
  } \
} while(0)

#if CK_ASSERTIONS_ENABLED
#define RCCWarnWithCategory(condition, category, description, ...) \
do { \
  if (!(condition)) { \
    NSMutableString *__ckWarning_loggingString = [NSMutableString stringWithFormat:@"[%@] Warning: ",(category)]; \
    [__ckWarning_loggingString appendFormat:(description), ##__VA_ARGS__]; \
    NSLog(@"%@",__ckWarning_loggingString); \
  } \
} while(0)
#else
#define RCCWarnWithCategory(condition, category, description, ...)
#endif

#define RCWarn(condition, description, ...) if (!(condition)) { NSLog((description), ##__VA_ARGS__); }

#define RCCWarn(condition, description, ...) if (!(condition)) { NSLog((description), ##__VA_ARGS__); }
