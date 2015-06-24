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

BOOL CKSubclassOverridesSelector(Class superclass, Class subclass, SEL selector);

std::string CKStringFromPointer(const void *ptr);

CGFloat CKScreenScale();

CGFloat CKFloorPixelValue(CGFloat f);

CGFloat CKCeilPixelValue(CGFloat f);

CGFloat CKRoundPixelValue(CGFloat f);
