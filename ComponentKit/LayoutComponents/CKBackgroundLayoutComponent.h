/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKDefines.h>

#if CK_NOT_SWIFT

#import <ComponentKit/CKLayoutComponent.h>

#import <ComponentKit/CKMacros.h>

/**
 @uidocs https://fburl.com/CKBackgroundLayoutComponent:bf91

 Lays out a single child component, then lays out a background component behind it stretched to its size.
 */
@interface CKBackgroundLayoutComponent : CKLayoutComponent

/**
 @param component A child that is laid out to determine the size of this component. If this is nil, then this method
        returns nil.
 @param background A child that is laid out behind it. May be nil, in which case the background is omitted.
 */
+ (instancetype)newWithComponent:(CKComponent *)component
                      background:(CKComponent *)background;

+ (instancetype)newWithView:(const CKComponentViewConfiguration &)view
                       size:(const CKComponentSize &)size CK_NOT_DESIGNATED_INITIALIZER_ATTRIBUTE;

@end

#import <ComponentKit/BackgroundLayoutComponentBuilder.h>

#endif
