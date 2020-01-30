/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKDefines.h>

#if CK_NOT_SWIFT

#import <ComponentKit/CKAssert.h>
#import <ComponentKit/CKMountable.h>

// Helper functions.
namespace CKIterable {

// Return the number of non-nil children that are being passed as arguments.
template <typename First>
unsigned int numberOfChildren(First first) {
  return (first != nil ? 1 : 0);
}

template <typename First, typename... Rest>
unsigned int numberOfChildren(First first, Rest... rest) {
  return (first != nil ? 1 : 0) + numberOfChildren(rest...);
}

// Return the child at index according to the children that are being passed as arguments.
template <typename First>
id<CKMountable> childAtIndex(__unsafe_unretained id<CKIterable> self, unsigned int idx, First first) {
  if (idx == 0 && first != nil) {
    return first;
  }
  CKCFailAssertWithCategory([self class], @"Index out of bounds %u", [self numberOfChildren]);
  return nil;
}

template <typename First, typename... Rest>
id<CKMountable> childAtIndex(__unsafe_unretained id<CKIterable> self, unsigned int idx, First first, Rest... rest) {
  if (first != nil) {
    if (idx == 0) {
      // Found
      return first;
    } else {
      // Skip non-nil element
      return childAtIndex(self, idx - 1, rest...);
    }
  } else {
    // Skip nil element
    return childAtIndex(self, idx, rest...);
  }
}
}

#endif
