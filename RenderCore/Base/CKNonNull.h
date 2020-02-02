/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#pragma once

#import <RenderCore/CKDefines.h>

#if CK_NOT_SWIFT

#import <RenderCore/CKAssert.h>

namespace CK {

template <typename> class RelaxedNonNull;
template <typename> class NonNull;

namespace NonNullDetail {
template <typename> struct IsNonNull: public std::false_type {};
template <typename Ptr> struct IsNonNull<RelaxedNonNull<Ptr>>: public std::true_type {};
template <typename Ptr> struct IsNonNull<NonNull<Ptr>>: public std::true_type {};
} // NonNullDetail

template <typename Ptr>
class RelaxedNonNull {
public:
  static_assert(!NonNullDetail::IsNonNull<Ptr>::value, "Pointer is already non-null");

  RelaxedNonNull(const Ptr &ptr) :_ptr(ptr) { CKCAssertNotNil(_ptr, @"The pointer can't be nil"); }
  RelaxedNonNull(Ptr &&ptr) :_ptr(ptr) { CKCAssertNotNil(_ptr, @"The pointer can't be nil"); }

  template <typename OtherPtr, typename = std::enable_if_t<std::is_convertible<OtherPtr, Ptr>::value>>
  RelaxedNonNull(const RelaxedNonNull<OtherPtr> &ptr) :_ptr(ptr.operator OtherPtr()) {}

  // Disallow assignment from nullable
  auto operator =(const Ptr &) -> RelaxedNonNull & = delete;

  // Implicit conversion to nullable
  template <typename U, typename = std::enable_if_t<std::is_convertible<Ptr, U>::value>>
  operator U () const & { return _ptr; }
  operator Ptr &&() && { return std::move(_ptr); }

  // Passthrough
  Ptr operator ->() const { return _ptr; }
  Ptr operator *() const { return _ptr; }

  template <typename... Args>
  auto operator ()(Args &&... args) const { return _ptr(std::forward<Args>(args)...); }

  // Disallow conversion to bool
  operator bool () const = delete;

  // Disallow nil literals
  RelaxedNonNull(std::nullptr_t) = delete;

  template <typename L, typename R>
  friend auto operator ==(const RelaxedNonNull<L> &, const RelaxedNonNull<R> &) -> bool;

private:
  Ptr _ptr;
};

template <typename L, typename R>
auto operator ==(const RelaxedNonNull<L> &lhs, const RelaxedNonNull<R> &rhs) -> bool
{
  return lhs._ptr == rhs._ptr;
}

template <typename L, typename R>
auto operator !=(const RelaxedNonNull<L> &lhs, const RelaxedNonNull<R> &rhs) -> bool
{
  return !(lhs == rhs);
}

template <typename Ptr>
auto operator ==(const RelaxedNonNull<Ptr> &lhs, std::nullptr_t rhs) -> bool = delete;
template <typename Ptr>
auto operator !=(const RelaxedNonNull<Ptr> &lhs, std::nullptr_t rhs) -> bool = delete;

template <typename Ptr>
class NonNull final: public RelaxedNonNull<Ptr> {
public:
  // Explicit construction from nullable
  explicit NonNull(const Ptr &ptr) : RelaxedNonNull<Ptr>{ptr} {}
  explicit NonNull(Ptr &&ptr) : RelaxedNonNull<Ptr>{std::move(ptr)} {}

  template <typename OtherPtr, typename = std::enable_if_t<std::is_convertible<OtherPtr, Ptr>::value>>
  NonNull(const NonNull<OtherPtr> &ptr) : RelaxedNonNull<Ptr>{ptr} {}

  template <typename OtherPtr, typename = std::enable_if_t<std::is_convertible<OtherPtr, Ptr>::value>>
  NonNull(const RelaxedNonNull<OtherPtr> &ptr) : RelaxedNonNull<Ptr>{ptr} {}

  // Disallow nil literals
  NonNull(std::nullptr_t) = delete;
};

template <typename Ptr>
auto makeNonNull(Ptr p) { return NonNull<Ptr>{std::move(p)}; }

} // namespace CK

#endif
