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

#import "CKComponent.h"
#import "CKMountable+UIView.h"

/** Strong reference back to the associated component while the component is mounted. */
CKComponent *CKMountedComponentForView(UIView *view)
{
  return (CKComponent *)CKMountableForView(view);
}

/** This is for internal use by the framework only. */
void CKSetMountedComponentForView(UIView *view, CKComponent *component)
{
  CKSetMountableForView(view, component);
}
