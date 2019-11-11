/*
*  Copyright (c) 2014-present, Facebook, Inc.
*  All rights reserved.
*
*  This source code is licensed under the BSD-style license found in the
*  LICENSE file in the root directory of this source tree. An additional grant
*  of patent rights can be found in the PATENTS file in the same directory.
*
*/

#import <UIKit/UIKit.h>

/** Return the mounted object of view. */
id CKMountedObjectForView(UIView *view);

/**
 Object should be set to view after it's mounted.
 This is for internal use by the framework only.
 */
void CKSetMountedObjectForView(UIView *view, id object);
