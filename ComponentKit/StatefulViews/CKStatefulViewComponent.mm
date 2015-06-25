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
  // We need a component-created view in the hierarchy to serve as the stateful view's parent to ensure proper ordering.
  // This is a temporary solution to add accessibility to stateful view components because
  // the current feed accessibilityLabel aggregator searches the component tree for accessiblity contexts
  return [super newWithView:
          {
            [UIView class],
            {},
            {
              .isAccessibilityElement = accessibility.isAccessibilityElement,
              .accessibilityLabel = accessibility.accessibilityLabel,
            },
          }
                       size:size];
}

@end
