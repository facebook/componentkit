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

#import <ComponentKit/CKLayoutComponent.h>

NS_ASSUME_NONNULL_BEGIN

/**
 @uidocs https://fburl.com/CKRatioLayoutComponent:b4d0

 Ratio layout component
 For when the content should respect a certain inherent ratio but can be scaled (think photos or videos)
 The ratio passed is the ratio of height / width you expect

 For a ratio 0.5, the component will have a flat rectangle shape
  _ _ _ _
 |       |
 |_ _ _ _|

 For a ratio 2.0, the component will be twice as tall as it is wide
  _ _
 |   |
 |   |
 |   |
 |_ _|

 **/
NS_SWIFT_NAME(RatioLayoutComponent)
@interface CKRatioLayoutComponent : CKLayoutComponent

CK_INIT_UNAVAILABLE;

CK_LAYOUT_COMPONENT_INIT_UNAVAILABLE;

#if CK_SWIFT

- (instancetype)initWithRatio:(CGFloat)ratio
                    swiftSize:(CKComponentSize_SwiftBridge *_Nullable)swiftSize
                    component:(CKComponent *)component NS_DESIGNATED_INITIALIZER;

#else

- (instancetype)initWithRatio:(CGFloat)ratio
                         size:(const CKComponentSize &)size
                    component:(CKComponent *_Nullable)component NS_DESIGNATED_INITIALIZER;

// DEPRECATED - Do not use. Use CK::RatioLayoutComponentBuilder instead.
+ (instancetype)newWithRatio:(CGFloat)ratio
                        size:(const CKComponentSize &)size
                   component:(CKComponent *_Nullable)component;

#endif

@end

NS_ASSUME_NONNULL_END

#import <ComponentKit/RatioLayoutComponentBuilder.h>
