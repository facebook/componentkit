/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#ifndef CKCollection_h
#define CKCollection_h

namespace CK {
  namespace Collection {
    template <typename Collection, typename Predicate>
    bool containsWhere(const Collection& collection, Predicate &&predicate)
    {
      return std::find_if(collection.begin(), collection.end(), predicate) != collection.end();
    }

    template <typename Collection>
    bool contains(const Collection& collection, typename Collection::const_reference value)
    {
      return std::find(collection.begin(), collection.end(), value) != collection.end();
    }
  }
}

#endif /* CKCollection_h */
