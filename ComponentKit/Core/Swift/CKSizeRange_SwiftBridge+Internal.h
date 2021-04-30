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
#import <ComponentKit/CKSizeRange_SwiftBridge.h>

#import <ComponentKit/CKSizeRange.h>

#if CK_NOT_SWIFT

NS_ASSUME_NONNULL_BEGIN

@interface CKSizeRange_SwiftBridge ()

- (instancetype)initWithSizeRange:(const CKSizeRange &)sizeRange NS_DESIGNATED_INITIALIZER;

- (const CKSizeRange &)sizeRange;

@end

NS_ASSUME_NONNULL_END

#endif
