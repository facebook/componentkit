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
  template<typename T, typename V = bool>
  struct is_objc_class : std::false_type { };

  // Conditionally enable this template specialization on whether T is convertible to id, makes the is_objc_class a true_type
  template<typename T>
  struct is_objc_class<T, typename std::enable_if<std::is_convertible<T, id>::value, bool>::type> : std::true_type { };

  // CKUtils::hash<T>()(value) -> either std::hash<T> if c++ or [o hash] if ObjC object.
  template <typename T, typename Enable = void> struct hash;

  // For non-objc types, defer to std::hash
  template <typename T> struct hash<T, typename std::enable_if<!is_objc_class<T>::value>::type> {
    size_t operator ()(const T& a) {
      return std::hash<T>()(a);
    }
  };

  // For objc types, call [o hash]
  template <typename T> struct hash<T, typename std::enable_if<is_objc_class<T>::value>::type> {
    size_t operator ()(id o) {
      return [o hash];
    }
  };

  // Hash definitions for common Cocoa structs.
  template<> struct hash<CGFloat> {
    size_t operator ()(const CGFloat &a) {
      return std::hash<CGFloat>()(a);
    }
  };

  template<> struct hash<CGPoint> {
    size_t operator ()(const CGPoint &a) {
      uint64_t value = 0;
      value = CKHashCombine(value, hash<CGFloat>()(a.x));
      value = CKHashCombine(value, hash<CGFloat>()(a.y));
      return CKHash64ToNative(value);
    }
  };

  template<> struct hash<CGSize> {
    size_t operator ()(const CGSize &a) {
      uint64_t value = 0;
      value = CKHashCombine(value, hash<CGFloat>()(a.width));
      value = CKHashCombine(value, hash<CGFloat>()(a.height));
      return CKHash64ToNative(value);
    }
  };

  template<> struct hash<CGRect> {
    size_t operator ()(const CGRect &a) {
      uint64_t value = 0;
      value = CKHashCombine(value, hash<CGPoint>()(a.origin));
      value = CKHashCombine(value, hash<CGSize>()(a.size));
      return CKHash64ToNative(value);
    }
  };

  template<> struct hash<UIEdgeInsets> {
    size_t operator ()(const UIEdgeInsets &a) {
      uint64_t value = 0;
      value = CKHashCombine(value, hash<CGFloat>()(a.top));
      value = CKHashCombine(value, hash<CGFloat>()(a.left));
      value = CKHashCombine(value, hash<CGFloat>()(a.bottom));
      value = CKHashCombine(value, hash<CGFloat>()(a.right));
      return CKHash64ToNative(value);
    }
  };

  template<> struct hash<CGAffineTransform> {
    size_t operator ()(const CGAffineTransform &a) {
      uint64_t value = 0;
      value = CKHashCombine(value, hash<CGFloat>()(a.a));
      value = CKHashCombine(value, hash<CGFloat>()(a.b));
      value = CKHashCombine(value, hash<CGFloat>()(a.c));
      value = CKHashCombine(value, hash<CGFloat>()(a.d));
      value = CKHashCombine(value, hash<CGFloat>()(a.tx));
      value = CKHashCombine(value, hash<CGFloat>()(a.ty));
      return CKHash64ToNative(value);
    }
  };

  template<> struct hash<CATransform3D> {
    size_t operator ()(const CATransform3D &a) {
      uint64_t value = 0;
      value = CKHashCombine(value, hash<CGFloat>()(a.m11));
      value = CKHashCombine(value, hash<CGFloat>()(a.m12));
      value = CKHashCombine(value, hash<CGFloat>()(a.m13));
      value = CKHashCombine(value, hash<CGFloat>()(a.m14));
      value = CKHashCombine(value, hash<CGFloat>()(a.m21));
      value = CKHashCombine(value, hash<CGFloat>()(a.m22));
      value = CKHashCombine(value, hash<CGFloat>()(a.m23));
      value = CKHashCombine(value, hash<CGFloat>()(a.m24));
      value = CKHashCombine(value, hash<CGFloat>()(a.m31));
      value = CKHashCombine(value, hash<CGFloat>()(a.m32));
      value = CKHashCombine(value, hash<CGFloat>()(a.m33));
      value = CKHashCombine(value, hash<CGFloat>()(a.m34));
      value = CKHashCombine(value, hash<CGFloat>()(a.m41));
      value = CKHashCombine(value, hash<CGFloat>()(a.m42));
      value = CKHashCombine(value, hash<CGFloat>()(a.m43));
      value = CKHashCombine(value, hash<CGFloat>()(a.m44));
      return CKHash64ToNative(value);
    }
  };

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
      using TypeForIndex = typename std::tuple_element<Index,Tuple>::type;
      size_t thisHash = CK::hash<TypeForIndex>()(std::get<Index>(tuple));
      return CKHash64ToNative(CKHashCombine(prev, thisHash));
    }
  };

  // Base case (hash 0th element)
  template <class Tuple>
  struct _hash_helper<Tuple, 0>
  {
    static size_t hash(Tuple const& tuple)
    {
      using TypeForIndex = typename std::tuple_element<0,Tuple>::type;
      return CK::hash<TypeForIndex>()(std::get<0>(tuple));
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
