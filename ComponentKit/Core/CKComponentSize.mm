/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentSize.h"
#import "CKEqualityHashHelpers.h"

#import <ComponentKit/CKAssert.h>

CKComponentSize CKComponentSize::fromCGSize(CGSize size)
{
  return {size.width, size.height};
}

static inline void CKCSConstrain(CGFloat minVal, CGFloat exactVal, CGFloat maxVal, CGFloat *outMin, CGFloat *outMax)
{
    CKCAssert(!isnan(minVal), @"minVal must not be NaN. Current stack description: %@", CK::Component::LayoutContext::currentStackDescription());
    CKCAssert(!isnan(maxVal), @"maxVal must not be NaN. Current stack description: %@", CK::Component::LayoutContext::currentStackDescription());
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
    if (isnan(exactVal)) {
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

CKSizeRange CKComponentSize::resolve(const CGSize &parentSize) const
{
  CGSize resolvedExact = CKRelativeSize(width, height).resolveSize(parentSize, {NAN, NAN});
  CGSize resolvedMin = CKRelativeSize(minWidth, minHeight).resolveSize(parentSize, {0, 0});
  CGSize resolvedMax = CKRelativeSize(maxWidth, maxHeight).resolveSize(parentSize, {INFINITY, INFINITY});

  CGSize rangeMin, rangeMax;
  CKCSConstrain(resolvedMin.width, resolvedExact.width, resolvedMax.width, &rangeMin.width, &rangeMax.width);
  CKCSConstrain(resolvedMin.height, resolvedExact.height, resolvedMax.height, &rangeMin.height, &rangeMax.height);
  return {rangeMin, rangeMax};
}

bool CKComponentSize::operator==(const CKComponentSize &other) const
{
  return width == other.width && height == other.height
  && minWidth == other.minWidth && minHeight == other.minHeight
  && maxWidth == other.maxWidth && maxHeight == other.maxHeight;
}

NSString *CKComponentSize::description() const
{
  return [NSString stringWithFormat:
          @"<CKComponentSize: exact=%@, min=%@, max=%@>",
          CKRelativeSize(width, height).description(),
          CKRelativeSize(minWidth, minHeight).description(),
          CKRelativeSize(maxWidth, maxHeight).description()];
}

size_t std::hash<CKComponentSize>::operator ()(const CKComponentSize &size) {
  NSUInteger subhashes[] = {
    std::hash<CKRelativeDimension>()(size.width),
    std::hash<CKRelativeDimension>()(size.height),
    std::hash<CKRelativeDimension>()(size.minWidth),
    std::hash<CKRelativeDimension>()(size.minHeight),
    std::hash<CKRelativeDimension>()(size.maxWidth),
    std::hash<CKRelativeDimension>()(size.maxHeight),
  };

  return CKIntegerArrayHash(subhashes, std::end(subhashes) - std::begin(subhashes));
};
