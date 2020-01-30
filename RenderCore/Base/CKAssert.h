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

#define CKAssert(condition, description, ...) NSAssert(condition, description, ##__VA_ARGS__)
#define CKCAssert(condition, description, ...) NSCAssert(condition, description, ##__VA_ARGS__)

#define CKAssertNil(condition, description, ...) CKAssert(!(condition), (description), ##__VA_ARGS__)
#define CKCAssertNil(condition, description, ...) CKCAssert(!(condition), (description), ##__VA_ARGS__)

#define CKAssertNotNil(condition, description, ...) CKAssert((condition), (description), ##__VA_ARGS__)
#define CKCAssertNotNil(condition, description, ...) CKCAssert((condition), (description), ##__VA_ARGS__)

#define CKAssertTrue(condition) CKAssert((condition), nil, nil)
#define CKCAssertTrue(condition) CKCAssert((condition), nil, nil)

#define CKAssertFalse(condition) CKAssert(!(condition), nil, nil)
#define CKCAssertFalse(condition) CKCAssert(!(condition), nil, nil)

#define CKAssertMainThread() CKAssert([NSThread isMainThread], @"This method must be called on the main thread")
#define CKCAssertMainThread() CKCAssert([NSThread isMainThread], @"This method must be called on the main thread")

#define CKFailAssert(description, ...) CKAssert(NO, (description), ##__VA_ARGS__)
#define CKCFailAssert(description, ...) CKCAssert(NO, (description), ##__VA_ARGS__)

#define CKFailAssertWithCategory(category, description, ...) CKAssertWithCategory(NO, category, (description), ##__VA_ARGS__)
#define CKCFailAssertWithCategory(category, description, ...) CKCAssertWithCategory(NO, category, (description), ##__VA_ARGS__)

#define CKAssertWithCategory(condition, category, description, ...) \
do { \
  if (!(condition)) { \
    NSMutableString *__ckError_loggingString = [NSMutableString stringWithFormat:@"[%@] Error: ",(category)]; \
    [__ckError_loggingString appendFormat:(description), ##__VA_ARGS__]; \
    CKAssert((condition), __ckError_loggingString);\
  } \
} while(0)

#define CKCAssertWithCategory(condition, category, description, ...) \
do { \
  if (!(condition)) { \
    NSMutableString *__ckError_loggingString = [NSMutableString stringWithFormat:@"[%@] Error: ",(category)]; \
    [__ckError_loggingString appendFormat:(description), ##__VA_ARGS__]; \
    CKCAssert((condition), __ckError_loggingString);\
  } \
} while(0)

#define CKWarnWithCategory(condition, category, description, ...) \
do { \
  if (!(condition)) { \
    NSMutableString *__ckWarning_loggingString = [NSMutableString stringWithFormat:@"[%@] Warning: ",(category)]; \
    [__ckWarning_loggingString appendFormat:(description), ##__VA_ARGS__]; \
    NSLog(@"%@",__ckWarning_loggingString); \
  } \
} while(0)

#define CKCWarnWithCategory(condition, category, description, ...) \
do { \
  if (!(condition)) { \
    NSMutableString *__ckWarning_loggingString = [NSMutableString stringWithFormat:@"[%@] Warning: ",(category)]; \
    [__ckWarning_loggingString appendFormat:(description), ##__VA_ARGS__]; \
    NSLog(@"%@",__ckWarning_loggingString); \
  } \
} while(0)

#define CKWarn(condition, description, ...) if (!(condition)) { NSLog((description), ##__VA_ARGS__); }

#define CKCWarn(condition, description, ...) if (!(condition)) { NSLog((description), ##__VA_ARGS__); }
