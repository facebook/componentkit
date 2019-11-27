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

#import <ComponentKit/CKCollection.h>

namespace CK {
  auto ComponentTreeDiff::description() const -> NSString *
  {
    auto description = [NSMutableString new];
    if (!appearedComponents.empty()) {
      [description appendString:@"Appeared components: {\n"];
      [description appendString:Collection::descriptionForElements(appearedComponents, [](const auto &c){
        return [NSString stringWithFormat:@"\t%@", c];
      })];
      [description appendString:@"\n}\n"];
    }
    if (!updatedComponents.empty()) {
      [description appendString:@"Updated components: {\n"];
      [description appendString:Collection::descriptionForElements(updatedComponents, [](const auto &p){
        return [NSString stringWithFormat:@"\t%@ -> %@", p.prev, p.current];
      })];
      [description appendString:@"\n}\n"];
    }
    return description;
  }

  auto operator==(const ComponentTreeDiff &lhs, const ComponentTreeDiff &rhs) -> bool
  {
    return lhs.appearedComponents == rhs.appearedComponents && lhs.updatedComponents == rhs.updatedComponents && lhs.disappearedComponents == rhs.disappearedComponents;
  }

  auto operator==(const ComponentTreeDiff::Pair &lhs, const ComponentTreeDiff::Pair &rhs) -> bool
  {
    return lhs.prev == rhs.prev && lhs.current == rhs.current;
  }
}
