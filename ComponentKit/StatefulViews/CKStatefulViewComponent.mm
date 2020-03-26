/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKStatefulViewComponent.h"

@implementation CKStatefulViewComponent

+ (instancetype)newWithView:(const CKComponentViewConfiguration &)view size:(const CKComponentSize &)size
{
  [NSException raise:NSInvalidArgumentException format:@"Not designated initializer."];
  return nil;
}

+ (instancetype)newWithSize:(const CKComponentSize &)size
              accessibility:(const CKStatefulViewComponentAccessibility &)accessibility
{
  return
  [super
   newWithView:
   {
     {
       // CK infra will infer [UIView class] on mount when accessibility is enabled.
     },
     {},
     {
       .isAccessibilityElement = accessibility.isAccessibilityElement,
       .accessibilityLabel = accessibility.accessibilityLabel,
       .accessibilityTraits = accessibility.accessibilityTraits,
     },
   }
   size:size];
}

@end
