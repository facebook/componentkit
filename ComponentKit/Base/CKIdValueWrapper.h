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

#import <ComponentKit/CKIdValueWrapperInternal.h>

#include <type_traits>
#include <memory>
#include <new>

NS_ASSUME_NONNULL_BEGIN

/**
 * CKIdValueWrapper is useful to wrap a value type (cpp struct / class) as an `id`.
 * Unlike NSValue the copy semantics will be preserved and thus arc pointers will
 * be handled correctly.
 *
 * Usage:
 *
 * CKIdValueWrapper *const wrapper = CKIdValueWrapperCreate<int>(42); // create object
 * int& value = CKIdValueWrapperGet<int>(wrapper); // access value
 * value = 44; // update value
 */


/**
 * Returns a ref to the wrapped value. Passing the wrong type will result in a crash.
 * Use carefuly.
 *
 * The returned reference will be valid for as long as object lives.
 */
template <typename T>
T& CKIdValueWrapperGet(__unsafe_unretained CKIdValueWrapper *object) {
  return *reinterpret_cast<T *>(object.data);
}

/**
 * Creates a new wrapper from an equatable value of type T.
 *
 * For this function to work, T needs to implement `operator==()`.
 * If not, see `CKIdValueWrapperCustomComparatorCreate` or
 * `CKIdValueWrapperNonEquatableCreate`.
 */
template <typename T>
CKIdValueWrapper *CKIdValueWrapperCreate(T value) NS_RETURNS_RETAINED {
  using TType = std::decay_t<T>;

  // Override alloc to allocate our classes with the additional storage
  // required for the instance variables.
  CKIdValueWrapper *object = CKIdValueWrapperAlloc(/* extra bytes */sizeof(TType), alignof(TType));
  return [object initWithValue:&value
                      assigner:&CKIdValueWrapperAssigner<TType>
                      releaser:&CKIdValueWrapperReleaser<TType>
                    comparator:&CKIdValueWrapperComparator<TType>
                 dataAlignment:alignof(TType)];
}

/**
 * Creates a new wrapper from a equatable value of type T through
 * a custom comparator function.
 *
 * If the type isn't equatable at all - see `CKIdValueWrapperNonEquatableCreate`.
 */
template <typename T>
CKIdValueWrapper *CKIdValueWrapperCustomComparatorCreate(T value, BOOL (*comparator)(const T&, const T&)) NS_RETURNS_RETAINED {
  using TType = std::decay_t<T>;

  // Override alloc to allocate our classes with the additional storage
  // required for the instance variables.
  CKIdValueWrapper *object = CKIdValueWrapperAlloc(/* extra bytes */sizeof(TType), alignof(TType));
  return [object initWithValue:&value
                      assigner:&CKIdValueWrapperAssigner<TType>
                      releaser:&CKIdValueWrapperReleaser<TType>
                    comparator:(CKIdValueWrapperComparatorType)comparator
                 dataAlignment:alignof(TType)];
}

/**
 * Creates a new wrapper from a non equatable value of type T.
 */
template <typename T>
CKIdValueWrapper *CKIdValueWrapperNonEquatableCreate(T value) NS_RETURNS_RETAINED {
  using TType = std::decay_t<T>;

  // Override alloc to allocate our classes with the additional storage
  // required for the instance variables.
  CKIdValueWrapper *object = CKIdValueWrapperAlloc(/* extra bytes */sizeof(TType), alignof(TType));
  return [object initWithValue:&value
                      assigner:&CKIdValueWrapperAssigner<TType>
                      releaser:&CKIdValueWrapperReleaser<TType>
                    comparator:nullptr
                 dataAlignment:alignof(TType)];
}

NS_ASSUME_NONNULL_END

#endif
