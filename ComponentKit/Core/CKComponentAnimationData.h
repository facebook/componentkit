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

#ifndef CKComponentAnimationData_h
#define CKComponentAnimationData_h

#import <unordered_map>
#import <vector>

#import <ComponentKit/CKComponentAnimation.h>

struct CKPendingComponentAnimation {
  CKComponentAnimation animation;
  id context; // The context returned by the animation's willRemount block.
};

struct CKAppliedComponentAnimation {
  CKComponentAnimation animation;
  id context; // The context returned by the animation's didRemount block.
};

typedef size_t CKComponentAnimationID;
typedef std::unordered_map<CKComponentAnimationID, CKAppliedComponentAnimation> CKAppliedComponentAnimationMap;

struct CKComponentControllerAnimationData {
  CKComponentAnimationID nextAnimationID;
  std::vector<CKPendingComponentAnimation> pendingAnimationsOnInitialMount;
  CKAppliedComponentAnimationMap appliedAnimationsOnInitialMount;
  std::vector<CKPendingComponentAnimation> pendingAnimations;
  CKAppliedComponentAnimationMap appliedAnimations;
};

#endif /* CKComponentAnimationData_h */

#endif
