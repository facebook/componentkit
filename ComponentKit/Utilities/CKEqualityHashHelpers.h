/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <UIKit/UIKit.h>

#import <functional>
#import <string>
#import <vector>

// From folly:
// This is the Hash128to64 function from Google's cityhash (available
// under the MIT License).  We use it to reduce multiple 64 bit hashes
// into a single hash.
inline uint64_t CKHashCombine(const uint64_t upper, const uint64_t lower) {
  // Murmur-inspired hashing.
  const uint64_t kMul = 0x9ddfea08eb382d69ULL;
  uint64_t a = (lower ^ upper) * kMul;
  a ^= (a >> 47);
  uint64_t b = (upper ^ a) * kMul;
  b ^= (b >> 47);
  b *= kMul;
  return b;
}

#if __LP64__
inline size_t CKHash64ToNative(uint64_t key) {
  return key;
}
#else
// Thomas Wang downscaling hash function
inline size_t CKHash64ToNative(uint64_t key) {
  key = (~key) + (key << 18);
  key = key ^ (key >> 31);
  key = key * 21;
  key = key ^ (key >> 11);
  key = key + (key << 6);
  key = key ^ (key >> 22);
  return (uint32_t) key;
}
#endif

NSUInteger CKIntegerArrayHash(const NSUInteger *subhashes, NSUInteger count);

namespace CK {
  // Default is not an ObjC class
  template <typename T, typename = void>
  struct is_objc_class : std::false_type { };

  // Conditionally enable this template specialization on whether T is convertible to id, makes the is_objc_class a true_type
  template <typename T>
  struct is_objc_class<T, typename std::enable_if<std::is_convertible<T, id>::value>::type> : std::true_type { };

  // Default isn't hashable.
  template <typename T, typename = void>
  struct is_std_hashable : std::false_type {};

  // Conditionally enable when T is hashable by std::hash.
  template <typename T>
  struct is_std_hashable<T, typename std::enable_if<std::is_same<decltype(std::hash<T>()(std::declval<T>())), size_t>::value>::type> : std::true_type { };

  // Default is not an iterable
  template <typename T, typename V = bool>
  struct is_iterable : std::false_type { };

  // Conditionally enable when T can be iterated on.
  template <typename T>
  struct is_iterable<T, typename std::enable_if<std::is_same<decltype(std::declval<T>().begin()), decltype(std::declval<T>().end())>::value>::type> : std::true_type { };

  // Get the element type of the collection.
  template <typename T>
  using collection_element_t = typename std::iterator_traits<decltype(std::declval<T>().begin())>::value_type;

  // Defer to std:hash when available.
  template <typename T, typename = typename std::enable_if<is_std_hashable<T>::value && !is_objc_class<T>::value>::type>
  size_t hash(const T &a)
  {
    return std::hash<T>()(a);
  }

  // For objc types, call [o hash]
  template <typename T, typename = typename std::enable_if<is_objc_class<T>::value>::type>
  size_t hash(T a)
  {
    return [a hash];
  }

  // std::hash doesn't have a default implementation for std::vector<T> and other collection types
  // when T is hashable. This stubs in for that.
  template <typename T, typename = typename std::enable_if<!is_std_hashable<T>::value>::type, typename = typename std::enable_if<is_std_hashable<collection_element_t<T>>::value>::type>
  size_t hash(const T &a)
  {
    uint64_t value = 0;
    for (const auto elem : a) {
      value = CKHashCombine(value, hash(elem));
    }
    return CKHash64ToNative(value);
  }

  // Hash definitions for common Cocoa structs.
  extern size_t hash(const CGFloat &a);
  extern size_t hash(const CGPoint &a);
  extern size_t hash(const CGSize &a);
  extern size_t hash(const CGRect &a);
  extern size_t hash(const UIEdgeInsets &a);
  extern size_t hash(const CGAffineTransform &a);
  extern size_t hash(const CATransform3D &a);

  template <typename T, typename Enable = void> struct is_equal;

  // For non-objc types use == operator
  template <typename T> struct is_equal<T, typename std::enable_if<!is_objc_class<T>::value>::type> {
    bool operator ()(const T& a, const T& b) {
      return a == b;
    }
  };

  // For objc types, check pointer equality, then use -isEqual:
  template <typename T> struct is_equal<T, typename std::enable_if<is_objc_class<T>::value>::type> {
    bool operator ()(id a, id b) {
      return a == b || [a isEqual:b];
    }
  };

  // Equals definitions for common Cocoa structs.
  template<> struct is_equal<CGFloat> {
    bool operator ()(const CGFloat &a, const CGFloat &b) {
      return a == b;
    }
  };

  template<> struct is_equal<CGPoint> {
    bool operator ()(const CGPoint &a, const CGPoint &b) {
      return (is_equal<CGFloat>()(a.x, b.x) &&
              is_equal<CGFloat>()(a.y, b.y));
    }
  };

