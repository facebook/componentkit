/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKInternalHelpers.h"

#import <functional>
#import <objc/runtime.h>
#import <stdio.h>
#import <string>

BOOL CKSubclassOverridesSelector(Class superclass, Class subclass, SEL selector)
{
  Method superclassMethod = class_getInstanceMethod(superclass, selector);
  Method subclassMethod = class_getInstanceMethod(subclass, selector);
  IMP superclassIMP = superclassMethod ? method_getImplementation(superclassMethod) : NULL;
  IMP subclassIMP = subclassMethod ? method_getImplementation(subclassMethod) : NULL;
  return (superclassIMP != subclassIMP);
}

std::string CKStringFromPointer(const void *ptr)
{
  char buf[64];
  snprintf(buf, sizeof(buf), "%p", ptr);
  return buf;
}


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

/*
 * Thomas Wang downscaling hash function
 */

inline uint32_t twang_32from64(uint64_t key) {
  key = (~key) + (key << 18);
  key = key ^ (key >> 31);
  key = key * 21;
  key = key ^ (key >> 11);
  key = key + (key << 6);
  key = key ^ (key >> 22);
  return (uint32_t) key;
}

NSUInteger CKIntegerArrayHash(const NSUInteger *subhashes, NSUInteger count)
{
  uint64_t result = subhashes[0];
  for (int ii = 1; ii < count; ++ii) {
    result = CKHashCombine(result, subhashes[ii]);
  }
#if __LP64__
  return result;
#else
  return twang_32from64(result);
#endif
}

CGFloat CKScreenScale()
{
  static CGFloat _scale;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _scale = [UIScreen mainScreen].scale;
  });
  return _scale;
}

CGFloat CKFloorPixelValue(CGFloat f)
{
  return floorf(f * CKScreenScale()) / CKScreenScale();
}

CGFloat CKCeilPixelValue(CGFloat f)
{
  return ceilf(f * CKScreenScale()) / CKScreenScale();
}

CGFloat CKRoundPixelValue(CGFloat f)
{
  return roundf(f * CKScreenScale()) / CKScreenScale();
}
