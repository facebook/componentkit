/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <RenderCore/CKDefines.h>

#if CK_NOT_SWIFT

#pragma once

#include <cstdlib>
#include <functional>
#include <new>
#include <type_traits>
#include <utility>

namespace CK {

template <typename>
struct PointerToMemberTraits;

template <typename R, typename T>
struct PointerToMemberTraits<R(T::*)> {
  using Self = T;
  using MemberType = R;
};

template <typename F>
using Self = typename PointerToMemberTraits<F>::Self;

template <typename F>
using MemberType = typename PointerToMemberTraits<F>::MemberType;

struct None {
  auto operator==(const None&) const -> bool {
    return true;
  }
};

/**
 Singleton empty value for all optionals.
 */
constexpr None none;

namespace OptionalDetail {
  template <unsigned ValueSize>
  struct HasValue {
    bool hasValue;
  };

  template <>
  struct HasValue<4> {
    uint32_t hasValue;
  };

  template <>
  struct HasValue<8> {
    uint64_t hasValue;
  };

  template <>
  struct HasValue<16> {
    uint64_t hasValue;
  };

  template <typename T, bool = std::is_trivially_destructible<T>::value, bool = std::is_trivially_copyable<T>::value, bool = std::is_default_constructible<T>::value>
  struct Storage: HasValue<sizeof(T)> {
    static constexpr auto HasValueSize = sizeof(HasValue<sizeof(T)>);

    union {
      char emptyState;
      T value;
    };

    Storage() : HasValue<sizeof(T)>{false} {}

    Storage(const Storage &other) : Storage() {
      if (other.hasValue) {
        construct(other.value);
      }
    }

    Storage(Storage &&other) : Storage() {
      if (other.hasValue) {
        construct(std::move(other.value));
        other.clear();
      }
    }

    auto operator =(const Storage &other) -> Storage & {
      if (other.hasValue) {
        if (this->hasValue) {
          value = other.value;
        } else {
          construct(other.value);
        }
      } else {
        clear();
      }
      return *this;
    }

    auto operator =(Storage &&other) -> Storage & {
      if (other.hasValue) {
        if (this->hasValue) {
          value = std::move(other.value);
        } else {
          construct(std::move(other.value));
          other.clear();
        }
      } else {
        clear();
      }
      return *this;
    }

    ~Storage() {
      clear();
    }

    void clear() {
      if (!this->hasValue) {
        return;
      }
      this->hasValue = false;
      value.~T();
    }

  private:
    template<typename U = T>
    void construct(U&& otherValue) {
      new (std::addressof(value)) T{std::forward<U>(otherValue)};
      this->hasValue = true;
    }
  };

  template <typename T>
  struct Storage<T, true /* is_trivially_destructible */, true /* is_trivially_copyable */, false /* is_default_constructible */> : HasValue<sizeof(T)> {
    static constexpr auto HasValueSize = sizeof(HasValue<sizeof(T)>);

    union {
      char emptyState;
      T value;
    };

    Storage() : HasValue<sizeof(T)>{false} {}
    Storage(const Storage &) = default;

    void clear() {
      this->hasValue = false;
    }
  };

  template <typename T>
  struct Storage<T, true, true, true>: HasValue<sizeof(T)> {
    static constexpr auto HasValueSize = sizeof(HasValue<sizeof(T)>);

    T value;

    constexpr Storage() : HasValue<sizeof(T)>{false}, value{} {}
    Storage(const Storage &) = default;

