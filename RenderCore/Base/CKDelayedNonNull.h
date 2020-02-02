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

#pragma once

#include <ComponentKit/CKDelayedInitialisationWrapper.h>
#include <RenderCore/CKNonNull.h>

namespace CK {
  template <typename Ptr>
  using DelayedNonNull = DelayedInitialisationWrapper<NonNull<Ptr>>;
}

#endif
