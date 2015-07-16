/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant 
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKDimension.h"

#import <tgmath.h>

#import <ComponentKit/CKAssert.h>

#import "CKInternalHelpers.h"
#import "ComponentLayoutContext.h"
#import "CKMacros.h"

#define CKCAssertPositiveReal(description, num) \
  CKCAssert(num >= 0 && num < CGFLOAT_MAX, @"%@ must be a real positive integer.\n%@", description, CK::Component::LayoutContext::currentStackDescription())
#define CKCAssertInfOrPositiveReal(description, num) \
  CKCAssert(isinf(num) || (num >= 0 && num < CGFLOAT_MAX), @"%@ must be infinite or a real positive integer.\n%@", description, CK::Component::LayoutContext::currentStackDescription())

CKRelativeDimension::CKRelativeDimension(Type type, CGFloat value) : _type(type), _value(value)
{
  if (type == Type::POINTS) {
    CKCAssertPositiveReal(@"Points", value);
  }
}

bool CKRelativeDimension::operator==(const CKRelativeDimension &other) const
{
  // Implementation assumes that "auto" assigns '0' to value.
  if (_type != other._type) {
    return false;
  }
  switch (_type) {
    case Type::AUTO:
      return true;
    case Type::POINTS:
    case Type::PERCENT:
      return _value == other._value;
  }
}

NSString *CKRelativeDimension::description() const
{
  switch (_type) {
    case Type::AUTO:
      return @"Auto";
    case Type::POINTS:
      return [NSString stringWithFormat:@"%.0fpt", _value];
    case Type::PERCENT:
      return [NSString stringWithFormat:@"%.0f%%", _value * 100.0];
  }
}

CGFloat CKRelativeDimension::resolve(CGFloat autoSize, CGFloat parent) const
{
  switch (_type) {
    case Type::AUTO:
      return autoSize;
    case Type::POINTS:
      return _value;
    case Type::PERCENT:
      return round(_value * parent);
  }
}

CKSizeRange::CKSizeRange(const CGSize &_min, const CGSize &_max) : min(_min), max(_max)
{
  CKCAssertPositiveReal(@"Range min width", min.width);
  CKCAssertPositiveReal(@"Range min height", min.height);
  CKCAssertInfOrPositiveReal(@"Range max width", max.width);
  CKCAssertInfOrPositiveReal(@"Range max height", max.height);
  CKCAssert(min.width <= max.width,
            @"Range min width (%f) must not be larger than max width (%f).", min.width, max.width);
  CKCAssert(min.height <= max.height,
            @"Range min height (%f) must not be larger than max height (%f).", min.height, max.height);
}

CGSize CKSizeRange::clamp(const CGSize &size) const
{
  return {
    MAX(min.width, MIN(max.width, size.width)),
    MAX(min.height, MIN(max.height, size.height))
  };
}

struct _Range {
  CGFloat min;
  CGFloat max;

  /**
   Intersects another dimension range. If the other range does not overlap, this size range "wins" by returning a
   single point within its own range that is closest to the non-overlapping range.
   */
  _Range intersect(const _Range &other) const
  {
    CGFloat newMin = MAX(min, other.min);
    CGFloat newMax = MIN(max, other.max);
    if (!(newMin > newMax)) {
      return {newMin, newMax};
    } else {
      // No intersection. If we're before the other range, return our max; otherwise our min.
      if (min < other.min) {
        return {max, max};
      } else {
        return {min, min};
      }
    }
  }
};

CKSizeRange CKSizeRange::intersect(const CKSizeRange &other) const
{
  auto w = _Range({min.width, max.width}).intersect({other.min.width, other.max.width});
  auto h = _Range({min.height, max.height}).intersect({other.min.height, other.max.height});
  return {{w.min, h.min}, {w.max, h.max}};
}

bool CKSizeRange::operator==(const CKSizeRange &other) const
{
  return CGSizeEqualToSize(min, other.min) && CGSizeEqualToSize(max, other.max);
}
NSString *CKSizeRange::description() const
{
  return [NSString stringWithFormat:@"<CKSizeRange: min=%@, max=%@>", NSStringFromCGSize(min), NSStringFromCGSize(max)];
}
size_t CKSizeRange::hash() const
{
  std::hash<CGFloat> hasher;
  NSUInteger subhashes[] = {
    hasher(min.width),
    hasher(min.height),
    hasher(max.width),
    hasher(max.height)
  };
  return CKIntegerArrayHash(subhashes, CK_ARRAY_COUNT(subhashes));
}

CKRelativeSize::CKRelativeSize(const CKRelativeDimension &_width, const CKRelativeDimension &_height) : width(_width), height(_height) {}
CKRelativeSize::CKRelativeSize(const CGSize &size) : CKRelativeSize(size.width, size.height) {}
CKRelativeSize::CKRelativeSize() : CKRelativeSize({}, {}) {}

CGSize CKRelativeSize::resolveSize(const CGSize &parentSize, const CGSize &autoSize) const
{
  return {
    width.resolve(autoSize.width, parentSize.width),
    height.resolve(autoSize.height, parentSize.height),
  };
}

bool CKRelativeSize::operator==(const CKRelativeSize &other) const
{
  return width == other.width && height == other.height;
}

NSString *CKRelativeSize::description() const
{
  return [NSString stringWithFormat:@"{%@, %@}", width.description(), height.description()];
}

CKRelativeSizeRange::CKRelativeSizeRange(const CKRelativeSize &_min, const CKRelativeSize &_max) : min(_min), max(_max) {}
CKRelativeSizeRange::CKRelativeSizeRange(const CKRelativeSize &exact) : CKRelativeSizeRange(exact, exact) {}
CKRelativeSizeRange::CKRelativeSizeRange(const CGSize &exact) : CKRelativeSizeRange(CKRelativeSize(exact)) {}
CKRelativeSizeRange::CKRelativeSizeRange(const CKRelativeDimension &exactWidth, const CKRelativeDimension &exactHeight) : CKRelativeSizeRange(CKRelativeSize(exactWidth, exactHeight)) {}
CKRelativeSizeRange::CKRelativeSizeRange() : CKRelativeSizeRange(CKRelativeSize(), CKRelativeSize()) {}

CKSizeRange CKRelativeSizeRange::resolveSizeRange(const CGSize &parentSize, const CKSizeRange &autoCKSizeRange) const
{
  return {
    min.resolveSize(parentSize, autoCKSizeRange.min),
    max.resolveSize(parentSize, autoCKSizeRange.max)
  };
}
