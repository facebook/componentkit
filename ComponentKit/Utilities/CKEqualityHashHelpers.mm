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

  size_t hash(const CGFloat &a) {
    return std::hash<CGFloat>()(a);
  };

  size_t hash(const CGPoint &a) {
    uint64_t value = 0;
    value = CKHashCombine(value, hash(a.x));
    value = CKHashCombine(value, hash(a.y));
    return CKHash64ToNative(value);
  };

  size_t hash(const CGSize &a) {
    uint64_t value = 0;
    value = CKHashCombine(value, hash(a.width));
    value = CKHashCombine(value, hash(a.height));
    return CKHash64ToNative(value);
  };

  size_t hash(const CGRect &a) {
    uint64_t value = 0;
    value = CKHashCombine(value, hash(a.origin));
    value = CKHashCombine(value, hash(a.size));
    return CKHash64ToNative(value);
  };

  size_t hash(const UIEdgeInsets &a) {
    uint64_t value = 0;
    value = CKHashCombine(value, hash(a.top));
    value = CKHashCombine(value, hash(a.left));
    value = CKHashCombine(value, hash(a.bottom));
    value = CKHashCombine(value, hash(a.right));
    return CKHash64ToNative(value);
  };

  size_t hash(const CGAffineTransform &a) {
    uint64_t value = 0;
    value = CKHashCombine(value, hash(a.a));
    value = CKHashCombine(value, hash(a.b));
    value = CKHashCombine(value, hash(a.c));
    value = CKHashCombine(value, hash(a.d));
    value = CKHashCombine(value, hash(a.tx));
    value = CKHashCombine(value, hash(a.ty));
    return CKHash64ToNative(value);
  };

  size_t hash(const CATransform3D &a) {
    uint64_t value = 0;
    value = CKHashCombine(value, hash(a.m11));
    value = CKHashCombine(value, hash(a.m12));
    value = CKHashCombine(value, hash(a.m13));
    value = CKHashCombine(value, hash(a.m14));
    value = CKHashCombine(value, hash(a.m21));
    value = CKHashCombine(value, hash(a.m22));
    value = CKHashCombine(value, hash(a.m23));
    value = CKHashCombine(value, hash(a.m24));
    value = CKHashCombine(value, hash(a.m31));
    value = CKHashCombine(value, hash(a.m32));
    value = CKHashCombine(value, hash(a.m33));
    value = CKHashCombine(value, hash(a.m34));
    value = CKHashCombine(value, hash(a.m41));
    value = CKHashCombine(value, hash(a.m42));
    value = CKHashCombine(value, hash(a.m43));
    value = CKHashCombine(value, hash(a.m44));
    return CKHash64ToNative(value);
  };

}
