// Copyright 2004-present Facebook. All Rights Reserved.

#import <RenderCore/CKDefines.h>

#if CK_NOT_SWIFT

#include <utility>

/**
 CKRequired<T> uses the compiler to enforce definition of a struct member (primitives, pointers, or objects).

 Internally, we use an implicit constructor without a default, so there has to be an initial value.

 Usage:
 @code
 struct S {
 CKRequired<int> i;
 CKRequired<NSString *> str;
 NSString *optionalStr;
 };

 S options = {
 .i = 0,                // warning if omitted
 .str = @"Hello World", // warning if omitted
 };
 @endcode
 */
template <typename T>
struct CKRequired {
  /// Pass-through constructor (allows for implicit conversion) for wrapped type T
  template<typename... Args>
  CKRequired(Args&&... args): _t(std::forward<Args>(args)...) {
    static_assert(sizeof...(Args) > 0, "Required struct member not initialized. Expand assert trace to see where this was triggered.");
  }

  /// Public accessor for private storage (Use when implicit conversion is impracticable)
  T get() const { return _t; }

  // Implicit conversion
  operator T() const { return _t; }
  operator T&() { return _t; }

private:
  T _t;
};

#endif
