/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <QuartzCore/QuartzCore.h>

/** Used by CKComponent internally to block animations when configuring a new or recycled view */
class CKMountAnimationGuard {
public:
  CKMountAnimationGuard(CKComponent *oldComponent, CKComponent *newComponent)
  : _blockedAnimations(blockAnimationsIfNeeded(oldComponent, newComponent)) {}

  ~CKMountAnimationGuard()
  {
    if (_blockedAnimations) {
      [CATransaction setDisableActions:NO];
    }
  }

private:
  CKMountAnimationGuard(const CKMountAnimationGuard&) = delete;
  CKMountAnimationGuard &operator=(const CKMountAnimationGuard&) = delete;
  BOOL _blockedAnimations;

  static BOOL blockAnimationsIfNeeded(CKComponent *oldComponent, CKComponent *newComponent)
  {
    if ([CATransaction disableActions]) {
      return NO; // Already blocked
    }
    if (shouldBlockAnimations(oldComponent, newComponent)) {
      [CATransaction setDisableActions:YES];
      return YES;
    }
    return NO;
  }

  static BOOL shouldBlockAnimations(CKComponent *oldComponent, CKComponent *newComponent)
  {
    // If we're configuring an entirely new view, or one where the old component has already unmounted,
    // block animation to prevent animating from an undefined previous state.
    if (oldComponent == nil) {
      return YES;
    }

    // If we do have scope frame tokens for both the old and new components, but they don't match, block animation.
    id oldScopeFrameToken = [oldComponent scopeFrameToken];
    id newScopeFrameToken = [newComponent scopeFrameToken];
    if (oldScopeFrameToken && newScopeFrameToken && ![oldScopeFrameToken isEqual:newScopeFrameToken]) {
      return YES;
    }

    // Otherwise, assume we can animate!
    return NO;
  }
};