  template<> struct is_equal<CGSize> {
    bool operator ()(const CGSize &a, const CGSize &b) {
      return (is_equal<CGFloat>()(a.width, b.width) &&
              is_equal<CGFloat>()(a.height, b.height));
    }
  };

  template<> struct is_equal<CGRect> {
    bool operator ()(const CGRect &a, const CGRect &b) {
      return (is_equal<CGPoint>()(a.origin, b.origin) &&
              is_equal<CGSize>()(a.size, b.size));
    }
  };

  template<> struct is_equal<UIEdgeInsets> {
    bool operator ()(const UIEdgeInsets &a, const UIEdgeInsets &b) {
      return (is_equal<CGFloat>()(a.top, b.top) &&
              is_equal<CGFloat>()(a.left, b.left) &&
              is_equal<CGFloat>()(a.bottom, b.bottom) &&
              is_equal<CGFloat>()(a.right, b.right));
    }
  };

  template<> struct is_equal<CGAffineTransform> {
    bool operator ()(const CGAffineTransform &a, const CGAffineTransform &b) {
      return (is_equal<CGFloat>()(a.a, b.a) &&
              is_equal<CGFloat>()(a.b, b.b) &&
              is_equal<CGFloat>()(a.c, b.c) &&
              is_equal<CGFloat>()(a.d, b.d) &&
              is_equal<CGFloat>()(a.tx, b.tx) &&
              is_equal<CGFloat>()(a.ty, b.ty));
    }
  };

  template<> struct is_equal<CATransform3D> {
    bool operator ()(const CATransform3D &a, const CATransform3D &b) {
      return (is_equal<CGFloat>()(a.m11, b.m11) &&
              is_equal<CGFloat>()(a.m12, b.m12) &&
              is_equal<CGFloat>()(a.m13, b.m13) &&
              is_equal<CGFloat>()(a.m14, b.m14) &&
              is_equal<CGFloat>()(a.m21, b.m21) &&
              is_equal<CGFloat>()(a.m22, b.m22) &&
              is_equal<CGFloat>()(a.m23, b.m23) &&
              is_equal<CGFloat>()(a.m24, b.m24) &&
              is_equal<CGFloat>()(a.m31, b.m31) &&
              is_equal<CGFloat>()(a.m32, b.m32) &&
              is_equal<CGFloat>()(a.m33, b.m33) &&
              is_equal<CGFloat>()(a.m34, b.m34) &&
              is_equal<CGFloat>()(a.m41, b.m41) &&
              is_equal<CGFloat>()(a.m42, b.m42) &&
              is_equal<CGFloat>()(a.m43, b.m43) &&
              is_equal<CGFloat>()(a.m44, b.m44));
    }
  };
};

namespace CKTupleOperations
{
  // Recursive case (hash up to Index)
  template <class Tuple, size_t Index = std::tuple_size<Tuple>::value - 1>
  struct _hash_helper
  {
    static size_t hash(Tuple const& tuple)
    {
      size_t prev = _hash_helper<Tuple, Index-1>::hash(tuple);
      size_t thisHash = CK::hash(std::get<Index>(tuple));
      return CKHash64ToNative(CKHashCombine(prev, thisHash));
    }
  };

  // Base case (hash 0th element)
  template <class Tuple>
  struct _hash_helper<Tuple, 0>
  {
    static size_t hash(Tuple const& tuple)
    {
      return CK::hash(std::get<0>(tuple));
    }
  };

  // Recursive case (elements equal up to Index)
  template <class Tuple, size_t Index = std::tuple_size<Tuple>::value - 1>
  struct _eq_helper
  {
    static bool equal(Tuple const& a, Tuple const& b)
    {
      bool prev = _eq_helper<Tuple, Index-1>::equal(a, b);
      using TypeForIndex = typename std::tuple_element<Index,Tuple>::type;
      auto aValue = std::get<Index>(a);
      auto bValue = std::get<Index>(b);
      return prev && CK::is_equal<TypeForIndex>()(aValue, bValue);
    }
  };

  // Base case (0th elements equal)
  template <class Tuple>
  struct _eq_helper<Tuple, 0>
  {
    static bool equal(Tuple const& a, Tuple const& b)
    {
      using TypeForIndex = typename std::tuple_element<0,Tuple>::type;
      auto& aValue = std::get<0>(a);
      auto& bValue = std::get<0>(b);
      return CK::is_equal<TypeForIndex>()(aValue, bValue);
    }
  };


  template <typename ... TT> struct hash;

  template <typename ... TT>
  struct hash<std::tuple<TT...>>
  {
    size_t operator()(std::tuple<TT...> const& tt) const
    {
      return _hash_helper<std::tuple<TT...>>::hash(tt);
    }
  };


  template <typename ... TT> struct equal_to;

  template <typename ... TT>
  struct equal_to<std::tuple<TT...>>
  {
    bool operator()(std::tuple<TT...> const& a, std::tuple<TT...> const& b) const
    {
      return _eq_helper<std::tuple<TT...>>::equal(a, b);
    }
  };
  
}
