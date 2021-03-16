/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKSwiftComponent.h"

#import "CKComponentViewConfiguration_SwiftBridge+Internal.h"
#import "RCComponentSize_SwiftBridge+Internal.h"
#import "CKIterableHelpers.h"

#import <ComponentKit/CKComponentSubclass.h>
#import <ComponentKit/CKComponentInternal.h>
#import <ComponentKit/CKInternalHelpers.h>
#import <ComponentKit/CKFlexboxComponent.h>
#import <ComponentKit/CKThreadLocalComponentScope.h>
#import <ComponentKit/CKIdValueWrapper.h>
#import <ComponentKit/CKAnimationComponentPassthroughView.h>
#import <RenderCore/RCAssert.h>

@interface CKSwiftComponentController : CKComponentController
@end

@implementation CKSwiftComponentModel_SwiftBridge {
  @package
  CAAnimation *_animation;
  CAAnimation *_initialMountAnimation;
  CAAnimation *_finalUnmountAnimation;
  NSArray<CKSwiftComponentDidInitCallback> *_didInitCallbacks;
  NSArray<CKSwiftComponentWillMountCallback> *_willMountCallbacks;
  NSArray<CKSwiftComponentDidUnMountCallback> *_didUnmountCallbacks;
  NSArray<CKSwiftComponentWillDisposeCallback> *_willDisposeCallbacks;
}

- (instancetype)initWithAnimation:(CAAnimation *)animation
            initialMountAnimation:(CAAnimation *)initialMountAnimation
            finalUnmountAnimation:(CAAnimation *)finalUnmountAnimation
                 didInitCallbacks:(NSArray<CKSwiftComponentDidInitCallback> *)didInitCallbacks
               willMountCallbacks:(NSArray<CKSwiftComponentWillMountCallback> *)willMountCallbacks
              didUnmountCallbacks:(NSArray<CKSwiftComponentDidUnMountCallback> *)didUnmountCallbacks
             willDisposeCallbacks:(NSArray<CKSwiftComponentWillDisposeCallback> *)willDisposeCallbacks
{
  if (self = [super init]) {
    _animation = animation;
    _initialMountAnimation = initialMountAnimation;
    _finalUnmountAnimation = finalUnmountAnimation;
    _didInitCallbacks = didInitCallbacks;
    _willMountCallbacks = willMountCallbacks;
    _didUnmountCallbacks = didUnmountCallbacks;
    _willDisposeCallbacks = willDisposeCallbacks;
  }

  return self;
}

- (BOOL)requiresController
{
  return _didInitCallbacks.firstObject != nil ||
  _willMountCallbacks.firstObject != nil ||
  _didUnmountCallbacks.firstObject != nil ||
  _willDisposeCallbacks.firstObject != nil;
}

- (BOOL)hasAnimations
{
  return _animation != nil ||
  _initialMountAnimation != nil ||
  _finalUnmountAnimation != nil;
}

@end

@implementation CKSwiftComponent {
  // The child. When nil, CKSwiftComponent is a leaf component.
  CKComponent *_child;
  @package
  CKSwiftComponentModel_SwiftBridge *_model;
}

static CKComponentViewConfiguration _viewConfigurationWithViewIfAnimated(
    CKComponentViewConfiguration_SwiftBridge *swiftView,
    BOOL hasAnimations) {
  if (swiftView == nil) {
    return hasAnimations
    ? CKComponentViewConfiguration{CKAnimationComponentPassthroughView.class}
    : CKComponentViewConfiguration{};
  } else {
    return swiftView.viewConfig.forceViewClassIfNone(CKAnimationComponentPassthroughView.class);
  }
}

- (instancetype)initFromShellComponent:(CKSwiftComponent *)shellComponent child:(CKComponent *)child
{
  if (self = [super initWithView:shellComponent.viewConfiguration size:shellComponent.size]) {
    _model = shellComponent->_model;
    _child = child;
  }
  return self;
}

- (instancetype)initWithSwiftView:(CKComponentViewConfiguration_SwiftBridge *)swiftView
                        swiftSize:(RCComponentSize_SwiftBridge *_Nullable)swiftSize
                            child:(CKComponent *)child
                            model:(CKSwiftComponentModel_SwiftBridge *)model

{
  const auto size = swiftSize != nil ? swiftSize.componentSize : RCComponentSize{};
  const auto view = _viewConfigurationWithViewIfAnimated(swiftView, model.hasAnimations);
  if (self = [super initWithView:view size:size]) {
    _model = model;
    _child = child;
  }

  return self;
}

