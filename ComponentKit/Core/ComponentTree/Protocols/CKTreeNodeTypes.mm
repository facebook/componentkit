/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKTreeNodeTypes.h"

namespace CK {
  namespace TreeNode {
    auto areKeysEqual(const CKTreeNodeComponentKey &lhs, const CKTreeNodeComponentKey &rhs) -> bool
    {
      return std::get<0>(lhs) == std::get<0>(rhs) &&
      std::get<1>(lhs) == std::get<1>(rhs) &&
      CKObjectIsEqual(std::get<2>(lhs), std::get<2>(rhs)) &&
      CKKeyVectorsEqual(std::get<3>(lhs), std::get<3>(rhs));
    }
    
    auto isKeyEmpty(const CKTreeNodeComponentKey &key) -> bool
    {
      return std::get<0>(key) == NULL;
    }
  }
}
