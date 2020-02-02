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

#include <algorithm>
#include <utility>
#include <vector>

namespace CK {
/**
 An associative container that stores a mapping from instances of \c Key to instances of \c Value .

 \c CK::Dictionary does not require keys to be hashable, only to be equatable. Both keys and values must be default constructible. Insertions take linear time.
 */
template <typename Key, typename Value>
class Dictionary {
  using Storage = std::vector<std::pair<Key, Value>>;

public:
  using value_type = typename Storage::value_type;
  using const_reference = typename Storage::const_reference;

  /**
   Initialises an empty dictionary.
   */
  Dictionary() = default;

  /**
   Initialises a dictionary from a list of key-value pairs. Keys must be unique.
   */
  Dictionary(std::initializer_list<value_type> kvs) : _elements{kvs} {
#ifndef NDEBUG
    auto keys = std::vector<Key>{};
    for (auto const &kv : kvs) {
      auto const it = std::find(keys.begin(), keys.end(), kv.first);
      assert(it == keys.end() && "Keys must be unique");
      keys.push_back(kv.first);
    }
#endif
  }

  auto begin() & { return _elements.begin(); }
  auto end() & { return _elements.end(); }
  auto begin() const & { return _elements.cbegin(); }
  auto end() const & { return _elements.cend(); }

  auto empty() const { return _elements.empty(); }
  auto size() const { return _elements.size(); }

  /**
   Provides access to keys and values stored in the dictionary.

   \param key A key used to look up the value.
   \return  A reference to an existing value, or, if the key was previously missing, a reference to just inserted default constructed value.
   */
  auto operator [](const Key &key) -> Value & {
    auto const it = std::find_if(_elements.begin(), _elements.end(), [&key](const_reference kv) {
      return kv.first == key;
    });

    if (it == _elements.end()) {
      _elements.emplace_back(key, Value{});
      return _elements.back().second;
    } else {
      return it->second;
    }
  }

private:
  Storage _elements;
};
}

#endif

