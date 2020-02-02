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

#ifndef CKCollection_h
#define CKCollection_h

#import <algorithm>
#import <functional>
#import <type_traits>

#import <RenderCore/CKAssert.h>
#import <RenderCore/CKFunctionalHelpers.h>

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

    /*
     Returns elements that are present in the first collection but not in the second. Element equivalence is determined
     by calling a binary predicate passed as the last parameter.
     */
    template <typename Collection1, typename Collection2, typename Predicate>
    auto difference(const Collection1 &c1, const Collection2 &c2, Predicate &&areEqual)
    {
      return filter(c1, [&](const auto &x1) {
        return !containsWhere(c2, [&](const auto &x2) {
          return areEqual(x1, x2);
        });
      });
    }

    /*
     Returns elements that are present both collections. Element equivalence is determined by calling a binary predicate
     passed as the last parameter.
     */
    template <typename Collection1, typename Collection2, typename Predicate>
    auto intersection(const Collection1 &c1, const Collection2 &c2, Predicate &&areEqual)
    {
      return filter(c1, [&](const auto &x1) {
        return containsWhere(c2, [&](const auto &x2) {
          return areEqual(x1, x2);
        });
      });
    }

    /*
     Given a collection of other collections, returns a lower-dimensional collection by "flattening" its elements into
     it, e.g. `flatten({{1, 2}, {3, 4}) == {1, 2, 3, 4}`.
     */
    template <typename Collection>
    auto flatten(const Collection &c) {
      auto r = std::vector<typename Collection::value_type::value_type> {};
      for (const auto &x : c) {
        r.insert(r.end(), x.begin(), x.end());
      }
      return r;
    }

    /*
     Returns string representations of elements of the collection separated by comma and new line. String representation
     of each element is obtained by calling the passed element description provider function.
     */
    template <typename Collection, typename ElementDescriptionFunc>
    auto descriptionForElements(const Collection &c, ElementDescriptionFunc &&d)
    {
      static_assert(std::is_convertible<ElementDescriptionFunc, std::function<NSString *(typename Collection::const_reference)>>::value, "Description provider needs to take a const reference to an element of the collection and return an NSString *");
      auto elementStrs = static_cast<NSMutableArray<NSString *> *>([NSMutableArray array]);
      for (const auto &e : c) {
        [elementStrs addObject:d(e)];
      }
      return [elementStrs componentsJoinedByString:@",\n"];
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
    Iterator(NSEnumerator *enumerator) : _enumerator(enumerator), _value(enumerator.nextObject) {};

    T operator* () const { return _value; }
    void operator++ () { _value = _enumerator.nextObject; }
    bool operator == (const Iterator &rhs) const { return _value == rhs._value; }
    bool operator != (const Iterator &rhs) const { return !(*this == rhs); }

  private:
    NSEnumerator *_enumerator;
    T _value;
  };

  using value_type = typename Iterator::value_type;
  using const_reference = const value_type &;

  CKCocoaCollectionAdapter(id collection) : _collection(collection)
  {
    assertCollectionRespondsToSelector(collection, @selector(objectEnumerator));
    assertCollectionRespondsToSelector(collection, @selector(count));
  }

  auto begin() const { return Iterator {[_collection objectEnumerator]}; }
  auto end() const { return Iterator {}; }
  auto size() const { return [_collection count]; }
  auto empty() const { return size() == 0; }

private:
  static auto assertCollectionRespondsToSelector(id c, SEL sel)
  {
    CKCAssert([c respondsToSelector:sel],
              @"%@ is not a collection since it doesn't respond to %@",
              c,
              NSStringFromSelector(sel));
  }

  id _collection;
};

#endif /* CKCollection_h */
#endif
