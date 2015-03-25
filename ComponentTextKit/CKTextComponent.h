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

#import <ComponentKit/CKTextKitAttributes.h>

struct CKTextComponentAccessibilityContext
{
  NSNumber *isAccessibilityElement;
  NSString *accessibilityIdentifier;
  NSNumber *providesAccessibleElements;
  /**
   Should rarely be used, the component's text will be used by default.
   */
  CKComponentAccessibilityTextAttribute accessibilityLabel;
};

@interface CKTextComponent : CKComponent

+ (instancetype)newWithTextAttributes:(const CKTextKitAttributes &)attributes
                       viewAttributes:(const CKViewComponentAttributeValueMap &)viewAttributes
                 accessibilityContext:(const CKTextComponentAccessibilityContext &)accessibilityContext;

@end
