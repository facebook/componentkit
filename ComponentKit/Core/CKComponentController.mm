/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentController.h"
#import "CKComponentControllerInternal.h"

#import <ComponentKit/CKAssert.h>

#import "CKComponentInternal.h"
#import "CKComponentSubclass.h"

struct CKPendingComponentAnimation {
  CKComponentAnimation animation;
  id context; // The context returned by the animation's willRemount block.
};

struct CKAppliedComponentAnimation {
  CKComponentAnimation animation;
  id context; // The context returned by the animation's didRemount block.
};

typedef NS_ENUM(NSUInteger, CKComponentControllerState) {
  CKComponentControllerStateUnmounted = 0,
  CKComponentControllerStateMounting,
  CKComponentControllerStateMounted,
  CKComponentControllerStateRemounting,
  CKComponentControllerStateUnmounting,
};

typedef size_t CKComponentAnimationID;
typedef std::unordered_map<CKComponentAnimationID, CKAppliedComponentAnimation> CKAppliedComponentAnimationMap;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-function"
static NSString *componentStateName(CKComponentControllerState state)
{
  switch (state) {
    case CKComponentControllerStateUnmounted:
      return @"unmounted";
    case CKComponentControllerStateMounting:
      return @"mounting";
    case CKComponentControllerStateMounted:
      return @"mounted";
    case CKComponentControllerStateRemounting:
      return @"remounting";
    case CKComponentControllerStateUnmounting:
      return @"unmounting";
  };
}
#pragma clang diagnostic pop

static void eraseAnimation(CKAppliedComponentAnimationMap &map, CKComponentAnimationID animationID)
{
  auto it = map.find(animationID);
  if (it != map.end()) {
    const CKAppliedComponentAnimation &appliedAnim = it->second;
    appliedAnim.animation.cleanup(appliedAnim.context);
    map.erase(it);
  }
}

struct CKComponentControllerAnimationData {
  CKComponentAnimationID nextAnimationID;
  std::vector<CKPendingComponentAnimation> pendingAnimationsOnInitialMount;
  CKAppliedComponentAnimationMap appliedAnimationsOnInitialMount;
  std::vector<CKPendingComponentAnimation> pendingAnimations;
  CKAppliedComponentAnimationMap appliedAnimations;
};

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

@implementation CKComponentController
{
  CKComponentControllerState _state;
  BOOL _updatingComponent;
  BOOL _performedInitialMount;
  CKComponent *_previousComponent;
  CKComponentControllerAnimationWrapper _animationData;
}

- (instancetype)initWithComponent:(CKComponent *)component
{
  if (self = [super init]) {
    _component = component;
  }
  return self;
}

- (void)willMount {}
- (void)didMount {}
- (void)willRemount {}
- (void)didRemount {}
- (void)willUnmount {}
- (void)didUnmount {}
- (void)willUpdateComponent {}
- (void)didUpdateComponent {}
- (void)componentWillRelinquishView {}
- (void)componentDidAcquireView {}
- (void)componentTreeWillAppear {}
- (void)componentTreeDidDisappear {}
- (void)invalidateController {}
- (void)didPrepareLayout:(const CKComponentLayout &)layout forComponent:(CKComponent *)component {}

#pragma mark - Hooks

- (void)willStartUpdateToComponent:(CKComponent *)component
{
  if (component != _component) {
    [self willUpdateComponent];
    _previousComponent = _component;
    _component = component;
    _updatingComponent = YES;
  }
}

- (void)didFinishComponentUpdate
{
  if (_updatingComponent) {
    [self didUpdateComponent];
    _previousComponent = nil;
    _updatingComponent = NO;
  }
}

