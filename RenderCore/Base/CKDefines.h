/*
*  Copyright (c) 2014-present, Facebook, Inc.
*  All rights reserved.
*
*  This source code is licensed under the BSD-style license found in the
*  LICENSE file in the root directory of this source tree. An additional grant
*  of patent rights can be found in the PATENTS file in the same directory.
*
*/

#import <RenderCore/CKMacros.h>

#if defined(__cplusplus) && __cplusplus
  #define CK_SWIFT 0
#else
  #define CK_SWIFT 1
#endif

#define CK_NOT_SWIFT !CK_SWIFT

#ifdef __cplusplus
#define CK_EXTERN_C_BEGIN extern "C" {
#define CK_EXTERN_C_END }
#else
#define CK_EXTERN_C_BEGIN
#define CK_EXTERN_C_END
#endif

#define CK_INIT_UNAVAILABLE \
  - (instancetype)init NS_UNAVAILABLE
