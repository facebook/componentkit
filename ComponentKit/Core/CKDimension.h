/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <string>

#import <UIKit/UIKit.h>

#import <ComponentKit/CKAssert.h>
#import <ComponentKit/CKSizeRange.h>
#import <ComponentKit/ComponentLayoutContext.h>  // Used by CKCAssertPositiveReal.

#define CKCAssertPositiveReal(description, num) \
  CKCAssert(num >= 0 && num < CGFLOAT_MAX, @"%@ must be a real positive integer.\n%@", description, CK::Component::LayoutContext::currentStackDescription())
#define CKCAssertInfOrPositiveReal(description, num) \
  CKCAssert(isinf(num) || (num >= 0 && num < CGFLOAT_MAX), @"%@ must be infinite or a real positive integer.\n%@", description, CK::Component::LayoutContext::currentStackDescription())

/**
 A dimension relative to constraints to be provided in the future.
 A RelativeDimension can be one of three types:

 "Auto" - This indicated "I have no opinion" and may be resolved in whatever way makes most sense given
 the circumstances. This is the default type.

 "Points" - Just a number. It will always resolve to exactly this amount.

 "Percent" - Multiplied to a provided parent amount to resolve a final amount.

 A number of convenience constructors have been provided to make using RelativeDimension straight-forward.

 CKRelativeDimension x;                                     // Auto (default case)
 CKRelativeDimension z = 10;                                // 10 Points
 CKRelativeDimension y = CKRelativeDimension::Auto();       // Auto
 CKRelativeDimension u = CKRelativeDimension::Percent(0.5); // 50%

 */
class CKRelativeDimension;

namespace std {
  template <> struct hash<CKRelativeDimension> {
    size_t operator ()(const CKRelativeDimension &);
  };
}

class CKRelativeDimension {
public:
  CKRelativeDimension() : CKRelativeDimension(Type::AUTO, 0) {}
  CKRelativeDimension(CGFloat points) : CKRelativeDimension(Type::POINTS, points) {}

  static CKRelativeDimension Auto() { return CKRelativeDimension(); }
  static CKRelativeDimension Points(CGFloat p) { return CKRelativeDimension(p); }
  static CKRelativeDimension Percent(CGFloat p) { return {CKRelativeDimension::Type::PERCENT, p}; }

  CKRelativeDimension(const CKRelativeDimension &) = default;
  CKRelativeDimension &operator=(const CKRelativeDimension &) = default;

  bool operator==(const CKRelativeDimension &) const;
  NSString *description() const;
  CGFloat resolve(CGFloat autoSize, CGFloat parent) const;

private:
  enum class Type {
    AUTO,
    POINTS,
    PERCENT,
  };
  CKRelativeDimension(Type type, CGFloat value)
    : _type(type), _value(value)
  {
    if (type == Type::POINTS) {
      CKCAssertPositiveReal(@"Points", value);
    }
  }

  Type _type;
  CGFloat _value;

  friend std::hash<CKRelativeDimension>;
};


/** Expresses a size with relative dimensions. */
struct CKRelativeSize {
  CKRelativeDimension width;
  CKRelativeDimension height;
  CKRelativeSize(const CKRelativeDimension &width, const CKRelativeDimension &height);

  /** Convenience constructor to provide size in Points. */
  CKRelativeSize(const CGSize &size);

  /** Convenience constructor for {Auto, Auto} */
  CKRelativeSize();

  /** Resolve this size relative to a parent size and an auto size. */
  CGSize resolveSize(const CGSize &parentSize, const CGSize &autoSize) const;

  bool operator==(const CKRelativeSize &other) const;
  NSString *description() const;
};

/**
 Expresses an inclusive range of relative sizes. Used to provide additional constraint to component layout.
 */
struct CKRelativeSizeRange {
  CKRelativeSize min;
  CKRelativeSize max;
  CKRelativeSizeRange(const CKRelativeSize &min, const CKRelativeSize &max);

  /**
   Convenience constructors to provide an exact size (min == max).
   CKRelativeSizeRange r = {80, 60} // width: [80, 80], height: [60, 60].
   */
  CKRelativeSizeRange(const CKRelativeSize &exact);
  CKRelativeSizeRange(const CGSize &exact);
  CKRelativeSizeRange(const CKRelativeDimension &exactWidth, const CKRelativeDimension &exactHeight);

  /** Convenience constructor for {{Auto, Auto}, {Auto, Auto}}. */
  CKRelativeSizeRange();

  /**
   Provided a parent size and values to use in place of Auto, compute final dimensions for this RelativeSizeRange
   to arrive at a SizeRange. As an example:

   CGSize parent = {200, 120};
   RelativeSizeRange rel = {Percent(0.5), Percent(2/3)}
   rel.resolveSizeRange(parent); // {{100, 60}, {100, 60}}

   The default for Auto() is *everything*, meaning min = {0,0}; max = {INFINITY, INFINITY};
   */
  CKSizeRange resolveSizeRange(const CGSize &parentSize,
                               const CKSizeRange &autoSizeRange = {{0,0}, {INFINITY, INFINITY}}) const;
};
