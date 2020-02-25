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

#import <ComponentKit/CKMountedObjectForView.h>
#import <ComponentKit/CKComponent.h>
#import <RenderCore/CKAssociatedObject.h>

#if CK_ASSERTIONS_ENABLED
static const void *kMountedComponentClassNameKey = nullptr;
#endif

/** Strong reference back to the associated component while the component is mounted. */
NSString *CKLastMountedComponentClassNameForView(UIView *view)
{
#if CK_ASSERTIONS_ENABLED
  return CKGetAssociatedObject_MainThreadAffined(view, &kMountedComponentClassNameKey);
#else
  return nil;
#endif
}

/** Strong reference back to the associated component while the component is mounted. */
CKComponent *CKMountedComponentForView(UIView *view)
{
  return (CKComponent *)CKMountedObjectForView(view);
}

/** This is for internal use by the framework only. */
void CKSetMountedComponentForView(UIView *view, CKComponent *component)
{
  CKSetMountedObjectForView(view, component);
#if CK_ASSERTIONS_ENABLED
  if (component != nil) {
    // We want to know which component was last mounted - do not clean this up.
    CKSetAssociatedObject_MainThreadAffined(view, &kMountedComponentClassNameKey, component.className);
  }
#endif
}
