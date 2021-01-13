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
  static BOOL blockAnimationsIfNeeded(id<CKMountable> oldComponent, id<CKMountable> newComponent,
                                      const CK::Component::MountContext &ctx,
                                      const CKComponentViewConfiguration &viewConfig) noexcept
  {
    if (shouldBlockAnimations(oldComponent, newComponent, ctx, viewConfig)) {
      [CATransaction setDisableActions:YES];
      return YES;
    }
    return NO;
  }
  
  static void unblockAnimation() {
    [CATransaction setDisableActions:NO];
  }
  
private:
  static BOOL shouldBlockAnimations(id<CKMountable> oldComponent, id<CKMountable> newComponent,
                                    const CK::Component::MountContext &ctx,
                                    const CKComponentViewConfiguration &viewConfig) noexcept
  {
    if ([CATransaction disableActions]) {
      return NO; // Already blocked
    }
    // If the context explicitly tells us to block animations, do it.
    if (ctx.shouldBlockAnimations) {
      return YES;
    }

    if (viewConfig.blockImplicitAnimations()) {
      return YES;
    }

    // If we're configuring an entirely new view, or one where the old component has already unmounted,
    // block animation to prevent animating from an undefined previous state.
    if (oldComponent == nil) {
      return YES;
    }

    // If we do have scope frame tokens for both the old and new components, but they don't match, block animation.
    id oldUniqueIdentifier = [oldComponent uniqueIdentifier];
    id newUniqueIdentifier = [newComponent uniqueIdentifier];
    if (oldUniqueIdentifier && newUniqueIdentifier && ![oldUniqueIdentifier isEqual:newUniqueIdentifier]) {
      return YES;
    }

    // Otherwise, assume we can animate!
    return NO;
  }
};