    void clear() {
      this->hasValue = false;
    }
  };
}

/**
 `Optional` class allows you to add an "empty state" value to any type `T`, similar to `nil` value for pointers.
 Instead of using an otherwise perfectly ordinary value to signify the absence of the value, like `NSNotFound` or
 `std::string::npos` or `-1`, `Optional` allows you to model this concept explicitly, without using any special values.
 `Optional` also makes sure that you don't forget to check for both cases and don't try to use the wrapped value when
 it's not there.

 Typical problems that are solved by using `Optional` include:

 - Inability to delay initialisation of types without the default constructor.

 - Having to resort to reference types / heap allocation to use `nil` as a sentinel.

 - Having to maintain a separate boolean flag that signifies the presence of a value.

 If you have function that takes an optional but you can't really do anything useful when this optional is empty,
 you should consider having an version that works with non-optional values instead. This simplifies code considerably:

     Optional<int> x = ...

     // Valid, but...
     auto f(Optional<int> i) -> Optional<string> {
       if (t == none) { return none; }
       ...
     }
     auto s = f(x);

     // ...better!
     auto f(int i) -> string { ... }
     auto s = x.map(f);

 In general, you should strive to have functions that take and return non-optional values and use these functions as
 arguments to map and have optionals usage confined to a limited number of call sites.
 */
template <typename T>
class Optional final {
  static_assert(!std::is_pointer<T>::value, "Pointers are already optional");

public:
  using ValueType = T;

  // Constructs an empty Optional
  Optional() noexcept {}
  Optional(const None&) noexcept {}

  // Constructs an Optional that contains a value
  template <typename U = ValueType, typename = std::enable_if_t<std::is_convertible<U, T>::value>>
  Optional(U&& value) noexcept {
    construct(std::forward<U>(value));
  }

  Optional(const Optional &) = default;
  Optional(Optional &&) = default;

  auto operator=(None) noexcept -> Optional& {
    clear();
    return *this;
  }

  template <typename U = ValueType, typename = std::enable_if_t<std::is_convertible<U, T>::value>>
  auto operator=(U&& value) -> Optional& {
    assign(std::forward<U>(value));
    return *this;
  }

  auto operator=(const Optional&) -> Optional& = default;
  auto operator=(Optional&&) -> Optional& = default;

  auto hasValue() const noexcept -> bool {
    return _storage.hasValue;
  }

  /**
   The foundational operation which allows you to get the access to the wrapped value. You should consider using other
   operations such as `map`, `valueOr` or `apply` first since they handle the most common use cases in a more concise
   manner.

   You pass the two callable objects to the match() function, where the first one will be called with the wrapped value
   if it's there and the second one will be called if the optional is empty:

       Optional<T> x = ...
       x.match(
       [](const T &t){
         // Always have a valid T here
         useT(t);
       },
       [](){
         // No T, handle it
       }
       );

   You can notice that there are certain similarities to switch statement. However, unlike switch, match() is an
   *expression*, so your handlers can return a value (both must return the same type).

   Note: "callable objects" here include but are not limited to lambdas. These can also be Objective C blocks,
   function pointers, function-like objects (that override operator ()).

   @param vm  function-like object that will be invoked if the Optional contains the value.
   @param nm  function-like object that will be invoked if the Optional is empty.

   @return The return value of invoking vm with the wrapped value if the Optional is not empty, or the return value
   of invoking nm otherwise.
   */
  template <typename ValueMatcher, typename NoneMatcher>
  auto match(ValueMatcher&& vm, NoneMatcher&& nm) const&
  -> decltype(vm(std::declval<T>())) {
    if (hasValue()) {
      return vm(forceUnwrap());
    }
    return nm();
  }

  template <typename ValueMatcher, typename NoneMatcher>
  auto match(ValueMatcher&& vm, NoneMatcher&& nm) &
  -> decltype(vm(std::declval<T &>())) {
    if (hasValue()) {
      return vm(forceUnwrap());
    }
    return nm();
  }

  template <typename ValueMatcher, typename NoneMatcher>
  auto match(ValueMatcher&& vm, NoneMatcher&& nm) &&
  -> decltype(vm(std::declval<T>())) {
    if (hasValue()) {
      return vm(std::move(*this).forceUnwrap());
    }
    return nm();
  }

  /**
   Same as `match` but for cases when you want to perform a side-effect instead of returning a value, e.g.:

       auto v = std::vector<int> {};

       x.apply([&](const int &x){
         v.push_back(x);
       });

   @param vm  function-like object that will be invoked if the Optional contains the value.

   Note: you are not allowed to return anything from value handler in apply.
   */
  template <typename ValueMatcher>
  auto apply(ValueMatcher&& vm) const& -> void {
    match(std::forward<ValueMatcher>(vm), []() {});
  }

