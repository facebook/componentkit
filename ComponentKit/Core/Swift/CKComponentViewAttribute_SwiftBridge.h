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
#import <UIKit/UIKit.h>
#import <ComponentKit/CKComponentViewAttribute.h>
#import <ComponentKit/CKAction_SwiftBridge.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_CLOSED_ENUM(NSInteger, CKComponentViewAttributeGesture_SwiftBridge) {
  CKComponentViewAttributeGesture_SwiftBridgeTap,
  CKComponentViewAttributeGesture_SwiftBridgePan,
  CKComponentViewAttributeGesture_SwiftBridgeLongPress,
} NS_SWIFT_NAME(ComponentViewAttributeSwiftBridge.Gesture);

__attribute__((objc_subclassing_restricted))
NS_SWIFT_NAME(ComponentViewAttributeSwiftBridge)
@interface CKComponentViewAttribute_SwiftBridge : NSObject

- (instancetype)initWithIdentifier:(NSString *)identifier applicator:(void(^)(UIView *))applicator;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithGesture:(CKComponentViewAttributeGesture_SwiftBridge)gesture swiftAction:(CKActionWithId_SwiftBridge)swiftAction;

@end

NS_ASSUME_NONNULL_END
