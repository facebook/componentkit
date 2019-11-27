/*
*  Copyright (c) 2014-present, Facebook, Inc.
*  All rights reserved.
*
*  This source code is licensed under the BSD-style license found in the
*  LICENSE file in the root directory of this source tree. An additional grant
*  of patent rights can be found in the PATENTS file in the same directory.
*
*/

#import <ComponentKit/CKAssert.h>

#pragma once

#define CKFatal(description, ...) CKAssert(NO, (description), ##__VA_ARGS__)
#define CKCFatal(description, ...) CKCAssert(NO, (description), ##__VA_ARGS__)

#define CKFatalWithCategory(category, description, ...) \
do { \
  NSMutableString *__ckError_loggingString = [NSMutableString stringWithFormat:@"[%@] Fatal: ",(category)]; \
  [__ckError_loggingString appendFormat:(description), ##__VA_ARGS__]; \
  CKFatal(@"%@", __ckError_loggingString);\
} while(0)

#define CKCFatalWithCategory(category, description, ...) \
do { \
  NSMutableString *__ckError_loggingString = [NSMutableString stringWithFormat:@"[%@] Fatal: ",(category)]; \
  [__ckError_loggingString appendFormat:(description), ##__VA_ARGS__]; \
  CKCFatal(@"%@", __ckError_loggingString);\
} while(0)