  template <typename ValueMatcher>
  auto apply(ValueMatcher&& vm) & -> void {
    match(std::forward<ValueMatcher>(vm), []() {});
  }

  template <typename ValueMatcher>
  auto apply(ValueMatcher&& vm) && -> void {
    std::move(*this).match(std::forward<ValueMatcher>(vm), []() {});
  }

  /**
   Transforms a value wrapped inside the Optional, e.g.:

       auto area(rect: CGRect) -> CGFloat;
       Optional<CGRect> r = ...
       Optional<CGFloat> a = r.map(area);

   @param f function-like object that will be invoked if the Optional contains the value.

   @return A new Optional that wraps the result of calling `f` with the wrapped value if the Optional was not empty, or
   an empty Optional otherwise.
   */
  template <typename F>
  auto map(F&& f) const -> Optional<decltype(f(std::declval<T>()))> {
    using U = decltype(f(std::declval<T>()));
    return match(
                 [&](const T& value) { return Optional<U>{f(value)}; },
                 []() { return Optional<U>{}; });
  }

  /**
   Transforms a value wrapped inside the Optional, e.g.:

   Optional<CGRect> r = ...
   Optional<CGFloat> w = r.map(&CGRect::width);

   @param f pointer-to-member function that will be invoked if the Optional contains the value.

   @return A new Optional that wraps the result of calling `f` with the wrapped value if the Optional was not empty, an
   empty Optional otherwise.
   */
  template <typename F>
  auto map(F&& f) const -> Optional<MemberType<F>> {
    using U = MemberType<F>;
    return match(
                 [&](const T& value) { return Optional<U>{value.*f}; },
                 []() { return Optional<U>{}; });
  }

  /**
   Transforms a value wrapped inside the Optional, e.g.:

   @code
   auto toNSString(int x) -> NSString *;
   Optional<int> x = ...
   NSString *s = x.mapToPtr(toNSString); // nil if the x was empty

   @param f function-like object that will be invoked if the Optional contains the value. Must return a pointer type.

   @return The result of calling `f` with the wrapped value if the Optional was not empty, or a null pointer otherwise.
   */
  template <typename F>
  auto mapToPtr(F&& f) const -> decltype(f(std::declval<T>())) {
    return match(
                 [&](const T& value) { return f(value); }, []() { return nullptr; });
  }

  /**
   Transforms a value wrapped inside the Optional, e.g.:

   @code
   Optional<Props> x = ...
   NSString *s = x.mapToPtr(&Props::title); // nil if the x was empty

   @param f pointer-to-member function that will be invoked if the Optional contains the value.

   @return The result of calling `f` with the wrapped value if the Optional was not empty, or a null pointer otherwise.
   */
  template <typename F>
  auto mapToPtr(F&& f) const -> MemberType<F> {
    return match(
                 [&](const T& value) { return value.*f; }, []() { return nullptr; });
  }

  /**
   Transforms a value wrapped inside the Optional using a function that itself returns an Optional, "flattening" the
   final result, e.g.:

       // Not all strings can be converted to integers
       auto toInt(const std::string& s) -> Optional<int>;
       Optional<std::string> s = ...
       Optional<int> = s.flatMap(toInt); // Not Optional<Optional<int>>!

   @param f function-like object that will be invoked if the Optional contains the value.

   @return The result of calling `f` with the wrapped value if the Optional was not empty, or an empty Optional otherwise.
   */
  template <typename F>
  auto flatMap(F&& f) const
  -> Optional<typename decltype(f(std::declval<T>()))::ValueType> {
    return match(
                 [&](const T& value) { return f(value); }, []() {
                   return Optional<typename decltype(f(std::declval<T>()))::ValueType>{};
                 });
  }

