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

#import <objc/runtime.h>

BOOL CKSubclassOverridesInstanceMethod(Class superclass, Class subclass, SEL selector) noexcept
{
  if (![subclass isSubclassOfClass:superclass]) {
    return NO;
  }
  Method superclassMethod = class_getInstanceMethod(superclass, selector);
  Method subclassMethod = class_getInstanceMethod(subclass, selector);
  IMP superclassIMP = superclassMethod ? method_getImplementation(superclassMethod) : NULL;
  IMP subclassIMP = subclassMethod ? method_getImplementation(subclassMethod) : NULL;
  if (superclassIMP == NULL) {
    return NO;
  }

  return (superclassIMP != subclassIMP);
}

BOOL CKSubclassOverridesClassMethod(Class superclass, Class subclass, SEL selector) noexcept
{
  if (![subclass isSubclassOfClass:superclass]) {
    return NO;
  }
  Method superclassMethod = class_getClassMethod(superclass, selector);
  Method subclassMethod = class_getClassMethod(subclass, selector);
  IMP superclassIMP = superclassMethod ? method_getImplementation(superclassMethod) : NULL;
  IMP subclassIMP = subclassMethod ? method_getImplementation(subclassMethod) : NULL;
  if (superclassIMP == NULL) {
    return NO;
  }

  return (superclassIMP != subclassIMP);
}

std::string CKStringFromPointer(const void *ptr) noexcept
{
  char buf[64];
  snprintf(buf, sizeof(buf), "%p", ptr);
  return buf;
}

CGFloat CKScreenScale() noexcept
{
  static CGFloat _scale;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _scale = [UIScreen mainScreen].scale;
  });
  return _scale;
}

CGFloat CKFloorPixelValue(CGFloat f) noexcept
{
  return floorf(f * CKScreenScale()) / CKScreenScale();
}

CGFloat CKCeilPixelValue(CGFloat f) noexcept
{
  return ceilf(f * CKScreenScale()) / CKScreenScale();
}

CGFloat CKRoundPixelValue(CGFloat f) noexcept
{
  return roundf(f * CKScreenScale()) / CKScreenScale();
}
