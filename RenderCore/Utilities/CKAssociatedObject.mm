/*
*  Copyright (c) 2014-present, Facebook, Inc.
*  All rights reserved.
*
*  This source code is licensed under the BSD-style license found in the
*  LICENSE file in the root directory of this source tree. An additional grant
*  of patent rights can be found in the PATENTS file in the same directory.
*
*/

#import "CKAssociatedObject.h"

#import <objc/runtime.h>
#import <unordered_map>
#import <vector>

#import <RenderCore/CKAssert.h>
#import <RenderCore/CKGlobalConfig.h>

/**
 Since the only way to get notified when an object is deallocated is through associated object from
 objc/runtime, we need this observer to be associated with the object so that we can remove all
 associations when the object is deallocated.
 */
@interface CKObjectDeallocationObserver : NSObject

- (instancetype)initWithAddress:(uintptr_t)address;

@end

using KeyValue = std::pair<const void *, id>;
using AssociatedObjectMap = std::unordered_map<uintptr_t, std::vector<KeyValue>>;

static AssociatedObjectMap *CKMainThreadAffinedAssociatedObjectMap()
{
  CKCAssertMainThread();
  static AssociatedObjectMap *associatedObjectMap = new AssociatedObjectMap {};
  return associatedObjectMap;
}

static BOOL useCKAssociatedObject()
{
  static BOOL useCKAssociatedObject = CKReadGlobalConfig().useCKAssociatedObject;
  return useCKAssociatedObject;
}

id _Nullable CKGetAssociatedObject_MainThreadAffined(__unsafe_unretained id object,
                                                     const void *key)
{
  CKCAssertMainThread();
  if (!useCKAssociatedObject()) {
    return objc_getAssociatedObject(object, key);
  }
  const auto map = CKMainThreadAffinedAssociatedObjectMap();
  const auto it = map->find(uintptr_t(object));
  if (it == map->end()) {
    return nil;
  }
  const auto &keyValues = it->second;
  const auto rs = std::find_if(keyValues.begin(), keyValues.end(), [&](const auto &pair) {
    return std::get<0>(pair) == key;
  });
  if (rs == keyValues.end()) {
    return nil;
  }
  return std::get<1>(*rs);
}

static char CKObjectDeallocationObserverKey = ' ';

void CKSetAssociatedObject_MainThreadAffined(__unsafe_unretained id object,
                                             const void *key,
                                             __unsafe_unretained id _Nullable value)
{
  CKCAssertMainThread();
  if (!useCKAssociatedObject()) {
    objc_setAssociatedObject(object, key, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return;
  }
  const auto map = CKMainThreadAffinedAssociatedObjectMap();
  const auto address = (uintptr_t)object;
  const auto it = map->find(address);
  if (it == map->end()) {
    if (value != nil) {
      map->emplace(address, std::vector<KeyValue> {{key, value}});
      // Set associated object from objc/runtime so that we will get notified when `object` is deallocated.
      objc_setAssociatedObject(object,
                               &CKObjectDeallocationObserverKey,
                               [[CKObjectDeallocationObserver alloc] initWithAddress:address],
                               OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
  } else {
    auto &keyValues = it->second;
    const auto rs = std::find_if(keyValues.begin(), keyValues.end(), [&](const auto &pair) {
      return std::get<0>(pair) == key;
    });
    if (rs == keyValues.end()) {
      if (value != nil) {
        keyValues.push_back({key, value});
      }
    } else {
      if (value != nil) {
        *rs = {key, value};
      } else {
        keyValues.erase(rs);
      }
    }
  }
}

static void removeAllAssociatedObjects(uintptr_t address)
{
  CKCAssertMainThread();
  CKMainThreadAffinedAssociatedObjectMap()->erase(address);
}

@implementation CKObjectDeallocationObserver
{
  uintptr_t _address;
}

- (instancetype)initWithAddress:(uintptr_t)address
{
  if (self = [super init]) {
    _address = address;
  }
  return self;
}

- (void)dealloc
{
  CKAssert([NSThread isMainThread],
           @"Object that has `CKAssociatedObject` must be deallocated on main thread");
  removeAllAssociatedObjects(_address);
}

@end
