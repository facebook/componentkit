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

#define CKConditionalAssert(shouldTestCondition, condition, description, ...) CKAssert((!(shouldTestCondition) || (condition)), nil, (description), ##__VA_ARGS__)
#define CKCConditionalAssert(shouldTestCondition, condition, description, ...) CKCAssert((!(shouldTestCondition) || (condition)), nil, (description), ##__VA_ARGS__)

#define CKAssertNil(condition, description, ...) CKAssert(!(condition), (description), ##__VA_ARGS__)
#define CKCAssertNil(condition, description, ...) CKCAssert(!(condition), (description), ##__VA_ARGS__)

#define CKAssertNotNil(condition, description, ...) CKAssert((condition), (description), ##__VA_ARGS__)
#define CKCAssertNotNil(condition, description, ...) CKCAssert((condition), (description), ##__VA_ARGS__)

#define CKAssertTrue(condition) CKAssert((condition), nil, nil)
#define CKCAssertTrue(condition) CKCAssert((condition), nil, nil)

#define CKAssertFalse(condition) CKAssert(!(condition), nil, nil)
#define CKCAssertFalse(condition) CKCAssert(!(condition), nil, nil)

#define CKAssertMainThread() CKAssert([NSThread isMainThread], nil, @"This method must be called on the main thread")
#define CKCAssertMainThread() CKCAssert([NSThread isMainThread], nil, @"This method must be called on the main thread")

#define CKFailAssert(description, ...) CKAssert(NO, nil, (description), ##__VA_ARGS__)
#define CKCFailAssert(description, ...) CKCAssert(NO, nil, (description), ##__VA_ARGS__)
