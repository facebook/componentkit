/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKComponent.h>

/**
 Lays out a single child component, then lays out a background component behind it stretched to its size.
 */
@interface CKBackgroundLayoutComponent : CKComponent

/**
 @param component A child that is laid out to determine the size of this component. If this is nil, then this method
        returns nil.
 @param background A child that is laid out behind it. May be nil, in which case the background is omitted.
 */
+ (instancetype)newWithComponent:(CKComponent *)component
                      background:(CKComponent *)background;

@end
