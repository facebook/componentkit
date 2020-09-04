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

#import <ComponentKit/CKComponentViewAttribute_SwiftBridge.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_subclassing_restricted))
NS_SWIFT_NAME(ComponentViewConfigurationSwiftBridge)
@interface CKComponentViewConfiguration_SwiftBridge : NSObject

- (instancetype)initWithViewClass:(Class)viewClass;
- (instancetype)initWithViewClass:(Class)viewClass attributes:(NSArray<CKComponentViewAttribute_SwiftBridge *> *)attributes;

@end

NS_ASSUME_NONNULL_END
