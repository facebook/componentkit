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

#import <ComponentKit/CKComponentSizeRangeProviding.h>

NS_ASSUME_NONNULL_BEGIN

@interface CKBlockSizeRangeProvider : NSObject<CKComponentSizeRangeProviding>

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithBlock:(CKComponentSizeRangeProviderBlock)srp NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
