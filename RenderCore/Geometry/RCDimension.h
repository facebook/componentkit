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

#import <UIKit/UIKit.h>

#import <RenderCore/CKAssert.h>
#import <RenderCore/CKSizeRange.h>

/**
 A dimension relative to constraints to be provided in the future.
 A RelativeDimension can be one of three types:

 "Auto" - This indicated "I have no opinion" and may be resolved in whatever way makes most sense given
 the circumstances. This is the default type.

 "Points" - Just a number. It will always resolve to exactly this amount.

 "Percent" - Multiplied to a provided parent amount to resolve a final amount.
 If the parent amount is undefined (NaN) or infinite, it acts as if Auto size was specified instead.

 A number of convenience constructors have been provided to make using RelativeDimension straight-forward.

 RCRelativeDimension x;                                     // Auto (default case)
 RCRelativeDimension z = 10;                                // 10 Points
 RCRelativeDimension y = RCRelativeDimension::Auto();       // Auto
 RCRelativeDimension u = RCRelativeDimension::Percent(0.5); // 50%

 */
class RCRelativeDimension;

namespace std {
  template <> struct hash<RCRelativeDimension> {
    size_t operator ()(const RCRelativeDimension &) noexcept;
  };
}

class RCRelativeDimension {
public:
  // Make sizeof(Type) == sizeof(CGFloat) so that the default
  // constructor takes fewer instructions (because of SLP
  // vectorization).
  enum class Type : NSInteger {
    AUTO,
    POINTS,
    PERCENT,
  };
  /** Default constructor is equivalent to "Auto". */
  constexpr RCRelativeDimension() noexcept : _type(Type::AUTO), _value(0) {}
  RCRelativeDimension(CGFloat points) noexcept : RCRelativeDimension(Type::POINTS, points) {}

  constexpr static RCRelativeDimension Auto() noexcept { return RCRelativeDimension(); }
  static RCRelativeDimension Points(CGFloat p) noexcept { return RCRelativeDimension(p); }
  static RCRelativeDimension Percent(CGFloat p) noexcept { return {RCRelativeDimension::Type::PERCENT, p}; }

  RCRelativeDimension(const RCRelativeDimension &) = default;
  RCRelativeDimension &operator=(const RCRelativeDimension &) = default;

  bool operator==(const RCRelativeDimension &) const noexcept;
  NSString *description() const noexcept;
  CGFloat resolve(CGFloat autoSize, CGFloat parent) const noexcept;
  Type type() const noexcept;
  CGFloat value() const noexcept;

private:
  RCRelativeDimension(Type type, CGFloat value)
    : _type(type), _value(value) {}

  Type _type;
  CGFloat _value;

  friend std::hash<RCRelativeDimension>;
};


/** Expresses a size with relative dimensions. */
struct RCRelativeSize {
  RCRelativeDimension width;
  RCRelativeDimension height;
  RCRelativeSize(const RCRelativeDimension &width, const RCRelativeDimension &height) noexcept;

  /** Convenience constructor to provide size in Points. */
  RCRelativeSize(const CGSize &size) noexcept;

  /** Convenience constructor for {Auto, Auto} */
  constexpr RCRelativeSize() = default;

  /** Resolve this size relative to a parent size and an auto size. */
  CGSize resolveSize(const CGSize &parentSize, const CGSize &autoSize) const noexcept;

  bool operator==(const RCRelativeSize &other) const noexcept;
  NSString *description() const noexcept;
};

/**
 Expresses an inclusive range of relative sizes. Used to provide additional constraint to component layout.
 */
struct RCRelativeSizeRange {
  RCRelativeSize min;
  RCRelativeSize max;
  RCRelativeSizeRange(const RCRelativeSize &min, const RCRelativeSize &max);

  /**
   Convenience constructors to provide an exact size (min == max).
   RCRelativeSizeRange r = {80, 60} // width: [80, 80], height: [60, 60].
   */
  RCRelativeSizeRange(const RCRelativeSize &exact) noexcept;
  RCRelativeSizeRange(const CGSize &exact) noexcept;
  RCRelativeSizeRange(const RCRelativeDimension &exactWidth, const RCRelativeDimension &exactHeight) noexcept;

  /** Convenience constructor for {{Auto, Auto}, {Auto, Auto}}. */
  constexpr RCRelativeSizeRange() = default;

  /**
   Provided a parent size and values to use in place of Auto, compute final dimensions for this RelativeSizeRange
   to arrive at a SizeRange. As an example:

   CGSize parent = {200, 120};
   RelativeSizeRange rel = {Percent(0.5), Percent(2/3)}
   rel.resolveSizeRange(parent); // {{100, 60}, {100, 60}}

   The default for Auto() is *everything*, meaning min = {0,0}; max = {INFINITY, INFINITY};
   */
  CKSizeRange resolveSizeRange(const CGSize &parentSize,
                               const CKSizeRange &autoSizeRange = {{0,0}, {INFINITY, INFINITY}}) const noexcept;
};

#endif
