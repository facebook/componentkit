/*
*  Copyright (c) 2014-present, Facebook, Inc.
*  All rights reserved.
*
*  This source code is licensed under the BSD-style license found in the
*  LICENSE file in the root directory of this source tree. An additional grant
*  of patent rights can be found in the PATENTS file in the same directory.
*
*/

#import <ComponentKit/ComponentLayoutContext.h>

#define CKAssertPositiveReal(description, num) \
  RCCAssertWithCategory(num >= 0 && num < CGFLOAT_MAX, CK::Component::LayoutContext::currentRootComponentClassName(), @"%@ (%f) must be a real positive integer.\n%@", description, num, CK::Component::LayoutContext::currentStackDescription())

#define CKAssertInfOrPositiveReal(description, num) \
  RCCAssertWithCategory(isinf(num) || (num >= 0 && num < CGFLOAT_MAX), CK::Component::LayoutContext::currentRootComponentClassName(), @"%@ (%f) must be infinite or a real positive integer.\n%@", description, num, CK::Component::LayoutContext::currentStackDescription())

#define CKAssertWidth(min, max) \
  RCCAssertWithCategory(min.width <= max.width, \
    CK::Component::LayoutContext::currentRootComponentClassName(), \
    @"Range min width (%f) must not be larger than max width (%f).\n%@", min.width, max.width, CK::Component::LayoutContext::currentStackDescription())

#define CKAssertHeight(min, max) \
  RCCAssertWithCategory(min.height <= max.height, \
    CK::Component::LayoutContext::currentRootComponentClassName(), \
    @"Range min height (%f) must not be larger than max height (%f).\n%@", min.height, max.height, CK::Component::LayoutContext::currentStackDescription())

#define CKAssertSizeRange(sizeRange) \
  CKAssertPositiveReal(@"Range min width", sizeRange.min.width); \
  CKAssertPositiveReal(@"Range min height", sizeRange.min.height); \
  CKAssertInfOrPositiveReal(@"Range max width", sizeRange.max.width); \
  CKAssertInfOrPositiveReal(@"Range max height", sizeRange.max.height); \
  CKAssertWidth(sizeRange.min, sizeRange.max); \
  CKAssertHeight(sizeRange.min, sizeRange.max)

#define CKAssertConstrainedValue(val) \
  RCCAssert(!isnan(val), @"Constrained value must not be NaN. Current stack description: %@", \
    CK::Component::LayoutContext::currentStackDescription())

#if CK_ASSERTIONS_ENABLED
  #define CKAssertResolvedSize(componentSize, parentSize) \
    CGSize resolvedMin = RCRelativeSize(componentSize.minWidth, componentSize.minHeight).resolveSize(parentSize, {0, 0}); \
    CGSize resolvedMax = RCRelativeSize(componentSize.maxWidth, componentSize.maxHeight).resolveSize(parentSize, {INFINITY, INFINITY}); \
    CKAssertConstrainedValue(resolvedMin.width); \
    CKAssertConstrainedValue(resolvedMin.height); \
    CKAssertConstrainedValue(resolvedMax.width); \
    CKAssertConstrainedValue(resolvedMax.height)
#else
  #define CKAssertResolvedSize(componentSize, parentSize)  do {} while (0)
#endif
