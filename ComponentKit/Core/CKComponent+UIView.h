/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKDefines.h>

#if CK_NOT_SWIFT

#import <UIKit/UIKit.h>

@class CKComponent;

#ifndef __cplusplus
#error This file must be compiled as Obj-C++. If you are importing it, you must change your file extension to .mm.
#endif

NSString *CKLastMountedComponentClassNameForView(UIView *view);

/** Strong reference back to the associated component while the component is mounted. */
CKComponent *CKMountedComponentForView(UIView *view);

/** This is for internal use by the framework only. */
void CKSetMountedComponentForView(UIView *view, CKComponent *component);

#endif
