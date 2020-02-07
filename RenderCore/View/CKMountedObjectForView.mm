/*
*  Copyright (c) 2014-present, Facebook, Inc.
*  All rights reserved.
*
*  This source code is licensed under the BSD-style license found in the
*  LICENSE file in the root directory of this source tree. An additional grant
*  of patent rights can be found in the PATENTS file in the same directory.
*
*/

#import "CKMountedObjectForView.h"

#import <objc/runtime.h>

#import <RenderCore/CKAssociatedObject.h>

static char const kMountedObjectKey = ' ';

id CKMountedObjectForView(UIView *view)
{
  return CKGetAssociatedObject_MainThreadAffined(view, &kMountedObjectKey);
}

void CKSetMountedObjectForView(UIView *view, id object)
{
  CKSetAssociatedObject_MainThreadAffined(view, &kMountedObjectKey, object);
}
