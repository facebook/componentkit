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

#include <array>
#include <cassert>
#include <new>
#include <tuple>
#include <type_traits>
#include <utility>
#include <functional>

namespace CK {

template <typename... Types> class Variant;

namespace VariantDetail {

#pragma mark - Typelist

/**
 Represents a list of types known at compile-time, e.g. \code Typelist<bool, short, int> \endcode
 */
template <typename... Elements> class Typelist {};

#pragma mark - IsEmpty

/**
 A meta-function that determines if a given typelist is empty.

 \code
 IsEmpty<Typelist<bool, short, int>>::value == false
 IsEmpty<Typelist<>>::value == true
 \endcode
 */
template <typename List> class IsEmpty {
 public:
  static constexpr auto value = false;
};

template <> class IsEmpty<Typelist<>> {
 public:
  static constexpr auto value = true;
};

#pragma mark - Front

template <typename List> class FrontT;

template <typename Head, typename... Tail> class FrontT<Typelist<Head, Tail...>> {
 public:
  using Type = Head;
};

/**
 A meta-function returning the first element of a typelist.

 \code
 using T = Front<Typelist<bool, short, int>>; // T == bool
 \endcode
 */
template <typename List> using Front = typename FrontT<List>::Type;

#pragma mark - PopFront

template <typename List> class PopFrontT;

template <typename Head, typename... Tail> class PopFrontT<Typelist<Head, Tail...>> {
 public:
  using Type = Typelist<Tail...>;
};

/**
 A meta-function that removes the first element from the typelist.

 \code
 using Ts = PopFront<Typelist<bool, short, int>>; // T == Typelist<short, int>
 \endcode
 */
template <typename List> using PopFront = typename PopFrontT<List>::Type;

#pragma mark - LargestType

template <typename List, bool Empty = IsEmpty<List>::value> class LargestTypeT;

template <typename List> class LargestTypeT<List, false> {
 private:
  using Contender = Front<List>;
  using Best = typename LargestTypeT<PopFront<List>>::Type;

 public:
  using Type = std::conditional_t<sizeof(Contender) >= sizeof(Best), Contender, Best>;
};

template <typename List> class LargestTypeT<List, true> {
 public:
  using Type = char;  // Guaranteed not to be larger than any other type.
};

/**
 A meta-function returning the largest type in a typelist.

 \code
 using T = LargestType<Typelist<bool, short, int>>; // T == int
 \endcode
 */
template <typename List> using LargestType = typename LargestTypeT<List>::Type;

#pragma mark - NthElement

template <typename List, unsigned N> class NthElementT : public NthElementT<PopFront<List>, N - 1> {};

template <typename List> class NthElementT<List, 0> : public FrontT<List> {};

/**
 A meta-function returning the Nth element of a typelist.

 \code
 using T = NthElement<Typelist<bool, short, int>, 1>; // T == short
 \endcode
 */
template <typename List, unsigned N> using NthElement = typename NthElementT<List, N>::Type;

#pragma mark - FindIndexOf

constexpr auto notFound = std::numeric_limits<std::size_t>::max();
constexpr auto ambiguous = std::numeric_limits<std::size_t>::max() - 1;

/**
 Returns an index for type \c T in a template parameter pack \c Ts.

 \code
 auto i = findIndexImpl<short, bool, short, int>(); // i == 1
 \endcode

 This function should not be used directly. Consider using the \c IndexOfT meta-function instead.

 \return  The index of \c T in \c Ts if it occurs only once; \c ambiguous if \c T occurs more than once or \c notFound
 if \c T was not found.
 */
template <typename T, typename... Ts> constexpr auto findIndexImpl() -> std::size_t
{
  // For T == short and Ts == {bool, short, int}, this array would be {false, true, false}
  constexpr auto matches = std::array<bool, sizeof...(Ts)>{{std::is_same<T, Ts>::value...}};

  auto result = notFound;
  for (std::size_t i = 0; i < sizeof...(Ts); i++) {
    if (matches[i]) {
      if (result != notFound) {
        result = ambiguous;
      }
      result = i;
    }
  }
  return result;
}

template <std::size_t Index> struct FindIndexChecked : std::integral_constant<std::size_t, Index> {
  static_assert(Index != notFound, "The specified type is not found");
  static_assert(Index != ambiguous, "The specified type is ambiguous");
};

/**
 A meta-function returning an index for type \c T in a template parameter pack \c Ts.
 */
template <typename T, typename... Ts> using IndexOfT = FindIndexChecked<findIndexImpl<T, Ts...>()>;

#pragma mark - VariantStorage

/**
 Class responsible for providing storage big enough to accomodate any alternative from \c Types and tracks the currently
 active alternative using a discriminator.
 */
template <typename... Types> class VariantStorage {
 public:
  auto getDiscriminator() const -> unsigned
  {
    return _discriminator;
  }

  auto setDiscriminator(unsigned d) -> void
  {
    _discriminator = d;
  }

  auto getRawBuffer() -> void *
  {
    return _buffer;
  }

  auto getRawBuffer() const -> const void *
  {
    return _buffer;
  }

  template <typename T> auto getBufferAs() -> T *
  {
    // std::launder()
    return reinterpret_cast<T *>(_buffer);
  }

  template <typename T> auto getBufferAs() const -> T const *
  {
    // std::launder()
    return reinterpret_cast<T const *>(_buffer);
  }

 private:
  using LargestT = LargestType<Typelist<Types...>>;
  alignas(Types...) unsigned char _buffer[sizeof(LargestT)];
  unsigned _discriminator = 0;
};

#pragma mark - VariantChoice

/**
 Class responsible for handling a particular alternative \c T in a variant.

 \discussion
 The handling includes:

 \li – Construction and assignment from values of \c T
 \li – Destruction of values of \c T
 \li – Assigning the value for the alternative \em discriminator (see \c VariantStorage )

 The non-type template parameter \c N is a \em reverse index of the alternative in the \c Types parameter pack, i.e. for

 \code Types == {bool, short, int} \endcode

 a \c VariantChoice corresponding to \c bool would be

 \code VariantChoice<3, bool, short, int> \endcode

 The reverse index is being used so the terminating condition for the recursive inheritance (see below) does not depend
 on the \c N itself.

 In addition to that, \c VariantChoice uses recursive inheritance so that it actually handles \em all alternatives that
 precede this one in \c Types i.e. for

 \code VariantChoice<3, bool, short, int> \endcode

 the inheritance chain would be

 \code
 VariantChoice<3, bool, short, int> -> VariantChoice<2, bool, short, int> -> VariantChoice<1, bool, short, int>...
 \endcode

 terminating with a degenerate case of \c VariantChoice<0> which is undefined. In the end, there's going to be a \c
 VariantChoice instantiation for every type in \c Types .
 */
template <unsigned N, typename... Types> class VariantChoice : public VariantChoice<N - 1, Types...> {
  using Derived = Variant<Types...>;
  using T = NthElement<Typelist<Types...>, sizeof...(Types) - N>;

 public:
  VariantChoice() {}

  VariantChoice(const T &value)
  {
    new (getDerived().getRawBuffer()) T{value};
    getDerived().setDiscriminator(Discriminator);
  }

  VariantChoice(T &&value)
  {
    new (getDerived().getRawBuffer()) T{std::move(value)};
    getDerived().setDiscriminator(Discriminator);
  }

  // Inherit constructors from the rest of the alternatives
  using VariantChoice<N - 1, Types...>::VariantChoice;

  /// Calls the destructor of \c T, if it is the current alternative, otherwise delegates to the base class.
  auto destroy() -> void
  {
    if (getDerived().getDiscriminator() == Discriminator) {
      getDerived().template getBufferAs<T>()->~T();
      return;
    }
    VariantChoice<N - 1, Types...>::destroy();
  }

  auto operator=(const T &value) -> Derived &
  {
    auto &derived = getDerived();
    if (derived.getDiscriminator() == Discriminator) {
      *derived.template getBufferAs<T>() = value;
    } else {
      derived.destroy();
      new (derived.getRawBuffer()) T{value};
      derived.setDiscriminator(Discriminator);
    }
    return derived;
  }

  auto operator=(T &&value) -> Derived &
  {
    auto &derived = getDerived();
    if (derived.getDiscriminator() == Discriminator) {
      *derived.template getBufferAs<T>() = std::move(value);
    } else {
      derived.destroy();
      new (derived.getRawBuffer()) T{std::move(value)};
      derived.setDiscriminator(Discriminator);
    }
    return derived;
  }

  // Inherit assignment operators from the rest of the alternatives
  using VariantChoice<N - 1, Types...>::operator=;

 protected:
  /// Discriminator value used for the alternative that holds an instance of \c T (see \c VariantStorage )
  static constexpr unsigned Discriminator =
    sizeof...(Types) - N + 1;  // Start with 1 since 0 is reserved for empty variants

 private:
  /// CRTP helpers
  auto getDerived() -> Derived &
  {
    return *static_cast<Derived *>(this);
  }

  auto getDerived() const -> const Derived &
  {
    return *static_cast<Derived const *>(this);
  }
};

template <typename... Types> class VariantChoice<0, Types...> {
 public:
  auto destroy() -> void {}
};

#pragma mark - VariantMatch

/**
 Recursively matches a variant against a given matcher.

 Do not use this directly, prefer using \c Variant::match instead.

 \param variant A variant to match.
 \param matcher A function-like object that is able to handle all the alternatives in the variant.
 \param _ An unused typelist that is used to pass the list of the alternatives still to be matched, decomposed into a
 head and a tail.

 \return  The result of invoking \c matcher with the current alternative.
 */
template <typename Result, typename V, typename Matcher, typename Head, typename... Tail>
auto variantMatchImpl(V &&variant, Matcher &&matcher, Typelist<Head, Tail...>) -> Result
{
  if (variant.template is<Head>()) {
    return static_cast<Result>(matcher(variant.template get<Head>()));
  }
  // Try to match the rest of the alternatives
  return variantMatchImpl<Result>(std::forward<V>(variant), std::forward<Matcher>(matcher), Typelist<Tail...>{});
}

template <typename Result, typename V, typename Matcher> auto variantMatchImpl(V &&, Matcher &&, Typelist<>) -> Result
{
  // Getting here means the currently stored alternative doesn't match anything from the typelist. The only way this
  // could happen is trying to match an empty variant which is forbidden.
  abort();
}

#pragma mark - MatchResult

template <typename Result, typename Matcher, typename... ElementTypes> class MatchResultT {
 public:
  using Type = Result;
};

/// A placeholder type for cases when the result type of matching is determined automatically.
class ComputedResultType;

template <typename Matcher, typename T> using MatchElementResult = decltype(std::declval<Matcher>()(std::declval<T>()));

template <typename Matcher, typename... ElementTypes> class MatchResultT<ComputedResultType, Matcher, ElementTypes...> {
 public:
  using Type = std::common_type_t<MatchElementResult<Matcher, ElementTypes>...>;
};

/**
 A meta-function returning the result type of matching a variant holding \c ElementTypes as its alternatives, against an
 instance of \c Matcher.

 If \c Result is different from \c ComputedResultType , it is returned immediately; otherwise, a type, all result types
 of invoking \c Matcher with each type from \c ElementTypes  can be converted to, is returned instead.

 Consider the example. For the following matcher:

 \code
 struct M {
   auto operator()(int) -> const char *;
   auto operator()(std::string) -> std::string;
 }
 \endcode

 and the \c ElementTypes of:

 \code
 {int, std::string}
 \endcode

 The result type of invoking the matcher with \c int would be \c const \c char \c * , while the result type of invoking
 the matcher with \c std::string would be an \c std::string . Thus, the common type for \c const \c char \c * and \c
 std::string would be \c std::string .
 */
template <typename Result, typename Matcher, typename... ElementTypes>
using MatchResult = typename MatchResultT<Result, Matcher, ElementTypes...>::Type;

#pragma mark - Overloaded

template <typename T>
using ConditionalFunctionWrapper = typename std::conditional<
    std::is_pointer<T>::value && std::is_function<typename std::remove_pointer<T>::type>::value,
    std::function<typename std::remove_pointer<T>::type>,
    T
  >::type;

/**
 Struct template that aggregates multiple callables into a single callable by inherting from all of them.

 For the following \c Fs :

 \code
 [](int i) { ... },
 [](double d) { ... }
 \endcode

 the resulting callable would be:

 \code
 struct Overloaded {
   auto operator()(int i) { ... }
   auto operator()(double d) { ... }
 }
 \endcode

 Thus, the resulting callable can be invoked with both \c int and \c double arguments.
 */
template <typename... Fs> struct Overloaded : ConditionalFunctionWrapper<Fs>... {
  Overloaded(Fs... fs) : ConditionalFunctionWrapper<Fs>{fs}... {}
};

}  // namespace VariantDetail

#pragma mark - Variant

/**
 Class template representing a sum type for all \c Types .

 \c CK::Variant is useful for representing a set of mutually exclusive alternatives represented by instances of \c Types
 . For example:

 \code
 CK::Variant<int, double, std::string>
 \endcode

 can store either an \c int , a \c double or a \c std::string , but only one of them at a time.

 In order to access the currently active alternative, a set of  \c match member functions is provided, e.g.

 \code
 CK::Variant<int, double, std::string> v = ...;
 v.match(
   [](int i) { // Process int value },
   [](double d) { // Process double value },
   [](const std::string &s) { // Process string value }
 );
 \endcode
 */
template <typename... Types>
class Variant : private VariantDetail::VariantStorage<Types...>,
                private VariantDetail::VariantChoice<sizeof...(Types), Types...> {
  template <unsigned, typename... OtherTypes> friend class VariantDetail::VariantChoice;

 public:
  // Inherit constructors from each of the types in Types
  using VariantDetail::VariantChoice<sizeof...(Types), Types...>::VariantChoice;

  // Inherit assignment operators from each of the types in Types
  using VariantDetail::VariantChoice<sizeof...(Types), Types...>::operator=;

  Variant() = default;

  Variant(const Variant& other) {
    if (other.getDiscriminator() != 0) {
      other.match([this](const auto& rhs){
        *this = rhs;
      });
    }
  }

  Variant(Variant&& other) {
    if (other.getDiscriminator() != 0) {
      other.match([this](auto&& rhs){
        *this = std::move(rhs);
      });
    }
  }

  Variant& operator=(const Variant& other)
  {
    if (other.getDiscriminator() != 0) {
      other.match([this](const auto& rhs){
        *this = rhs;
      });
    } else {
      destroy();
    }

    return *this;
  }

  Variant& operator=(Variant&& other) {
    if (other.getDiscriminator() != 0) {
      other.match([this](auto&& rhs){
        *this = std::move(rhs);
      });
    } else {
      destroy();
    }

    return *this;
  }

  ~Variant()
  {
    destroy();
  }

  /**
   Checks if the alternative corresponding to \c T is currently stored in the variant.
   */
  template <typename T> auto is() const -> bool
  {
    constexpr auto indexOfT = VariantDetail::IndexOfT<T, Types...>::value;
    return this->getDiscriminator() ==
           VariantDetail::VariantChoice<sizeof...(Types) - indexOfT, Types...>::Discriminator;
  }

  /**
   Matches the variant against a given matcher.

   \param matcher A callable that can be invoked with any type in \c Types . If \c matcher cannot be invoked with one or
   more types in \c Types a compilation error is raised.
   */
  template <typename R = VariantDetail::ComputedResultType, typename Matcher> auto match(Matcher &&matcher) &
  {
    using Result = VariantDetail::MatchResult<R, Matcher, Types &...>;
    return VariantDetail::variantMatchImpl<Result>(
      *this, std::forward<Matcher>(matcher), VariantDetail::Typelist<Types...>{});
  }

  template <typename R = VariantDetail::ComputedResultType, typename Matcher> auto match(Matcher &&matcher) const &
  {
    using Result = VariantDetail::MatchResult<R, Matcher, Types const &...>;
    return VariantDetail::variantMatchImpl<Result>(
      *this, std::forward<Matcher>(matcher), VariantDetail::Typelist<Types...>{});
  }

  template <typename R = VariantDetail::ComputedResultType, typename Matcher> auto match(Matcher &&matcher) &&
  {
    using Result = VariantDetail::MatchResult<R, Matcher, Types &&...>;
    return VariantDetail::variantMatchImpl<Result>(
      std::move(*this), std::forward<Matcher>(matcher), VariantDetail::Typelist<Types...>{});
  }

  /**
   Matches the variant against a given set of matchers.

   \param matchers A set of callables that can be invoked with any type in \c Types . If a matcher for one or more types
   in \c Types is missing, a compilation error is raised.
   */
  template <typename... Matchers> auto match(Matchers &&... matchers) &
  {
    return match(VariantDetail::Overloaded<Matchers...>{matchers...});
  }

  template <typename... Matchers> auto match(Matchers &&... matchers) const &
  {
    return match(VariantDetail::Overloaded<Matchers...>{matchers...});
  }

  template <typename... Matchers> auto match(Matchers &&... matchers) &&
  {
    return std::move(*this).match(VariantDetail::Overloaded<Matchers...>{matchers...});
  }

  /**
   Compares this variant to a value of \c T.

   The variant is considered equal to the value if it currently holds the alternative of \c T and the alternative is
   equal to the provided value. The equality for the alternatives is determined by invoking the equality operator,
   therefore, if the equality operator is not provided by the alternative, a compilation error is raised.
   */
  template <typename T> auto operator==(const T &value) const -> bool
  {
    if (!is<T>()) {
      return false;
    }
    return get<T>() == value;
  }

  /**
   Compares this variant to another.

   Variants are considered equal if both hold the same alternative, and the alternatives are equal. The equality for the
   alternatives is determined by invoking the equality operator, therefore, if the equality operator is not provided by
   the alternative, a compilation error is raised.

   \param other A variant to compare to.
  */
  auto operator==(const Variant<Types...> &other) const -> bool
  {
    if (this->getDiscriminator() != other.getDiscriminator()) {
      return false;
    }

    return other.match([this](const auto &rhs) {
      using T = std::remove_const_t<std::remove_reference_t<decltype(rhs)>>;
      return this->get<T>() == rhs;
    });
  }

  auto operator!=(const Variant<Types...> &other) const -> bool
  {
    return !(*this == other);
  }

 private:
  template <typename Result, typename V, typename Matcher, typename Head, typename... Tail>
  friend auto VariantDetail::variantMatchImpl(V &&variant, Matcher &&matcher, VariantDetail::Typelist<Head, Tail...>)
    -> Result;

  template <typename T> auto get() & -> T &
  {
    assert(is<T>());
    return *this->template getBufferAs<T>();
  }

  template <typename T> auto get() const & -> const T &
  {
    assert(is<T>());
    return *this->template getBufferAs<T>();
  }

  template <typename T> auto get() && -> T &&
  {
    assert(is<T>());
    return std::move(*this)->template getBufferAs<T>();
  }

  auto destroy() -> void
  {
    VariantDetail::VariantChoice<sizeof...(Types), Types...>::destroy();
    this->setDiscriminator(0);
  }
};

}  // namespace CK

#endif
