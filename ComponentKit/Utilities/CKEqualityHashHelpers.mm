/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKEqualityHashHelpers.h"

#import <functional>
#import <objc/runtime.h>
#import <stdio.h>
#import <string>

NSUInteger CKIntegerArrayHash(const NSUInteger *subhashes, NSUInteger count)
{
  uint64_t result = subhashes[0];
  for (int ii = 1; ii < count; ++ii) {
    result = CKHashCombine(result, subhashes[ii]);
  }
  return CKHash64ToNative(result);
}

namespace CK {

  size_t hash<CGPoint>::operator()(const CGPoint &a)
  {
    uint64_t value = 0;
    value = CKHashCombine(value, hash<CGFloat>()(a.x));
    value = CKHashCombine(value, hash<CGFloat>()(a.y));
    return CKHash64ToNative(value);
  }

  size_t hash<CGSize>::operator()(const CGSize &a)
  {
    uint64_t value = 0;
    value = CKHashCombine(value, hash<CGFloat>()(a.width));
    value = CKHashCombine(value, hash<CGFloat>()(a.height));
    return CKHash64ToNative(value);
  }

  size_t hash<CGRect>::operator()(const CGRect &a)
  {
    uint64_t value = 0;
    value = CKHashCombine(value, hash<CGPoint>()(a.origin));
    value = CKHashCombine(value, hash<CGSize>()(a.size));
    return CKHash64ToNative(value);
  }
  size_t hash<UIEdgeInsets>::operator()(const UIEdgeInsets &a)
  {
    uint64_t value = 0;
    value = CKHashCombine(value, hash<CGFloat>()(a.top));
    value = CKHashCombine(value, hash<CGFloat>()(a.left));
    value = CKHashCombine(value, hash<CGFloat>()(a.bottom));
    value = CKHashCombine(value, hash<CGFloat>()(a.right));
    return CKHash64ToNative(value);
  }
  size_t hash<CGAffineTransform>::operator()(const CGAffineTransform &a)
  {
    uint64_t value = 0;
    value = CKHashCombine(value, hash<CGFloat>()(a.a));
    value = CKHashCombine(value, hash<CGFloat>()(a.b));
    value = CKHashCombine(value, hash<CGFloat>()(a.c));
    value = CKHashCombine(value, hash<CGFloat>()(a.d));
    value = CKHashCombine(value, hash<CGFloat>()(a.tx));
    value = CKHashCombine(value, hash<CGFloat>()(a.ty));
    return CKHash64ToNative(value);
  }
  size_t hash<CATransform3D>::operator()(const CATransform3D &a)
  {
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

  bool is_equal<CGAffineTransform>::operator ()(const CGAffineTransform &a, const CGAffineTransform &b)
  {
    return (is_equal<CGFloat>()(a.a, b.a) &&
            is_equal<CGFloat>()(a.b, b.b) &&
            is_equal<CGFloat>()(a.c, b.c) &&
            is_equal<CGFloat>()(a.d, b.d) &&
            is_equal<CGFloat>()(a.tx, b.tx) &&
            is_equal<CGFloat>()(a.ty, b.ty));
  }

  bool is_equal<CATransform3D>::operator ()(const CATransform3D &a, const CATransform3D &b)
  {
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

}
