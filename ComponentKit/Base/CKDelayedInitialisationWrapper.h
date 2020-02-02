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

#pragma once

#include <new>
#include <type_traits>
#include <utility>

#import <ComponentKit/CKFatal.h>
#import <ComponentKit/CKOptional.h>

namespace CK {

/**
 * DelayedInitialisationWrapper is an object that allows to store a non-default
 * constructible object as a objective-c ivar. This object expects a value to
 * be set before being read and will assert if this is not the case. This object
 * can also be used to copy assign an object containing const members.
 *
 * Relies on CKOptional to hold the value.
 */
template <typename T>
struct DelayedInitialisationWrapper final {

 private:
  Optional<T> _value;

 public:
  template <typename... Args>
  void operator=(Args... args) {
    _value = std::forward<Args...>(args...);
  }

  auto get() const -> const T& {
    if (_value.hasValue() == false) {
      CKCFatal(@"Expecting value to be set");
    }
    return *_value.unsafeValuePtrOrNull();
  }

  operator const T&() const {
    return get();
  }

  auto get() -> T& {
    if (_value.hasValue() == false) {
      CKCFatal(@"Expecting value to be set");
    }
    return *_value.unsafeValuePtrOrNull();
  }

  operator T&() {
    return get();
  }

  // Can't return a reference to the optional storage since it stores T, not U.
  // Can't return a reference since this would be a reference to a stack allocated temporary of U.
  // => Return by value
  template <typename U, typename = std::enable_if_t<std::is_convertible<T, U>::value>>
  operator U() const {
    if (_value.hasValue() == false) {
      CKCFatal(@"Expecting value to be set");
    }
    return *_value.unsafeValuePtrOrNull();
  }
};

}

#endif
