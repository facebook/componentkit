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

#define RC_AT_LEAST_IOS9 (kCFCoreFoundationVersionNumber >= 1223.1)
#define RC_AT_LEAST_IOS10_BETA_4 (kCFCoreFoundationVersionNumber >= 1345.0)
#define RC_AT_LEAST_IOS11 (kCFCoreFoundationVersionNumber >= 1429.15)
#define RC_AT_LEAST_IOS11_3 (kCFCoreFoundationVersionNumber >= 1452.23)
#define RC_AT_LEAST_IOS12 (kCFCoreFoundationVersionNumber >= 1556.00)
