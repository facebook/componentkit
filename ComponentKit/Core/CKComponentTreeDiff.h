/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKDefines.h>

#if CK_NOT_SWIFT

#ifndef CKComponentTreeDiff_h
#define CKComponentTreeDiff_h

#import <Foundation/Foundation.h>

#import <vector>

@class CKComponent;

namespace CK {
  /*
   A structure describing the changes between two instances of the same "logical" component tree,
   i.e. before and after a state update.
   */
  struct ComponentTreeDiff {
    /* A structure that stores two successive generations of the same "logical" component. */
    struct Pair {
      CKComponent *const prev;
      CKComponent *const current;
    };

    auto description() const -> NSString *;

    /* Components only present in the newer version of the tree. */
    const std::vector<CKComponent *> appearedComponents = {};
    /* Components that appear in both versions of the tree. Each component is paired up with its previous generation. */
    const std::vector<Pair> updatedComponents = {};
    /* Components not present in the newer version of the tree. */
    const std::vector<CKComponent *> disappearedComponents = {};
  };

  auto operator==(const ComponentTreeDiff &lhs, const ComponentTreeDiff &rhs) -> bool;
  auto operator==(const ComponentTreeDiff::Pair &lhs, const ComponentTreeDiff::Pair &rhs) -> bool;
}

#endif /* CKComponentTreeDiff_h */

#endif
