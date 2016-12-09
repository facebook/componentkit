/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <Availability.h>
#import <AvailabilityInternal.h>

#import <CoreFoundation/CFBase.h>

#define CK_AT_LEAST_IOS8 (kCFCoreFoundationVersionNumber > 847.27)
#define CK_AT_LEAST_IOS8_2 (kCFCoreFoundationVersionNumber >= 1142.16)
#define CK_AT_LEAST_IOS9 (kCFCoreFoundationVersionNumber >= 1223.1)
#define CK_AT_LEAST_IOS10_BETA_4 (kCFCoreFoundationVersionNumber >= 1345.0)
