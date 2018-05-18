/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKIndexSetDescription.h"

auto CK::indexSetDescription(NSIndexSet *const is, NSString *const title, const int indent) -> NSString *
{
  if (is.count == 0) {
    return @"";
  }

  auto rangeStrings = static_cast<NSMutableArray<NSString *> *>([NSMutableArray array]);
  [is enumerateRangesUsingBlock:^(NSRange range, BOOL * _Nonnull) {
    const auto rangeStr = range.length > 1 ?
      [NSString stringWithFormat:@"%lu–%lu", (unsigned long)range.location, (unsigned long)NSMaxRange(range) - 1] :
      [NSString stringWithFormat:@"%lu", (unsigned long)range.location];
    [rangeStrings addObject:rangeStr];
  }];
  const auto description = [rangeStrings componentsJoinedByString:@", "];
  const auto titleIndentStr = [@"" stringByPaddingToLength:indent withString:@" " startingAtIndex:0];
  return title.length > 0 ? [NSString stringWithFormat:@"%@%@: %@", titleIndentStr, title, description] : description;
}
