/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKComponentViewConfiguration_SwiftBridge.h>

#import <ComponentKit/CKComponentViewConfiguration.h>

NS_ASSUME_NONNULL_BEGIN

@interface CKComponentViewConfiguration_SwiftBridge ()

- (instancetype)initWithViewConfiguration:(const CKComponentViewConfiguration &)viewConfig NS_DESIGNATED_INITIALIZER;

- (const CKComponentViewConfiguration &)viewConfig;

@end

NS_ASSUME_NONNULL_END
