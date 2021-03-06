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

#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKMacros.h>

struct CKStatefulViewComponentAccessibility {
  NSNumber *isAccessibilityElement;
  NSString *accessibilityLabel;
  NSNumber *accessibilityTraits;
};

/**
 Used with CKStatefulViewComponentController.
 You must use +newWithSize: or +new to initialize this component. You may not specify a view.
 */
@interface CKStatefulViewComponent : CKComponent

CK_INIT_UNAVAILABLE;

CK_COMPONENT_INIT_UNAVAILABLE;

+ (instancetype)newWithSize:(const RCComponentSize &)size
              accessibility:(const CKStatefulViewComponentAccessibility &)accessibility;

@end

#define CK_STATEFUL_COMPONENT_INIT_UNAVAILABLE \
  + (instancetype)newWithSize:(const RCComponentSize &)size \
                accessibility:(const CKStatefulViewComponentAccessibility &)accessibility NS_UNAVAILABLE;

#endif
