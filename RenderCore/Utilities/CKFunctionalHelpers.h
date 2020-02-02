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

#import <Foundation/Foundation.h>

#import <algorithm>
#import <functional>
#import <type_traits>
#import <vector>

#import <RenderCore/CKMacros.h>

namespace CK {
  /**
   Takes an iterable, applies a function to every element, and returns a vector of the results.
   Adapted from http://stackoverflow.com/questions/14945223/map-function-with-c11-constructs
   */
  template<typename Func>
  auto mapWithIndex(id<NSFastEnumeration> collection, CK_NOESCAPE Func &&func) -> std::vector<decltype(func(std::declval<id>(), std::declval<NSUInteger>()))>
  {
    std::vector<decltype(func(std::declval<id>(), std::declval<NSUInteger>()))> to;
    NSUInteger index = 0;
    for (id obj in collection) {
      to.push_back(func(obj, index));
      index++;
    }
    return to;
  }

  template <typename T, typename Func>
  auto mapWithIndex(const T &iterable, CK_NOESCAPE Func &&func) -> std::vector<decltype(func(std::declval<typename T::value_type>(), std::declval<NSUInteger>()))>
  {
    typedef decltype(func(std::declval<typename T::value_type>(), std::declval<NSUInteger>())) value_type;

    std::vector<value_type> res;
    res.reserve(iterable.size());
    NSUInteger index = 0;

    for (auto it = iterable.begin(); it != iterable.end(); ++it, ++index) {
      res.push_back(func(*it, index));
    }

    return res;
  }

  template <typename T, typename Func>
  auto map(const T &iterable, CK_NOESCAPE Func &&func) -> std::vector<decltype(func(std::declval<typename T::value_type>()))>
  {
    // Convenience type definition
    typedef decltype(func(std::declval<typename T::value_type>())) value_type;

    // Prepares an output vector of the appropriate size
    std::vector<value_type> res;
    res.reserve(iterable.size());

    // Let std::transform apply `func` to all elements
    // (use perfect forwarding for the function object)
    std::transform(
                   std::begin(iterable), std::end(iterable), std::back_inserter(res),
                   std::forward<Func>(func)
                   );

    return res;
  }

  template<typename Func>
  auto map(id<NSFastEnumeration> collection, CK_NOESCAPE Func &&func) -> std::vector<decltype(func(std::declval<id>()))>
  {
    return mapWithIndex(collection, [&func](id obj, NSUInteger) { return func(obj); });
  }

  template <typename T, typename Func>
  auto filter(const T &iterable, CK_NOESCAPE Func &&func) -> std::vector<typename T::value_type>
  {
    std::vector<typename T::value_type> to;
    for (const auto &obj : iterable) {
      if (func(obj)) {
        to.push_back(obj);
      }
    }
    return to;
  }

  template<typename Func>
  auto filter(id<NSFastEnumeration> collection, CK_NOESCAPE Func &&func) -> std::vector<id>
  {
    std::vector<id> to;
    for (id obj in collection) {
      if (func(obj)) {
        to.push_back(obj);
      }
    }
    return to;
  }

  namespace detail {
    template <class ContainerA, class ContainerB>
    std::vector<typename std::decay<ContainerA>::type::value_type> chainImpl(ContainerA &&a, ContainerB &&b) {
      std::vector<typename std::decay<ContainerA>::type::value_type> newVector(std::forward<ContainerA>(a));
      newVector.reserve(newVector.size() + b.size());

      for (auto &&i: b) {
        newVector.push_back(std::move(i));
      }

      return newVector;
    }
  } // namespace detail


  // std::initializer_list<T> isn't deduced as a template argument, so
  // we need to provide explicit overloads for it. I didn't want to
  // expose detail::chainImpl in its full generality either, so I'm
  // also providing explicit overloads for flavors of vectors. In
  // short, what follows are overloads for all 9 possible 2-element
  // pairs drawn from the set {const vector<T> &, vector<T> &&,
  // initializer_list<T>}.
  template <class T>
  std::vector<T> chain(const std::vector<T> &a, const std::vector<T> &b) {
    return detail::chainImpl(a, b);
  }

  template <class T>
  std::vector<T> chain(const std::vector<T> &a, std::vector<T> &&b) {
    return detail::chainImpl(a, std::move(b));
  }

  template <class T>
  std::vector<T> chain(std::vector<T> &&a, const std::vector<T> &b) {
    return detail::chainImpl(std::move(a), b);
  }

  template <class T>
  std::vector<T> chain(std::vector<T> &&a, std::vector<T> &&b) {
    return detail::chainImpl(std::move(a), std::move(b));
  }

  template <class T>
  std::vector<T> chain(std::vector<T> &&a, std::initializer_list<T> b) {
    return detail::chainImpl(std::move(a), b);
  }

  template <class T>
  std::vector<T> chain(const std::vector<T> &a, std::initializer_list<T> b) {
    return detail::chainImpl(a, b);
  }

  template <class T>
  std::vector<T> chain(std::initializer_list<T> a, const std::vector<T> &b) {
    return detail::chainImpl(a, b);
  }

  template <class T>
  std::vector<T> chain(std::initializer_list<T> a, std::vector<T> &&b) {
    return detail::chainImpl(a, std::move(b));
  }

  template <class T>
  std::vector<T> chain(std::initializer_list<T> a, std::initializer_list<T> b) {
    return detail::chainImpl(a, b);
  }

  /**
   This function takes a vector and returns a new vector after adding an additional object between every entry in the vector
   Example:
   inputs: { 2, 4, 6 }, factory ^(int) { return 0; }
   output: { 2, 0, 4, 0, 6 }
   */
  template <typename T, typename Func>
  auto intersperse(const std::vector<T> &a, CK_NOESCAPE Func &&factory) -> std::vector<T>
  {
    if (a.size() < 2) {
      return a;
    }

    std::vector<T> newVector;
    for (int i = 0; i < a.size(); i++) {
      newVector.push_back(a.at(i));
      if (i != a.size() - 1) {
        newVector.push_back(factory());
      }
    }
    return newVector;
  }
};

#endif