  /**
   Transforms a value wrapped inside the Optional using a function that itself returns an Optional, "flattening" the
   final result, e.g.:

   struct HasOptional {
     Optional<int> x;
   };
   Optional<HasOptional> a = HasOptional { 123 };
   Optional<int> x = a.flatMap(&HasOptional::x); // Not Optional<Optional<int>>!

   @param f pointer-to-member function that will be invoked if the Optional contains the value.

   @return The result of calling `f` with the wrapped value if the Optional was not empty, or an empty Optional otherwise.
   */
  template <typename F>
  auto flatMap(F&& f) const -> Optional<typename MemberType<F>::ValueType> {
    using U = typename MemberType<F>::ValueType;
    return match(
                 [&](const T& value) { return Optional<U>{value.*f}; },
                 []() { return Optional<U>{}; });
  }

  /**
   Substitutes a default value in case the optional is empty.

   @param dflt  default non-optional value to substitute.

   @return The value wrapped in the Optional if it is not empty, or the default value otherwise.
   */
  auto valueOr(const T& dflt) const& -> T {
    return match([](const T& value) { return value; }, [&]() { return dflt; });
  }

  auto valueOr(T&& dflt) const& -> T {
    return match(
                 [](const T& value) { return value; },
                 [&]() { return std::forward<T>(dflt); });
  }

  auto valueOr(const T& dflt) && -> T {
    return std::move(*this).match(
                 [](T&& value) { return std::move(value); },
                 [&]() { return dflt; });
  }

  auto valueOr(T&& dflt) && -> T {
    return std::move(*this).match(
                 [](T&& value) { return std::move(value); },
                 [&]() { return std::forward<T>(dflt); });
  }

  /**
   Substitutes a default value in case the optional is empty. The callable argument is only invoked when the optional is
   empty. Use this variant of `valueOr` when the computation of the default value is expensive or has side effects.

   @param defaultProvider  a function-like object that takes no arguments and returns a default non-optional value to
                           substitute.

   @return The value wrapped in the Optional if it is not empty, or the default value otherwise.
   */
  template <typename F, typename = std::enable_if_t<std::is_convertible<F, std::function<T()>>::value>>
  auto valueOr(F&& defaultProvider) const& -> T {
    return match([](const T& value) { return value; }, defaultProvider);
  }

  template <typename F, typename = std::enable_if_t<std::is_convertible<F, std::function<T()>>::value>>
  auto valueOr(F&& defaultProvider) && -> T {
    return std::move(*this).match([](T&& value) { return std::move(value); }, defaultProvider);
  }

  /**
   ** Advanced API, Tread with Caution **

   You can use a more concise syntax for getting access to the wrapped value using unsafeValuePtrOrNull:

       Optional<T> x = ...

       if (auto t = a.unsafeValuePtrOrNull()) {
         // Always have a pointer to valid T here
       } else {
         // No T, handle it
       }

   The constness of `x` here will be propagated to `t` (i.e. if `x` were `const Optional<T>`, `t` would be `const T *`;
   in the example the type of `t` is just `T *`).

   @note `unsafeValuePtrOrNull()` doesn't work for rvalues (because the Optional will be destroyed at the end of
   expression and you'll be left with a dangling pointer), so the following won't compile:

       if (auto t = getOptional().unsafeValuePtrOrNull()) { ... }

   @note `unsafeValuePtrOrNull()` returns a nullable unmanaged pointer to the Optional's storage. The usual safety
   rules about such pointers apply.
   */
  auto unsafeValuePtrOrNull() const& -> const ValueType* {
    return _storage.hasValue ? &_storage.value : nullptr;
  }

  auto unsafeValuePtrOrNull() & -> ValueType* {
    return _storage.hasValue ? &_storage.value : nullptr;
  }

  auto unsafeValuePtrOrNull() && -> ValueType* = delete;

private:
  template <typename U>
  friend auto operator==(
                         const Optional<U>& lhs,
                         const Optional<U>& rhs) noexcept -> bool;

  void construct(const T& value) {
    new (std::addressof(_storage.value)) T{value};
    _storage.hasValue = true;
  }

  void construct(T&& value) {
    new (std::addressof(_storage.value)) T{std::move(value)};
    _storage.hasValue = true;
  }

  template <typename U = ValueType, typename = std::enable_if_t<std::is_convertible<U, T>::value>>
  void assign(U&& newValue) {
    if (hasValue()) {
      _storage.value = std::forward<U>(newValue);
    } else {
      construct(std::forward<U>(newValue));
    }
  }

