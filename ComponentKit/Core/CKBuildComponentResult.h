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

#import <Foundation/Foundation.h>

#import <ComponentKit/CKBuildTrigger.h>
#import <ComponentKit/CKComponentBoundsAnimation.h>

@class CKComponent;
@class CKComponentScopeRoot;

/**
 The results of a build operation.

 A bounds animations are returned in this method if a component in the hierarchy requested an animation from its prior
 state. These animations should be applied with CKComponentBoundsAnimationApply.
 */
struct CKBuildComponentResult {
  CKComponent *component;
  CKComponentScopeRoot *scopeRoot;
  CKComponentBoundsAnimation boundsAnimation;
  CKBuildTrigger buildTrigger;
};

#endif
