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

#define CK_ARRAY_COUNT(x) sizeof(x) / sizeof(x[0])

#if defined(__has_attribute) && __has_attribute(noescape)
#define CK_NOESCAPE __attribute__((noescape))
#else
#define CK_NOESCAPE
#endif // defined(__has_attribute) && __has_attribute(noescape)
