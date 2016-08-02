/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <algorithm>
#import <functional>
#import <type_traits>
#import <vector>

#import <UIKit/UIKit.h>

namespace CK {
  // adopted from http://stackoverflow.com/questions/14945223/map-function-with-c11-constructs
  // Takes an iterable, applies a function to every element,
  // and returns a vector of the results
  //
  template <typename T, typename Func>
  auto map(const T &iterable, Func &&func) -> std::vector<decltype(func(std::declval<typename T::value_type>()))>
  {
    // Some convenience type definitions
    typedef decltype(func(std::declval<typename T::value_type>())) value_type;
    typedef std::vector<value_type> result_type;

    // Prepares an output vector of the appropriate size
    result_type res(iterable.size());

    // Let std::transform apply `func` to all elements
    // (use perfect forwarding for the function object)
    std::transform(
                   begin(iterable), end(iterable), res.begin(),
                   std::forward<Func>(func)
                   );

    return res;
  }

  template<typename Func>
  auto map(id<NSFastEnumeration> collection, Func &&func) -> std::vector<decltype(func(std::declval<id>()))>
  {
    std::vector<decltype(func(std::declval<id>()))> to;
    for (id obj in collection) {
      to.push_back(func(obj));
    }
    return to;
  }

  template <typename T, typename Func>
  auto filter(const T &iterable, Func &&func) -> std::vector<typename T::value_type>
  {
    std::vector<typename T::value_type> to;
    for (auto obj : iterable) {
      if (func(obj)) {
        to.push_back(obj);
      }
    }
    return to;
  }

  template <class T> typename
  std::vector<T> chain(std::vector<T> a, std::vector<T> b) {
    std::vector<T> newVector;

    for (auto i: a) {
      newVector.push_back(i);
    }
    for (auto i: b) {
      newVector.push_back(i);
    }

    return newVector;
  }

  /**
   This function takes a vector and returns a new vector after adding an additional object between every entry in the vector that passes the predicate
   Example:
   inputs: { 1, 2, 3, 4, 5, 6 }, factory ^(int) { return 0; } predicate: ^BOOL(int a) { return a%2 == 0; }
   output: { 2, 0, 4, 0, 6 }
   */
  template <typename T, typename Func, typename Predicate>
  auto intersperse(std::vector<T> a, Func &&factory, Predicate predicate) -> std::vector<T>
  {
    std::vector<T> newVector;

    if (a.size() < 2) {
      return (a.size() == 1 && predicate(a.at(0))) ? a : newVector;
    }

    for (int i = 0; i < a.size() - 1; i++) {
      T currentA = a.at(i);
      if (predicate(currentA)) {
        newVector.push_back(currentA);
        newVector.push_back(factory());
      }
    }

    T lastA = a.at(a.size() - 1);
    if (predicate(lastA)) {
      newVector.push_back(lastA);
    }

    return newVector;
  }
};

inline CGPoint operator+(const CGPoint &p1, const CGPoint &p2)
{
  return { p1.x + p2.x, p1.y + p2.y };
}

inline CGPoint operator-(const CGPoint &p1, const CGPoint &p2)
{
  return { p1.x - p2.x, p1.y - p2.y };
}

inline CGSize operator+(const CGSize &s1, const CGSize &s2)
{
  return { s1.width + s2.width, s1.height + s2.height };
}

inline CGSize operator-(const CGSize &s1, const CGSize &s2)
{
  return { s1.width - s2.width, s1.height - s2.height };
}

inline UIEdgeInsets operator+(const UIEdgeInsets &e1, const UIEdgeInsets &e2)
{
  return { e1.top + e2.top, e1.left + e2.left, e1.bottom + e2.bottom, e1.right + e2.right };
}

inline UIEdgeInsets operator-(const UIEdgeInsets &e1, const UIEdgeInsets &e2)
{
  return { e1.top - e2.top, e1.left - e2.left, e1.bottom - e2.bottom, e1.right - e2.right };
}

inline UIEdgeInsets operator*(const UIEdgeInsets &e1, const UIEdgeInsets &e2)
{
  return { e1.top * e2.top, e1.left * e2.left, e1.bottom * e2.bottom, e1.right * e2.right };
}

inline UIEdgeInsets operator-(const UIEdgeInsets &e)
{
  return { -e.top, -e.left, -e.bottom, -e.right };
}

/** Correctly equates two objects, including cases where both objects are nil (where `isEqual:` would return NO). */
inline BOOL CKObjectIsEqual(id<NSObject> obj, id<NSObject> otherObj)
{
  return obj == otherObj || [obj isEqual:otherObj];
}

typedef BOOL (^CKEqualityComparisonBlock)(id object, id comparisonObject);

/** 
 * Correctly executes the comparisonBlock for two objects, including cases one of the objects is nil or
 * of a different type (where `isEqual:` would return NO).
 */
inline BOOL CKCompareObjectEquality(id object, id comparisonObject, CKEqualityComparisonBlock comparisonBlock) {
  if (object == comparisonObject) {
    return YES;
  } else if (!object || !comparisonObject || ![comparisonObject isKindOfClass:[object class]]) {
    return NO;
  }
  return comparisonBlock(object, comparisonObject);
}
