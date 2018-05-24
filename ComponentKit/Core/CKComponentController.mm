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

#import "CKAnimationController.h"
#import "CKComponentInternal.h"
#import "CKComponentSubclass.h"

typedef NS_ENUM(NSInteger, CKComponentControllerState) {
  CKComponentControllerStateUnmounted = 0,
  CKComponentControllerStateMounting,
  CKComponentControllerStateMounted,
  CKComponentControllerStateRemounting,
  CKComponentControllerStateUnmounting,
};

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

@implementation CKComponentControllerContext
+ (instancetype)newWithHandleAnimationsInController:(BOOL)handleAnimationsInController
{
  const auto c = [super new];
  if (c != nil) {
    c->_handleAnimationsInController = handleAnimationsInController;
  }
  return c;
}
@end

@implementation CKComponentController
{
  CKComponentControllerState _state;
  BOOL _updatingComponent;
  CKComponent *_previousComponent;
  CKAnimationController *_animationController;
}

- (instancetype)initWithComponent:(CKComponent *)component
{
  if (self = [super init]) {
    _component = component;
    const auto ctx = CKComponentContext<CKComponentControllerContext>::get();
    const auto handleAnimationsInController = (ctx == nil) ? YES : ctx.handleAnimationsInController;
    _animationController = handleAnimationsInController ? [CKAnimationController new] : nil;
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
      [_animationController componentWillStartMounting:component];
      break;
    case CKComponentControllerStateMounted:
      _state = CKComponentControllerStateRemounting;
      [self willRemount];
      [_animationController componentWillStartRemounting:component previousComponent:_previousComponent];
      break;
    default:
      if (!component.componentOrAncestorHasScopeConflict) {
        // Scope collisions cause all sorts of havoc; ignore when that happens.
        CKCAssertWithCategory(NO, NSStringFromClass([self class]), @"Unexpected state '%@' for %@", componentStateName(_state), [_component class]);
      }
  }
}

- (void)componentDidMount:(CKComponent *)component
{
  switch (_state) {
    case CKComponentControllerStateMounting:
      _state = CKComponentControllerStateMounted;
      [self didMount];
      [_animationController componentDidMount];
      break;
    case CKComponentControllerStateRemounting:
      _state = CKComponentControllerStateMounted;
      [self didRemount];
      [_animationController componentDidMount];
      break;
    default:
      if (!component.componentOrAncestorHasScopeConflict) {
        // Scope collisions cause all sorts of havoc; ignore when that happens.
        CKCAssertWithCategory(NO, NSStringFromClass([self class]), @"Unexpected state '%@' for %@", componentStateName(_state), [_component class]);
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
        [_animationController componentWillUnmount];
      }
      break;
    case CKComponentControllerStateRemounting:
      CKAssert(component != _component, @"Didn't expect the new component to be unmounting during remount");
      break;
    default:
      if (!component.componentOrAncestorHasScopeConflict) {
        // Scope collisions cause all sorts of havoc; ignore when that happens.
        CKCAssertWithCategory(NO, NSStringFromClass([self class]), @"Unexpected state '%@' for %@", componentStateName(_state), [_component class]);
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
        CKCAssertWithCategory(NO, NSStringFromClass([self class]), @"Unexpected state '%@' for %@", componentStateName(_state), [_component class]);
      }
  }
}

- (void)_relinquishView
{
  [self componentWillRelinquishView];
  [_animationController componentWillRelinquishView];
  _view = nil;
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
