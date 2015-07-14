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

#import "ComponentLayoutContext.h"
#import "CKMacros.h"
#import "CKInternalHelpers.h"
#import "CKEqualityHashHelpers.h"

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

size_t std::hash<CKRelativeDimension>::operator ()(const CKRelativeDimension &size) {
  NSUInteger subhashes[] = {
    (size_t)(size._type),
    std::hash<CGFloat>()(size._value),
  };
  return CKIntegerArrayHash(subhashes, std::end(subhashes) - std::begin(subhashes));
};


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