- (void)componentWillMount:(CKComponent *)component
{
  [self willStartUpdateToComponent:component];

  switch (_state) {
    case CKComponentControllerStateUnmounted:
      _state = CKComponentControllerStateMounting;
      [self willMount];
      if (!_performedInitialMount) {
        _performedInitialMount = YES;
        for (const auto &animation : [component animationsOnInitialMount]) {
          _animationData->pendingAnimationsOnInitialMount.push_back({animation, animation.willRemount()});
        }
      }
      break;
    case CKComponentControllerStateMounted:
      _state = CKComponentControllerStateRemounting;
      [self willRemount];
      if (_previousComponent) { // Only animate if updating from an old component to a new one, and previously mounted
        for (const auto &animation : [component animationsFromPreviousComponent:_previousComponent]) {
          _animationData->pendingAnimations.push_back({animation, animation.willRemount()});
        }
      }
      break;
    default:
      if (!component.componentOrAncestorHasScopeConflict) {
        // Scope collisions cause all sorts of havoc; ignore when that happens.
        CKFailAssert(@"Unexpected state '%@' in %@ (%@)", componentStateName(_state), [self class], _component);
      }
  }
}

- (void)componentDidMount:(CKComponent *)component
{
  switch (_state) {
    case CKComponentControllerStateMounting:
      _state = CKComponentControllerStateMounted;
      [self didMount];
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
      }
      break;
    case CKComponentControllerStateRemounting:
      _state = CKComponentControllerStateMounted;
      [self didRemount];
      if (_animationData) {
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
      break;
    default:
      if (!component.componentOrAncestorHasScopeConflict) {
        // Scope collisions cause all sorts of havoc; ignore when that happens.
        CKFailAssert(@"Unexpected state '%@' in %@ (%@)", componentStateName(_state), [self class], _component);
      }
  }

  [self didFinishComponentUpdate];
}

- (void)componentWillUnmount:(CKComponent *)component
{
  switch (_state) {
    case CKComponentControllerStateMounted:
      // The "old" version of a component may be unmounted after the new version has finished remounting.
      if (component == _component) {
        _state = CKComponentControllerStateUnmounting;
        [self willUnmount];
        [self _cleanupAppliedAnimations];
      }
      break;
    case CKComponentControllerStateRemounting:
      CKAssert(component != _component, @"Didn't expect the new component to be unmounting during remount");
      break;
    default:
      if (!component.componentOrAncestorHasScopeConflict) {
        // Scope collisions cause all sorts of havoc; ignore when that happens.
        CKFailAssert(@"Unexpected state '%@' in %@ (%@)", componentStateName(_state), [self class], _component);
      }
  }
}

- (void)componentDidUnmount:(CKComponent *)component
{
  switch (_state) {
    case CKComponentControllerStateUnmounting:
      CKAssert(component == _component, @"Unexpected component mismatch during unmount from unmounting");
      _state = CKComponentControllerStateUnmounted;
      [self didUnmount];
      break;
    case CKComponentControllerStateRemounting:
      CKAssert(component != _component, @"Didn't expect the new component to be unmounted during remount");
      break;
    case CKComponentControllerStateMounted:
      CKAssert(component != _component, @"Didn't expect the new component to be unmounted while mounted");
      break;
    default:
      if (!component.componentOrAncestorHasScopeConflict) {
        // Scope collisions cause all sorts of havoc; ignore when that happens.
        CKFailAssert(@"Unexpected state '%@' in %@ (%@)", componentStateName(_state), [self class], _component);
      }
  }
}

- (void)_relinquishView
{
  [self componentWillRelinquishView];
  [self _cleanupAppliedAnimations];
  _view = nil;
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

- (void)component:(CKComponent *)component willRelinquishView:(UIView *)view
{
  if (component == _component) {
    CKAssert(view == _view, @"Didn't expect to be relinquishing view %@ when _view is %@", view, _view);
    [self _relinquishView];
  }
}

- (void)component:(CKComponent *)component didAcquireView:(UIView *)view
{
  if (component == _component) {
    if (view != _view) {
      if (_view) {
        CKAssertNotNil(_previousComponent, @"Only expect to acquire a new view before relinquishing old if updating");
        [self _relinquishView];
      }
      _view = view;
      [self componentDidAcquireView];
    }
  }
}

- (id)nextResponder
{
  return [_component nextResponderAfterController];
}

- (id)targetForAction:(SEL)action withSender:(id)sender
{
  return [self canPerformAction:action withSender:sender] ? self : [[self nextResponder] targetForAction:action withSender:sender];
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
  return [self respondsToSelector:action];
}

@end
