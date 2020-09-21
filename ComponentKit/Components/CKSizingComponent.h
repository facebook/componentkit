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
#import <ComponentKit/CKDefines.h>
#import <ComponentKit/CKLayoutComponent.h>
#import <ComponentKit/CKComponentSize_SwiftBridge.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(SizingComponent)
@interface CKSizingComponent : CKLayoutComponent

CK_LAYOUT_COMPONENT_INIT_UNAVAILABLE

#if CK_SWIFT

- (instancetype)initWithSwiftSize:(CKComponentSize_SwiftBridge *)swiftSize
                        component:(NS_RELEASES_ARGUMENT CKComponent *)component NS_DESIGNATED_INITIALIZER;

#else

- (instancetype _Nullable)initWithSize:(const CKComponentSize &)size
                             component:(CKComponent *)component NS_DESIGNATED_INITIALIZER;

#endif

@end

#if CK_SWIFT
#define CK_SIZING_COMPONENT_INIT_UNAVAILABLE \
- (instancetype)initWithSwiftSize:(CKComponentSize_SwiftBridge *)swiftSize \
                        component:(NS_RELEASES_ARGUMENT CKComponent *)component NS_DESIGNATED_INITIALIZER;
#else
#define CK_SIZING_COMPONENT_INIT_UNAVAILABLE \
- (instancetype _Nullable)initWithSize:(const CKComponentSize &)size \
                             component:(NS_RELEASES_ARGUMENT id<CKMountable>)component NS_DESIGNATED_INITIALIZER;
#endif

NS_ASSUME_NONNULL_END
