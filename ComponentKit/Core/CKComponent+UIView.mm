/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponent+UIView.h"

#import <objc/runtime.h>

static char const kViewComponentKey = ' ';

@implementation UIView (CKComponent)

- (CKComponent *)ck_component
{
  return objc_getAssociatedObject(self, &kViewComponentKey);
}

- (void)ck_setComponent:(CKComponent *)component
{
  objc_setAssociatedObject(self, &kViewComponentKey, component, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
