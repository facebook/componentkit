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

#import <ComponentKit/CKComponent.h>

/**
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
@interface CKRatioLayoutComponent : CKComponent

+ (instancetype)newWithRatio:(CGFloat)ratio
                        size:(const CKComponentSize &)size
                   component:(CKComponent *)component;

@end
