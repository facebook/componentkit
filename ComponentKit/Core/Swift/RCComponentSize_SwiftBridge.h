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

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_subclassing_restricted))
NS_SWIFT_NAME(ComponentSizeSwiftBridge)
@interface RCComponentSize_SwiftBridge : NSObject

- (instancetype)initWithSize:(CGSize)size;
- (instancetype)initWithWidth:(RCDimension_SwiftBridge *_Nullable)width
                       height:(RCDimension_SwiftBridge *_Nullable)height
                     minWidth:(RCDimension_SwiftBridge *_Nullable)minWidth
                    minHeight:(RCDimension_SwiftBridge *_Nullable)minHeight
                     maxWidth:(RCDimension_SwiftBridge *_Nullable)maxWidth
                    maxHeight:(RCDimension_SwiftBridge *_Nullable)maxHeight;

@end

NS_ASSUME_NONNULL_END
