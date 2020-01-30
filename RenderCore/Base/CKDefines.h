/*
*  Copyright (c) 2014-present, Facebook, Inc.
*  All rights reserved.
*
*  This source code is licensed under the BSD-style license found in the
*  LICENSE file in the root directory of this source tree. An additional grant
*  of patent rights can be found in the PATENTS file in the same directory.
*
*/

#if __has_feature(modules)
  #define CK_SWIFT 1
#else
  #define CK_SWIFT 0
#endif

#define CK_NOT_SWIFT !CK_SWIFT
