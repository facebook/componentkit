/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#include "CKComponentTreeDiff.h"

namespace CK {
  auto operator==(const ComponentTreeDiff &lhs, const ComponentTreeDiff &rhs) -> bool
  {
    return lhs.appearedComponents == rhs.appearedComponents && lhs.updatedComponents == rhs.updatedComponents;
  }

  auto operator==(const ComponentTreeDiff::Pair &lhs, const ComponentTreeDiff::Pair &rhs) -> bool
  {
    return lhs.prev == rhs.prev && lhs.current == rhs.current;
  }
}
