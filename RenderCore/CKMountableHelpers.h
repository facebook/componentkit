/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <RenderCore/CKDefines.h>

#if CK_NOT_SWIFT

#import <UIKit/UIKit.h>

#ifndef __cplusplus
#error This file must be compiled as Obj-C++. If you are importing it, you must change your file extension to .mm.
#endif

#import <RenderCore/ComponentMountContext.h>

@protocol CKMountable;
struct RCLayout;
struct CKMountInfo;
struct CKViewConfiguration;

using CKMountCallbackFunction = void(*)(id<CKMountable> mountable, UIView *view);

/**
 The CKMountable protocol requires implementing the mounting method
 `-mountInContext:layout:supercomponent:`. In practice most implementations
 can use this helper function to perform the mounting operation.

 @param mountInfo The storage for CKMountInfo; usually this will be an ivar
 from the class that conforms to CKMountable.
 */
CK::Component::MountResult CKPerformMount(std::unique_ptr<CKMountInfo> &mountInfo,
                                          const RCLayout &layout,
                                          const CKViewConfiguration &viewConfiguration,
                                          const CK::Component::MountContext &context,
                                          const id<CKMountable> supercomponent,
                                          const CKMountCallbackFunction didAcquireViewFunction,
                                          const CKMountCallbackFunction willRelinquishViewFunction);

/**
 Similar to CKPerformMount: a standard implementation of unmounting that can
 be used by most classes conforming to CKMountable.
 */
void CKPerformUnmount(std::unique_ptr<CKMountInfo> &mountInfo,
                      const id<CKMountable> mountable,
                      const CKMountCallbackFunction willRelinquishViewFunction);

/** A helper function to set view position and bounds during mount. */
void CKSetViewPositionAndBounds(UIView *v,
                                const CK::Component::MountContext &context,
                                const CGSize size);

#endif
