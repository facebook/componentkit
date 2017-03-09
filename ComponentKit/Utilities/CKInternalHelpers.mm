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
#import <unordered_map>

#import "CKComponent.h"
#import "CKComponentController.h"
#import "CKComponentSubclass.h"
#import "CKMutex.h"

BOOL CKSubclassOverridesSelector(Class superclass, Class subclass, SEL selector) noexcept
{
  Method superclassMethod = class_getInstanceMethod(superclass, selector);
  Method subclassMethod = class_getInstanceMethod(subclass, selector);
  IMP superclassIMP = superclassMethod ? method_getImplementation(superclassMethod) : NULL;
  IMP subclassIMP = subclassMethod ? method_getImplementation(subclassMethod) : NULL;
  return (superclassIMP != subclassIMP);
}

Class CKComponentControllerClassFromComponentClass(Class componentClass) noexcept
{
  if (componentClass == [CKComponent class]) {
    return Nil; // Don't create root CKComponentControllers as it does nothing interesting.
  }

  static CK::StaticMutex mutex = CK_MUTEX_INITIALIZER; // protects cache
  CK::StaticMutexLocker l(mutex);

  static std::unordered_map<Class, Class> *cache = new std::unordered_map<Class, Class>();
  const auto &it = cache->find(componentClass);
  if (it == cache->end()) {
    Class c = NSClassFromString([NSStringFromClass(componentClass) stringByAppendingString:@"Controller"]);

    // If you override animationsFromPreviousComponent: or animationsOnInitialMount then we need a controller.
    if (c == nil &&
        (CKSubclassOverridesSelector([CKComponent class], componentClass, @selector(animationsFromPreviousComponent:)) ||
         CKSubclassOverridesSelector([CKComponent class], componentClass, @selector(animationsOnInitialMount)))) {
          c = [CKComponentController class];
        }

    cache->insert({componentClass, c});
    return c;
  }
  return it->second;
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