- (RCLayout)computeLayoutThatFits:(CKSizeRange)constrainedSize
                 restrictedToSize:(const RCComponentSize &)size
             relativeToParentSize:(CGSize)parentSize
{
  if (_child) {
    // Non leaf component
    RCAssert(size == RCComponentSize(),
             @"CKSwiftComponent only passes size {} to the super class initializer, but received size %@ "
             "(component=%@)", size.description(), _child);

    const auto l = [_child layoutThatFits:constrainedSize parentSize:parentSize];
    const auto lSize = l.size;
    return {self, lSize, {{{0,0}, std::move(l)}}};
  } else {
    // Leaf component
    return [super computeLayoutThatFits:constrainedSize restrictedToSize:size relativeToParentSize:parentSize];
  }
}

- (UIView *)viewForAnimation
{
  // Delegate to the wrapped component's viewForAnimation if we don't have one.
  return [super viewForAnimation] ?: [_child viewForAnimation];
}

- (unsigned int)numberOfChildren
{
  return RCIterable::numberOfChildren(_child);
}

- (id<CKMountable>)childAtIndex:(unsigned int)index
{
  return RCIterable::childAtIndex(self, index, _child);
}

- (std::vector<CKComponentAnimation>)animationsFromPreviousComponent:(CKComponent *)previousComponent
{
  if (_model != nil && _model->_animation != nil) {
    return {
      {self, _model->_animation},
    };
  } else {
    return {};
  }
}

- (std::vector<CKComponentAnimation>)animationsOnInitialMount
{
  if (_model != nil && _model->_initialMountAnimation != nil) {
    return {
      {self, _model->_initialMountAnimation},
    };
  } else {
    return {};
  }
}

- (std::vector<CKComponentFinalUnmountAnimation>)animationsOnFinalUnmount
{
  if (_model != nil && _model->_finalUnmountAnimation != nil) {
    return {
      {self, _model->_finalUnmountAnimation},
    };
  } else {
    return {};
  }
}

- (BOOL)hasAnimations
{
  return _model != nil && _model->_animation != nil;
}

- (BOOL)hasBoundsAnimations
{
  return NO;
}

- (BOOL)hasInitialMountAnimations
{
  return _model != nil && _model->_initialMountAnimation != nil;
}

- (BOOL)hasFinalUnmountAnimations
{
  return _model != nil && _model->_finalUnmountAnimation != nil;
}

- (id<CKComponentControllerProtocol>)buildController
{
  if (_model.requiresController) {
    return [[CKSwiftComponentController alloc] initWithComponent:self];
  } else {
    return nil;
  }
}

+ (Class<CKComponentControllerProtocol>)controllerClass
{
  // Avoid assert in super
  return nil;
}

@end

@implementation CKSwiftComponentController {
  CKSwiftComponentModel_SwiftBridge *_model;
}

- (instancetype)initWithComponent:(CKSwiftComponent *)component
{
  if (component->_model == nil) {
    RCFailAssert(@"Building controller without model");
    return nil;
  }

  if (self = [super initWithComponent:component]) {
    _model = component->_model;
  }
  return self;
}

- (void)didInit
{
  // TODO: Predicate for initialization
  [super didInit];

  for (CKSwiftComponentDidInitCallback const callback : _model->_didInitCallbacks) {
    callback();
  }
}

- (void)willMount
{
  [super willMount];

  for (CKSwiftComponentWillMountCallback const callback : _model->_willMountCallbacks) {
    callback();
  }
}

- (void)didUnmount
{
  [super didUnmount];

  for (CKSwiftComponentDidUnMountCallback const callback : _model->_didUnmountCallbacks) {
    callback();
  }
}

- (void)invalidateController
{
  // TODO: Predicate for invalidation
  [super invalidateController];

  for (CKSwiftComponentWillDisposeCallback const callback : _model->_willDisposeCallbacks) {
    callback();
  }
}

@end

@interface CKSwiftStateWrapper : NSObject {
  @package
  std::vector<id> _values;
}

@end

@implementation CKSwiftStateWrapper

- (instancetype)initWithValues:(std::vector<id>)values
{
  if (self = [super init]) {
    _values = std::move(values);
  }
  return self;
}

- (void)add:(id)value
{
  _values.push_back(value);
}

- (instancetype)newStateWrapperWithUpdatedValue:(id)updatedValue atIndex:(NSInteger)index
{
  CKSwiftStateWrapper *const copy = [[self.class alloc] initWithValues:_values];
  copy->_values[index] = updatedValue;
  return copy;
}

@end

