/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "RCDimension.h"

#import <tgmath.h>

#import <RenderCore/CKAssert.h>
#import <RenderCore/RCEqualityHelpers.h>
#import <RenderCore/CKMacros.h>
#import <RenderCore/CKInternalHelpers.h>

bool RCRelativeDimension::operator==(const RCRelativeDimension &other) const noexcept
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

NSString *RCRelativeDimension::description() const noexcept
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

CGFloat RCRelativeDimension::resolve(CGFloat autoSize, CGFloat parent) const noexcept
{
  switch (_type) {
    case Type::AUTO:
      return autoSize;
    case Type::POINTS:
      return _value;
    case Type::PERCENT:
      return isnan(parent) || isinf(parent) ? autoSize : round(_value * parent);
  }
}

RCRelativeDimension::Type RCRelativeDimension::type(void) const noexcept
{
  return _type;
}

CGFloat RCRelativeDimension::value(void) const noexcept
{
  return _value;
}

size_t std::hash<RCRelativeDimension>::operator ()(const RCRelativeDimension &size) noexcept {
  NSUInteger subhashes[] = {
    (size_t)(size._type),
    std::hash<CGFloat>()(size._value),
  };
  return RCIntegerArrayHash(subhashes, std::end(subhashes) - std::begin(subhashes));
};


RCRelativeSize::RCRelativeSize(const RCRelativeDimension &_width, const RCRelativeDimension &_height) noexcept : width(_width), height(_height) {}
RCRelativeSize::RCRelativeSize(const CGSize &size) noexcept : RCRelativeSize(size.width, size.height) {}

CGSize RCRelativeSize::resolveSize(const CGSize &parentSize, const CGSize &autoSize) const noexcept
{
  return {
    width.resolve(autoSize.width, parentSize.width),
    height.resolve(autoSize.height, parentSize.height),
  };
}

bool RCRelativeSize::operator==(const RCRelativeSize &other) const noexcept
{
  return width == other.width && height == other.height;
}

NSString *RCRelativeSize::description() const noexcept
{
  return [NSString stringWithFormat:@"{%@, %@}", width.description(), height.description()];
}

RCRelativeSizeRange::RCRelativeSizeRange(const RCRelativeSize &_min, const RCRelativeSize &_max) : min(_min), max(_max) {}
RCRelativeSizeRange::RCRelativeSizeRange(const RCRelativeSize &exact) noexcept : RCRelativeSizeRange(exact, exact) {}
RCRelativeSizeRange::RCRelativeSizeRange(const CGSize &exact) noexcept : RCRelativeSizeRange(RCRelativeSize(exact)) {}
RCRelativeSizeRange::RCRelativeSizeRange(const RCRelativeDimension &exactWidth, const RCRelativeDimension &exactHeight) noexcept : RCRelativeSizeRange(RCRelativeSize(exactWidth, exactHeight)) {}

CKSizeRange RCRelativeSizeRange::resolveSizeRange(const CGSize &parentSize, const CKSizeRange &autoCKSizeRange) const noexcept
{
  return {
    min.resolveSize(parentSize, autoCKSizeRange.min),
    max.resolveSize(parentSize, autoCKSizeRange.max)
  };
}
