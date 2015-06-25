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
#import <ComponentKit/CKMacros.h>

struct CKStatefulViewComponentAccessibility {
  NSNumber *isAccessibilityElement;
  NSString *accessibilityLabel;
};

/**
 Used with CKStatefulViewComponentController.
 You must use +newWithSize: or +new to initialize this component. You may not specify a view.
 */
@interface CKStatefulViewComponent : CKComponent

+ (instancetype)newWithSize:(const CKComponentSize &)size
              accessibility:(const CKStatefulViewComponentAccessibility &)accessibility;

+ (instancetype)newWithView:(const CKComponentViewConfiguration &)view size:(const CKComponentSize &)size CK_NOT_DESIGNATED_INITIALIZER_ATTRIBUTE;

@end