static CKComponentScopePair *CKSwiftGetCurrentPair() {
  const auto threadLocalScope = CKThreadLocalComponentScope::currentScope();
  if (threadLocalScope == nullptr || threadLocalScope->stack.size() <= 1) {
    RCCFailAssert(@"No TLS on get node");
    return nil;
  } else {
    return &threadLocalScope->stack.top();
  }
}

void CKSwiftPopClass() {
  const auto threadLocalScope = CKThreadLocalComponentScope::currentScope();
  if (threadLocalScope == nullptr) {
    RCCFailAssert(@"No TLS on class pop");
    return;
  }

  const auto& pair = *CKSwiftGetCurrentPair();

  [pair.node.scopeHandle resolveInScopeRoot:threadLocalScope->newScopeRoot];
  threadLocalScope->pop(YES, YES);
}

CKTreeNode *CKSwiftCreateNode(Class klass, id identifier) {
  const auto threadLocalScope = CKThreadLocalComponentScope::currentScope();
  if (threadLocalScope == nullptr) {
    RCCFailAssert(@"Create scope handle but no TLS");
    return nil;
  }

  const auto childPair = [CKTreeNode childPairForPair:threadLocalScope->stack.top()
                                                   newRoot:threadLocalScope->newScopeRoot
                                         componentTypeName:class_getName(klass)
                                                identifier:identifier
                                                      keys:threadLocalScope->keys.top()
                                       initialStateCreator:^{ return [CKSwiftStateWrapper new]; }
                                              stateUpdates:threadLocalScope->stateUpdates
                                       requiresScopeHandle:YES];
  threadLocalScope->push(childPair, YES, /* ancestor has state update */YES);
  return childPair.node;
}

BOOL CKSwiftInitializeState(CKComponentScopeHandle *handle,
                            NSInteger index,
                            NS_NOESCAPE id _Nullable (^initialValueProvider)()) {
  const auto pair = CKSwiftGetCurrentPair();

  if (pair == nullptr) {
    RCCFailAssert(@"Initialising state but pair is nil");
    return NO;
  }

  if (pair->previousNode == nil) {
    RCCAssert([handle.state isKindOfClass:CKSwiftStateWrapper.class], @"Unexpected state: %@", handle.state);
    const auto wrapper = (CKSwiftStateWrapper *)handle.state;
    [wrapper add:initialValueProvider()];
    return YES;
  } else {
    return NO;
  }
}

id CKSwiftFetchState(CKTreeNode *node, NSInteger index) {
  RCCAssert(CKThreadLocalComponentScope::currentScope() != nullptr ||
            NSThread.currentThread.isMainThread, @"Fetching state out of the main thread (or body) non permitted");
  const auto stateWrapper = (CKSwiftStateWrapper *)node.scopeHandle.state;
  return stateWrapper->_values[index];
}

void CKSwiftUpdateViewModelState(CKComponentScopeHandle *scopeHandle) {
  RCCAssert(NSThread.currentThread.isMainThread, @"Updating state out of the main thread not permitted");
  RCCAssert(CKThreadLocalComponentScope::currentScope() == nullptr, @"Updating state during build not permitted");

  [scopeHandle updateState:^id _Nullable(id state) {
    return state;
  } metadata:{} mode:CKUpdateModeAsynchronous];
}

void CKSwiftUpdateState(CKComponentScopeHandle *scopeHandle, NSInteger index, id _Nullable newValue) {
  RCCAssert(NSThread.currentThread.isMainThread, @"Updating state out of the main thread not permitted");
  RCCAssert(CKThreadLocalComponentScope::currentScope() == nullptr, @"Updating state during build not permitted");

  [scopeHandle updateState:^id _Nullable(CKSwiftStateWrapper *state) {
    return [state newStateWrapperWithUpdatedValue:newValue atIndex:index];
  } metadata:{} mode:CKUpdateModeAsynchronous];
}

BOOL CKSwiftInitializeAction(Class klass, CKScopedResponder **responder, CKScopedResponderKey *key) {
  const auto pair = CKSwiftGetCurrentPair();

  if (responder == nil || key == nil) {
    RCCFailAssert(@"Initialising action but passing nil responder/key");
    return NO;
  }

  if (pair == nullptr) {
    RCCFailAssert(@"Initialising action but pair is nil");
    return NO;
  }

  const auto handle = pair->node.scopeHandle;
  if (class_getName(klass) != handle.componentTypeName) {
    RCCFailAssert(@"Creating an action outside the view's body function. Expected: %@, Found: %s", klass, handle.componentTypeName);
    return NO;
  }

  *responder = handle.scopedResponder;
  *key = [handle.scopedResponder keyForHandle:handle];
  return YES;
}
