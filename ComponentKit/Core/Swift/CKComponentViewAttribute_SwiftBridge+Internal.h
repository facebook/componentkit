/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKComponentViewAttribute_SwiftBridge.h>
#import <ComponentKit/CKDefines.h>
#import <ComponentKit/CKComponentViewAttribute.h>

NS_ASSUME_NONNULL_BEGIN

#if CK_NOT_SWIFT

@interface CKComponentViewAttribute_SwiftBridge ()

- (instancetype)initWithViewAttribute:(const CKComponentViewAttribute &)viewAttribute NS_DESIGNATED_INITIALIZER;

- (const CKComponentViewAttribute &)viewAttribute;

@end

auto CKComponentViewAttribute_SwiftBridgeToMap(NSArray<CKComponentViewAttribute_SwiftBridge *> *_Nullable swiftAttributes) -> CKViewComponentAttributeValueMap;

#endif

NS_ASSUME_NONNULL_END
