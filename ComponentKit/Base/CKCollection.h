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

#import <algorithm>

#import <ComponentKit/CKAssert.h>

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

template <typename T>
class CKCocoaCollectionAdapter {
  static_assert(std::is_convertible<T, id>::value, "Only elements of ObjC types are supported");

public:
  // Modelled after http://en.cppreference.com/w/cpp/iterator/istream_iterator
  class Iterator: public std::iterator<std::input_iterator_tag, T> {
  public:
    Iterator() : _enumerator(nil), _value(nil) {};
    Iterator(NSEnumerator *_Nonnull enumerator) : _enumerator(enumerator), _value(enumerator.nextObject) {};

    T operator* () const { return _value; }
    void operator++ () { _value = _enumerator.nextObject; }
    bool operator == (const Iterator &rhs) const { return _value == rhs._value; }
    bool operator != (const Iterator &rhs) const { return !(*this == rhs); }

  private:
    NSEnumerator *_Nonnull _enumerator;
    T _value;
  };

  using value_type = typename Iterator::value_type;
  using const_reference = const value_type &;

  CKCocoaCollectionAdapter(id _Nonnull collection) : _collection(collection)
  {
    assertCollectionRespondsToSelector(collection, @selector(objectEnumerator));
    assertCollectionRespondsToSelector(collection, @selector(count));
  }

  auto begin() const { return Iterator {[_collection objectEnumerator]}; }
  auto end() const { return Iterator {}; }
  auto size() const { return [_collection count]; }
  auto empty() const { return size() == 0; }

private:
  static auto assertCollectionRespondsToSelector(id _Nonnull c, SEL _Nonnull sel)
  {
    CKCAssert([c respondsToSelector:sel],
              @"%@ is not a collection since it doesn't respond to %@",
              c,
              NSStringFromSelector(sel));
  }

  id _Nonnull _collection;
};

#endif /* CKCollection_h */
