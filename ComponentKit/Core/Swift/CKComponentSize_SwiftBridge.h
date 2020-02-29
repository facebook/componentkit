/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKDimension_SwiftBridge.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_subclassing_restricted))
NS_SWIFT_NAME(ComponentSize)
@interface CKComponentSize_SwiftBridge : NSObject

- (instancetype)initWithSize:(CGSize)size;
- (instancetype)initWithWidth:(CKDimension_SwiftBridge *)width
                       height:(CKDimension_SwiftBridge *)height
                     minWidth:(CKDimension_SwiftBridge *)minWidth
                    minHeight:(CKDimension_SwiftBridge *)minHeight
                     maxWidth:(CKDimension_SwiftBridge *)maxWidth
                    maxHeight:(CKDimension_SwiftBridge *)maxHeight;

@end

NS_ASSUME_NONNULL_END
