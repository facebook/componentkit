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

BOOL CKSubclassOverridesSelector(Class superclass, Class subclass, SEL selector) noexcept;

std::string CKStringFromPointer(const void *ptr) noexcept;

CGFloat CKScreenScale() noexcept;

CGFloat CKFloorPixelValue(CGFloat f) noexcept;

CGFloat CKCeilPixelValue(CGFloat f) noexcept;

CGFloat CKRoundPixelValue(CGFloat f) noexcept;
