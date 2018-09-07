/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKRenderLayoutWithChildrenComponent.h>

#import <ComponentKit/CKMacros.h>

/**
 @uidocs https://fburl.com/CKOverlayLayoutComponent:4ad6

 This component lays out a single component and then overlays a component on top of it streched to its size
 */
@interface CKOverlayLayoutComponent : CKRenderLayoutWithChildrenComponent

+ (instancetype)newWithComponent:(CKComponent *)component
                         overlay:(CKComponent *)overlay;

+ (instancetype)newWithView:(const CKComponentViewConfiguration &)view
                       size:(const CKComponentSize &)size CK_NOT_DESIGNATED_INITIALIZER_ATTRIBUTE;

@end
