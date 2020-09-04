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
NS_SWIFT_NAME(ComponentSizeSwiftBridge)
@interface CKComponentSize_SwiftBridge : NSObject

- (instancetype)initWithSize:(CGSize)size;
- (instancetype)initWithWidth:(CKDimension_SwiftBridge *_Nullable)width
                       height:(CKDimension_SwiftBridge *_Nullable)height
                     minWidth:(CKDimension_SwiftBridge *_Nullable)minWidth
                    minHeight:(CKDimension_SwiftBridge *_Nullable)minHeight
                     maxWidth:(CKDimension_SwiftBridge *_Nullable)maxWidth
                    maxHeight:(CKDimension_SwiftBridge *_Nullable)maxHeight;

@end

NS_ASSUME_NONNULL_END
