/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKAnimationController.h"

#import "CKComponentAnimationData.h"
#import "CKComponentSubclass.h"

static void eraseAnimation(CKAppliedComponentAnimationMap &map, CKComponentAnimationID animationID)
{
  auto it = map.find(animationID);
  if (it != map.end()) {
    const CKAppliedComponentAnimation &appliedAnim = it->second;
    appliedAnim.animation.cleanup(appliedAnim.context);
    map.erase(it);
  }
}

struct CKComponentControllerAnimationWrapper {
public:
  CKComponentControllerAnimationData *operator->() {
    if (_animationData == nullptr) {
      _animationData.reset(new CKComponentControllerAnimationData());
    }
    return _animationData.get();
  };

  explicit operator bool() const {
    return _animationData != nullptr;
  };
private:
  std::unique_ptr<CKComponentControllerAnimationData> _animationData;
};

@implementation CKAnimationController {
  BOOL _performedInitialMount;
  CKComponentControllerAnimationWrapper _animationData;
}

- (void)componentWillStartMounting:(CKComponent * const _Nonnull)component
{
  if (!_performedInitialMount) {
    _performedInitialMount = YES;
    for (const auto &animation : [component animationsOnInitialMount]) {
      _animationData->pendingAnimationsOnInitialMount.push_back({animation, animation.willRemount()});
    }
  }
}

- (void)componentWillStartRemounting:(CKComponent * const _Nonnull)component
                   previousComponent:(CKComponent * const _Nullable)prevComponent
{
  if (prevComponent) { // Only animate if updating from an old component to a new one, and previously mounted
    for (const auto &animation : [component animationsFromPreviousComponent:prevComponent]) {
      _animationData->pendingAnimations.push_back({animation, animation.willRemount()});
    }
  }
}

- (void)componentDidMount
{
  if (_animationData) {
    for (const auto &pendingAnimation : _animationData->pendingAnimationsOnInitialMount) {
      const CKComponentAnimation &anim = pendingAnimation.animation;
      [CATransaction begin];
      CKComponentAnimationID animationID = _animationData->nextAnimationID++;
      [CATransaction setCompletionBlock:^() {
        eraseAnimation(_animationData->appliedAnimationsOnInitialMount, animationID);
      }];
      _animationData->appliedAnimationsOnInitialMount.insert({animationID, {anim, anim.didRemount(pendingAnimation.context)}});
      [CATransaction commit];
    }
    _animationData->pendingAnimationsOnInitialMount.clear();

    for (const auto &pendingAnimation : _animationData->pendingAnimations) {
      const CKComponentAnimation &anim = pendingAnimation.animation;
      [CATransaction begin];
      CKComponentAnimationID animationID = _animationData->nextAnimationID++;
      [CATransaction setCompletionBlock:^() {
        eraseAnimation(_animationData->appliedAnimations, animationID);
      }];
      _animationData->appliedAnimations.insert({animationID, {anim, anim.didRemount(pendingAnimation.context)}});
      [CATransaction commit];
    }
    _animationData->pendingAnimations.clear();
  }
}

- (void)componentWillUnmount
{
  [self _cleanupAppliedAnimations];
}

- (void)componentWillRelinquishView
{
  [self _cleanupAppliedAnimations];
}

- (void)_cleanupAppliedAnimations
{
  if (_animationData) {
    for (const auto &appliedAnimation : _animationData->appliedAnimationsOnInitialMount) {
      appliedAnimation.second.animation.cleanup(appliedAnimation.second.context);
    }
    _animationData->appliedAnimationsOnInitialMount.clear();
    for (const auto &appliedAnimation : _animationData->appliedAnimations) {
      appliedAnimation.second.animation.cleanup(appliedAnimation.second.context);
    }
    _animationData->appliedAnimations.clear();
  }
}

@end
