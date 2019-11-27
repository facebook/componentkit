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

#import <mutex>

#import <ComponentKit/CKAssert.h>

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

@implementation CKComponentController
{
  CKComponentControllerState _state;
  BOOL _updatingComponent;
  __weak CKComponent *_component;
  // Protects `_component` and `_latestComponent` when `threadSafe_component` is called.
  std::mutex _componentMutex;
#if CK_ASSERTIONS_ENABLED
  __weak NSThread *_initializationThread;
#endif
}

- (instancetype)initWithComponent:(CKComponent *)component
{
  if (self = [super init]) {
    _component = component;
#if CK_ASSERTIONS_ENABLED
    _initializationThread = [NSThread currentThread];
#endif
  }
  return self;
}

- (void)setLatestComponent:(CKComponent *)latestComponent
{
  CKAssertMainThread();
  if (latestComponent != _latestComponent) {
    [self willUpdateComponent];
    if ([self.class shouldAcquireLockWhenUpdatingComponent]) {
      std::lock_guard<std::mutex> lock(_componentMutex);
      _latestComponent = latestComponent;
      _updatingComponent = YES;
    } else {
      _latestComponent = latestComponent;
      _updatingComponent = YES;
    }
  }
}

- (CKComponent *)component
{
#if CK_ASSERTIONS_ENABLED
  if (_initializationThread != [NSThread currentThread]) {
    CKAssertWithCategory([NSThread isMainThread],
                         NSStringFromClass(self.class),
                         @"`self.component` must be called on the main thread");
  }
#endif
  return _component ?: _latestComponent;
}

- (CKComponent *)lastMountedComponent
{
  return _component;
}

- (CKComponent *)threadSafe_component
{
  if ([NSThread isMainThread]) {
    return _component ?: _latestComponent;
  } else {
    CKAssert([self.class shouldAcquireLockWhenUpdatingComponent],
             @"threadSafe_component should only be called when updating component is thread safe as well");
    std::lock_guard<std::mutex> lock(_componentMutex);
    return _component ?: _latestComponent;
  }
}

+ (BOOL)shouldAcquireLockWhenUpdatingComponent
{
  return CKReadGlobalConfig().shouldAcquireLockWhenUpdatingComponentInController;
}

- (void)didInit {}
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
  // We need to check `_updatingComponent` so that `willUpdateComponent` will be triggered if `_latestComponent`
  // is not updated after component build.
  if (!_updatingComponent) {
    if (component != _component) {
      [self willUpdateComponent];
      if ([self.class shouldAcquireLockWhenUpdatingComponent]) {
        std::lock_guard<std::mutex> lock(_componentMutex);
        _component = component;
        _updatingComponent = YES;
      } else {
        _component = component;
        _updatingComponent = YES;
      }
    }
  } else {
    if ([self.class shouldAcquireLockWhenUpdatingComponent]) {
      std::lock_guard<std::mutex> lock(_componentMutex);
      _component = component;
    } else {
      _component = component;
    }
  }
}

- (void)didFinishComponentUpdate
{
  if (_updatingComponent) {
    [self didUpdateComponent];
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
      break;
    case CKComponentControllerStateMounted:
      _state = CKComponentControllerStateRemounting;
      [self willRemount];
      break;
    default:
      CKCAssertWithCategory(NO, NSStringFromClass([self class]), @"Unexpected state '%@' for %@", componentStateName(_state), [_component class]);
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
      break;
    default:
     CKCAssertWithCategory(NO, NSStringFromClass([self class]), @"Unexpected state '%@' for %@", componentStateName(_state), [_component class]);
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
      }
      break;
    case CKComponentControllerStateRemounting:
      CKAssert(component != _component, @"Didn't expect the new component to be unmounting during remount");
      break;
    default:
      CKCAssertWithCategory(NO, NSStringFromClass([self class]), @"Unexpected state '%@' for %@", componentStateName(_state), [_component class]);
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
      CKCAssertWithCategory(NO, NSStringFromClass([self class]), @"Unexpected state '%@' for %@", componentStateName(_state), [_component class]);
  }
}

- (void)_relinquishView
{
  [self componentWillRelinquishView];
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
        CKAssert(_updatingComponent, @"Only expect to acquire a new view before relinquishing old if updating");
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
