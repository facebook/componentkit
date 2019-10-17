/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKMountable+UIView.h"

#import <objc/runtime.h>

static char const kViewComponentKey = ' ';

/** Strong reference back to the associated CKMountable while the component is mounted. */
id<CKMountable> CKMountableForView(UIView *view)
{
  return objc_getAssociatedObject(view, &kViewComponentKey);
}

/** This is for internal use by the framework only. */
void CKSetMountableForView(UIView *view, id<CKMountable> component)
{
  objc_setAssociatedObject(view, &kViewComponentKey, component, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