  const T& forceUnwrap() const& {
    requireValue();
    return _storage.value;
  }

  T& forceUnwrap() & {
    requireValue();
    return _storage.value;
  }

  T&& forceUnwrap() && {
    requireValue();
    return std::move(_storage.value);
  }

  void requireValue() const {
    if (!_storage.hasValue) {
      abort();
    }
  }

  void clear() noexcept {
    _storage.clear();
  }

  OptionalDetail::Storage<T> _storage;
};


/**
 Running apply function on multiple optionals, where the provided function will
 only be executed if all the passed optionals are not none

 auto v = std::vector<int> {};

 apply([&](const int &x, const int &y){
 v.push_back(x);
 v.push_back(y);
 }, x, y);

 Note: you are not allowed to return anything from value handler in apply.
 */
template <typename F, typename T, typename S>
auto apply(F &&f, const Optional<T> &opt1, const Optional<S> &opt2) -> void {
  opt1.apply([&](const T &value1){
    opt2.apply([&](const S &value2){
      f(value1, value2);
    });
  });
}

/**
 Running apply function on multiple optionals, where the provided function will
 only be executed if all the passed optionals are not none

 auto v = std::vector<int> {};

 apply([&](const int &x, const int &y, const int &z){
 v.push_back(x);
 v.push_back(y);
 v.push_back(z);
 }, x, y, z);

 Note: you are not allowed to return anything from value handler in apply.
 */
template <typename F, typename T, typename S, typename... Ts>
auto apply(F &&f, const Optional<T> &opt1, const Optional<S> &opt2, const Optional<Ts> &... opts) -> void {
  opt1.apply([&](const T &value1){
    apply([&](const S &value2, Ts... ts){ f(value1, value2, ts...); }, opt2, opts...);
  });
}

/**
 You can compare Optionals of the same type:

 - Empty optionals are equal to each other
 - An empty optional is never equal to the one that has a value
 - If both optionals have values, the values are checked for equality.
 */
template <typename U>
auto operator==(const Optional<U>& lhs, const Optional<U>& rhs) noexcept
-> bool {
  if (lhs.hasValue() != rhs.hasValue()) {
    return false;
  }
  if (lhs.hasValue()) {
    return lhs.forceUnwrap() == rhs.forceUnwrap();
  }
  return true;
}

template <typename T>
auto operator!=(const Optional<T>& lhs, const Optional<T>& rhs) noexcept
-> bool {
  return !(lhs == rhs);
}

/**
 You can compare optionals to values of the corresponding type directly:

     Optional<int> x = ...
     x == 2

 This return true iff x has a value and it is equal to 2.
 */

template <typename T>
auto operator==(const Optional<T>& lhs, const T& rhs) noexcept -> bool {
  return lhs.map([&](const T& value) { return value == rhs; }).valueOr(false);
}

template <typename T>
auto operator!=(const Optional<T>& lhs, const T& rhs) noexcept -> bool {
  return !(lhs == rhs);
}

template <typename T>
auto operator==(const T& lhs, const Optional<T>& rhs) noexcept -> bool {
  return rhs.map([&](const T& value) { return value == lhs; }).valueOr(false);
}

template <typename T>
auto operator!=(const T& lhs, const Optional<T>& rhs) noexcept -> bool {
  return !(lhs == rhs);
}

/**
 You can also compare optionals with `none` which is equivalent to calling `hasValue`.
 */

template <typename T>
auto operator==(const Optional<T>& lhs, None) noexcept -> bool {
  return !lhs.hasValue();
}

template <typename T>
auto operator!=(const Optional<T>& lhs, None) noexcept -> bool {
  return lhs.hasValue();
}

template <typename T>
auto operator==(None, const Optional<T>& rhs) noexcept -> bool {
  return !rhs.hasValue();
}

template <typename T>
auto operator!=(None, const Optional<T>& rhs) noexcept -> bool {
  return rhs.hasValue();
}

} // namespace CK

#endif
