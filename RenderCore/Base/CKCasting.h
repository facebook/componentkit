/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <RenderCore/CKDefines.h>

#if CK_NOT_SWIFT

#ifndef CKCasting_h
#define CKCasting_h

#import <RenderCore/CKAssert.h>

namespace CK {
  template <typename T>
  T *objCForceCast(id any) {
    CKCAssert([any isKindOfClass:[T class]], @"Dynamic cast of %@ to %@ failed", any, [T class]);
    return static_cast<T *>(any);
  }
}

#endif /* CKCasting_h */
#endif /* CK_NOT_SWIFT */
