/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKTextKitAttributes.h>

#import <ComponentKit/CKInternalHelpers.h>

#include <functional>

NSString *const CKTextKitTruncationAttributeName = @"ck_truncation";
NSString *const CKTextKitEntityAttributeName = @"ck_entity";

size_t CKTextKitAttributes::hash() const
{
  NSUInteger subhashes[] = {
    [attributedString hash],
    [truncationAttributedString hash],
    [avoidTailTruncationSet hash],
    std::hash<NSInteger>()(lineBreakMode),
    std::hash<NSInteger>()(maximumNumberOfLines),
    std::hash<CGFloat>()(shadowOffset.width),
    std::hash<CGFloat>()(shadowOffset.height),
    [shadowColor hash],
    std::hash<CGFloat>()(shadowOpacity),
    std::hash<CGFloat>()(shadowRadius),
  };
  return CKIntegerArrayHash(subhashes, sizeof(subhashes) / sizeof(subhashes[0]));
}
