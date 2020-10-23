/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, CKComponentBasedAccessibilityMode) {
  CKComponentBasedAccessibilityModeDisabled = 0,
  CKComponentBasedAccessibilityModeEnabledOnSurface, // Indicate that the feature only works on selected surfaces
  CKComponentBasedAccessibilityModeEnabled,
};

NS_ASSUME_NONNULL_END
