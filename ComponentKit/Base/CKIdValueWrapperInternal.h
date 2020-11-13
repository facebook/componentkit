/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKDefines.h>

#if CK_NOT_SWIFT

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

using CKIdValueWrapperAssignerType = void (*)(void *location, void *const value);
using CKIdValueWrapperReleaserType = void (*)(void *const value);
using CKIdValueWrapperComparatorType = BOOL (*)(const void * lhs, const void * rhs);

/**
 CKIdValueWrapper allows to easily wrap a value type like a stuct in an `NSObject` subclass.
 This type should be interacted with through its C API.
 */
@interface CKIdValueWrapper : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
+ (instancetype)alloc NS_UNAVAILABLE;
+ (instancetype)allocWithZone:(struct _NSZone *)zone NS_UNAVAILABLE;

/// Shouldn't be used directly, see CKIdValueWrapperCreate()
- (instancetype)initWithValue:(void *const _Nullable )value
                     assigner:(CKIdValueWrapperAssignerType _Nullable)assigner
                     releaser:(CKIdValueWrapperReleaserType)releaser
                   comparator:(CKIdValueWrapperComparatorType _Nullable)comparator
                dataAlignment:(NSUInteger)dataAlignment NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly) void *data;

@end

CKIdValueWrapper *CKIdValueWrapperAlloc(NSUInteger extraBytes, NSUInteger alignOf) NS_RETURNS_RETAINED;

template <typename T>
void CKIdValueWrapperAssigner(void *location, void *const value) {
  new (location) T{std::move(*reinterpret_cast<T *const>(value))};
}

template <typename T>
BOOL CKIdValueWrapperComparator(const void *lhs, const void * rhs) {
  return *reinterpret_cast<const T *>(lhs) ==
    *reinterpret_cast<const T *>(rhs);
}

template <typename T>
void CKIdValueWrapperReleaser(void *const value) {
  reinterpret_cast<T *const>(value)->~T();
}

NS_ASSUME_NONNULL_END

#endif
