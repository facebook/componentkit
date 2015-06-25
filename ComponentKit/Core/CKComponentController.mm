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

@implementation CKComponentController
{
  CKComponentControllerState _state;
  BOOL _updatingComponent;
  CKComponent *_previousComponent;
  std::vector<CKPendingComponentAnimation> _pendingAnimations;
  std::vector<CKAppliedComponentAnimation> _appliedAnimations;
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

#pragma mark - Hooks

- (void)componentWillMount:(CKComponent *)component
{
  if (component != _component) {
    [self willUpdateComponent];
    _previousComponent = _component;
    _component = component;
    _updatingComponent = YES;
  }

  switch (_state) {
    case CKComponentControllerStateUnmounted:
      _state = CKComponentControllerStateMounting;
      [self willMount];
      break;
    case CKComponentControllerStateMounted:
      _state = CKComponentControllerStateRemounting;
      [self willRemount];
      if (_previousComponent) { // Only animate if updating from an old component to a new one, and previously mounted
        for (const auto &animation : [component animationsFromPreviousComponent:_previousComponent]) {
          _pendingAnimations.push_back({animation, animation.willRemount()});
        }
      }
      break;
    default:
      CKFailAssert(@"Unexpected state '%@' in %@ (%@)", componentStateName(_state), [self class], _component);
  }
}

- (void)componentDidMount:(CKComponent *)component
{
  switch (_state) {
    case CKComponentControllerStateMounting:
      _state = CKComponentControllerStateMounted;
      [self didMount];
      break;
    case CKComponentControllerStateRemounting:
      _state = CKComponentControllerStateMounted;
      [self didRemount];
      for (const auto &pendingAnimation : _pendingAnimations) {
        const CKComponentAnimation &anim = pendingAnimation.animation;
        _appliedAnimations.push_back({anim, anim.didRemount(pendingAnimation.context)});
      }
      _pendingAnimations.clear();
      break;
    default:
      CKFailAssert(@"Unexpected state '%@' in %@ (%@)", componentStateName(_state), [self class], _component);
  }

  if (_updatingComponent) {
    [self didUpdateComponent];
    _previousComponent = nil;
    _updatingComponent = NO;
  }
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
      CKFailAssert(@"Unexpected state '%@' in %@ (%@)", componentStateName(_state), [self class], _component);
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
      CKFailAssert(@"Unexpected state '%@' in %@ (%@)", componentStateName(_state), [self class], _component);
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
  for (const auto &appliedAnimation : _appliedAnimations) {
    appliedAnimation.animation.cleanup(appliedAnimation.context);
  }
  _appliedAnimations.clear();
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
