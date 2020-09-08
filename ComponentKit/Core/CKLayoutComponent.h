/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <UIKit/UIKit.h>

#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKIterableHelpers.h>

/** This component should be used on non-leaf components with a custom layout . */
@interface CKLayoutComponent : CKComponent

@end

#define CK_LAYOUT_COMPONENT_INIT_UNAVAILABLE CK_COMPONENT_INIT_UNAVAILABLE

