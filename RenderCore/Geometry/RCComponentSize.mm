/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "RCComponentSize.h"

#import <RenderCore/CKAssert.h>
#import <RenderCore/RCEqualityHelpers.h>

#define CKCAssertConstrainedValue(val) \
  CKCAssert(!isnan(val), @"Constrained value must not be NaN.")

RCComponentSize RCComponentSize::fromCGSize(CGSize size) noexcept
{
  return {size.width, size.height};
}

static inline void CKCSConstrain(CGFloat minVal, CGFloat exactVal, CGFloat maxVal, CGFloat *outMin, CGFloat *outMax) noexcept
{
    CKCAssertConstrainedValue(minVal);
    CKCAssertConstrainedValue(maxVal);
    // Avoid use of min/max primitives since they're harder to reason
    // about in the presence of NaN (in exactVal)
    // Follow CSS: min overrides max overrides exact.

    // Begin with the min/max range
    *outMin = minVal;
    *outMax = maxVal;
    if (maxVal <= minVal) {
        // min overrides max and exactVal is irrelevant
        *outMax = minVal;
        return;
    }
    if (isnan(exactVal) || isinf(exactVal)) {
        // no exact value, so leave as a min/max range
        return;
    }
    if (exactVal > maxVal) {
        // clip to max value
        *outMin = maxVal;
    } else if (exactVal < minVal) {
        // clip to min value
        *outMax = minVal;
    } else {
        // use exact value
        *outMin = *outMax = exactVal;
    }
}

CKSizeRange RCComponentSize::resolve(const CGSize &parentSize) const noexcept
{
  CGSize resolvedExact = RCRelativeSize(width, height).resolveSize(parentSize, {NAN, NAN});
  CGSize resolvedMin = RCRelativeSize(minWidth, minHeight).resolveSize(parentSize, {0, 0});
  CGSize resolvedMax = RCRelativeSize(maxWidth, maxHeight).resolveSize(parentSize, {INFINITY, INFINITY});

  CGSize rangeMin, rangeMax;
  CKCSConstrain(resolvedMin.width, resolvedExact.width, resolvedMax.width, &rangeMin.width, &rangeMax.width);
  CKCSConstrain(resolvedMin.height, resolvedExact.height, resolvedMax.height, &rangeMin.height, &rangeMax.height);
  return {rangeMin, rangeMax};
}

bool RCComponentSize::operator==(const RCComponentSize &other) const noexcept
{
  return width == other.width && height == other.height
  && minWidth == other.minWidth && minHeight == other.minHeight
  && maxWidth == other.maxWidth && maxHeight == other.maxHeight;
}

NSString *RCComponentSize::description() const noexcept
{
  return [NSString stringWithFormat:
          @"<RCComponentSize: exact=%@, min=%@, max=%@>",
          RCRelativeSize(width, height).description(),
          RCRelativeSize(minWidth, minHeight).description(),
          RCRelativeSize(maxWidth, maxHeight).description()];
}

size_t std::hash<RCComponentSize>::operator ()(const RCComponentSize &size) noexcept {
  NSUInteger subhashes[] = {
    std::hash<RCRelativeDimension>()(size.width),
    std::hash<RCRelativeDimension>()(size.height),
    std::hash<RCRelativeDimension>()(size.minWidth),
    std::hash<RCRelativeDimension>()(size.minHeight),
    std::hash<RCRelativeDimension>()(size.maxWidth),
    std::hash<RCRelativeDimension>()(size.maxHeight),
  };

  return RCIntegerArrayHash(subhashes, std::end(subhashes) - std::begin(subhashes));
};
