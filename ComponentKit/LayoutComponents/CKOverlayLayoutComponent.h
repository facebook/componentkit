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
 This component lays out a single component and then overlays a component on top of it streched to its size
 */
@interface CKOverlayLayoutComponent : CKComponent

+ (instancetype)newWithComponent:(CKComponent *)component
                         overlay:(CKComponent *)overlay;

@end
