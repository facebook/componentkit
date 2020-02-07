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

NS_ASSUME_NONNULL_BEGIN

/**
 Equivalent to `objc_getAssociatedObject` but main thread affined.
 */
id _Nullable CKGetAssociatedObject_MainThreadAffined(id object, const void *key);

/**
 Equivalent to `objc_setAssociatedObject` but main thread affined.
 */
void CKSetAssociatedObject_MainThreadAffined(id object, const void *key, id _Nullable value);

NS_ASSUME_NONNULL_END
