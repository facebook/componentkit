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

#ifndef CK_NOT_DESIGNATED_INITIALIZER
#define CK_NOT_DESIGNATED_INITIALIZER() \
  do { \
    NSAssert2(NO, @"%@ is not the designated initializer for instances of %@.", NSStringFromSelector(_cmd), NSStringFromClass([self class])); \
    return nil; \
  } while (0)
#endif // CK_NOT_DESIGNATED_INITIALIZER

#ifndef CK_NOT_DESIGNATED_INITIALIZER_ATTRIBUTE
#define CK_NOT_DESIGNATED_INITIALIZER_ATTRIBUTE \
__attribute__((unavailable("Not the designated initializer")))
#endif // CK_NOT_DESIGNATED_INITIALIZER_ATTRIBUTE

#ifndef CK_FINAL_CLASS_INITIALIZE_IMP
#define CK_FINAL_CLASS_INITIALIZE_IMP(__finalClass) \
  do { \
    if (![NSStringFromClass(self) hasPrefix:@"NSKVONotifying"] && self != (__finalClass)) { \
      NSString *reason = [NSString stringWithFormat:@"%@ is a final class and cannot be subclassed. %@", NSStringFromClass((__finalClass)), NSStringFromClass(self)]; \
      @throw [NSException exceptionWithName:@"CKFinalClassViolationException" reason:reason userInfo:nil]; \
    } \
  } while(0)
#endif // CK_FINAL_CLASS_INITIALIZE_IMP

#ifndef CK_FINAL_CLASS
#define CK_FINAL_CLASS(__finalClass) \
  + (void)initialize { CK_FINAL_CLASS_INITIALIZE_IMP((__finalClass)); }
#endif // Ck_FINAL_CLASS

#define CK_ARRAY_COUNT(x) sizeof(x) / sizeof(x[0])