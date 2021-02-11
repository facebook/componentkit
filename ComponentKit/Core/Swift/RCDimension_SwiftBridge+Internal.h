/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/RCDimension_SwiftBridge.h>
#import <ComponentKit/CKDefines.h>
#import <RenderCore/RCDimension.h>

NS_ASSUME_NONNULL_BEGIN

#if CK_NOT_SWIFT

@interface RCDimension_SwiftBridge ()

- (instancetype)initWithDimension:(const RCRelativeDimension &)dimension NS_DESIGNATED_INITIALIZER;

- (const RCRelativeDimension &)dimension;

@end

#endif

NS_ASSUME_NONNULL_END
