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

#import <string>

#import <UIKit/UIKit.h>

BOOL CKSubclassOverridesInstanceMethod(Class superclass, Class subclass, SEL selector) noexcept;
BOOL CKSubclassOverridesClassMethod(Class superclass, Class subclass, SEL selector) noexcept;

std::string CKStringFromPointer(const void *ptr) noexcept;

CGFloat CKScreenScale() noexcept;

CGFloat CKFloorPixelValue(CGFloat f) noexcept;

CGFloat CKCeilPixelValue(CGFloat f) noexcept;

CGFloat CKRoundPixelValue(CGFloat f) noexcept;

static inline BOOL CKFloatsEqual(const CGFloat a, const CGFloat b) noexcept {
    if (isnan(a)) {
        return isnan(b);
    }
    return fabs(a - b) < 0.0001f;
}

static inline bool CKIsGreaterThanOrEqualWithTolerance(CGFloat a,CGFloat b) {
    return a > b || CKFloatsEqual(a, b);
}

static inline CGFloat CKRoundValueToPixelGrid(CGFloat value, const BOOL forceCeil,
                                              const BOOL forceFloor) noexcept
{
    CGFloat scale = CKScreenScale();
    CGFloat scaledValue = value * scale;
    CGFloat fractial = fmodf(scaledValue, 1.0);
    if (CKFloatsEqual(fractial, 0)) {
        // First we check if the value is already rounded
        scaledValue = scaledValue - fractial;
    } else if (CKFloatsEqual(fractial, 1.0)) {
        scaledValue = scaledValue - fractial + 1.0;
    } else if (forceCeil) {
        // Next we check if we need to use forced rounding
        scaledValue = scaledValue - fractial + 1.0f;
    } else if (forceFloor) {
        scaledValue = scaledValue - fractial;
    } else {
        // Finally we just round the value
        scaledValue = scaledValue - fractial +
        (fractial > 0.5f || CKFloatsEqual(fractial, 0.5f) ? 1.0f : 0.0f);
    }
    return scaledValue / scale;
}

#endif
