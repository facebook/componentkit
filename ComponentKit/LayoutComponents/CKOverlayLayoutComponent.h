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
 @uidocs https://fburl.com/CKOverlayLayoutComponent:4ad6

 This component lays out a single component and then overlays a component on top of it streched to its size
 */
@interface CKOverlayLayoutComponent : CKLayoutComponent

CK_INIT_UNAVAILABLE;

CK_LAYOUT_COMPONENT_INIT_UNAVAILABLE;

+ (instancetype)newWithComponent:(CKComponent *)component
                         overlay:(CKComponent *)overlay;

@end

#import <ComponentKit/OverlayLayoutComponentBuilder.h>

#endif
