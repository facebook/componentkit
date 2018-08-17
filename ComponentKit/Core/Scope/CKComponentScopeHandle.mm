/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentScopeHandle.h"

#include <mutex>

#import "CKComponentScopeRoot.h"
#import "CKComponentSubclass.h"
#import "CKComponentInternal.h"
#import "CKInternalHelpers.h"
#import "CKMutex.h"
#import "CKComponentProtocol.h"
#import "CKComponentControllerProtocol.h"
#import "CKThreadLocalComponentScope.h"
#import "CKRenderComponentProtocol.h"

@interface CKScopedResponder ()
- (void)addHandleToChain:(CKComponentScopeHandle *)component;
@end

@implementation CKComponentScopeHandle
{
  id<CKComponentStateListener> __weak _listener;
  id<CKComponentControllerProtocol> _controller;
  CKComponentScopeRootIdentifier _rootIdentifier;
  BOOL _acquired;
  BOOL _resolved;
  CKScopedResponder *_scopedResponder;
}

+ (CKComponentScopeHandle *)handleForComponent:(id<CKComponentProtocol>)component
{
  CKThreadLocalComponentScope *currentScope = CKThreadLocalComponentScope::currentScope();
  if (currentScope == nullptr) {
    return nil;
  }

  CKComponentScopeHandle *handle = currentScope->stack.top().frame.handle;
  if ([handle acquireFromComponent:component]) {
    [currentScope->newScopeRoot registerComponent:component];
    return handle;
  }
  CKCAssertNil([component.class controllerClass] &&
               ![component conformsToProtocol:@protocol(CKRenderComponentProtocol)]
                , @"%@ has a controller but no scope! "
               "Make sure you construct your scope(self) before constructing the component or CKComponentTestRootScope "
               "at the start of the test.", [component class]);

  return nil;
}

- (instancetype)initWithListener:(id<CKComponentStateListener>)listener
                  rootIdentifier:(CKComponentScopeRootIdentifier)rootIdentifier
                  componentClass:(Class)componentClass
                    initialState:(id)initialState
                          parent:(CKComponentScopeHandle *)parent
{
  static int32_t nextGlobalIdentifier = 0;
  return [self initWithListener:listener
               globalIdentifier:OSAtomicIncrement32(&nextGlobalIdentifier)
                 rootIdentifier:rootIdentifier
                 componentClass:componentClass
                          state:initialState
                     controller:nil  // Controllers are built on resolution of the handle.
                scopedResponder:nil  // Scoped responders are created lazily. Once they exist, we use that reference for future handles.
                         parent:parent];
}

- (instancetype)initWithListener:(id<CKComponentStateListener>)listener
                globalIdentifier:(CKComponentScopeHandleIdentifier)globalIdentifier
                  rootIdentifier:(CKComponentScopeRootIdentifier)rootIdentifier
                  componentClass:(Class<CKComponentProtocol>)componentClass
                           state:(id)state
                      controller:(id<CKComponentControllerProtocol>)controller
                 scopedResponder:(CKScopedResponder *)scopedResponder
                          parent:(CKComponentScopeHandle *)parent
{
  if (self = [super init]) {
    _listener = listener;
    _globalIdentifier = globalIdentifier;
    _rootIdentifier = rootIdentifier;
    _componentClass = componentClass;
    _state = state;
    _controller = controller;
    _parent = parent;

    _scopedResponder = scopedResponder;
    [scopedResponder addHandleToChain:self];
  }
  return self;
}

- (instancetype)newHandleWithStateUpdates:(const CKComponentStateUpdateMap &)stateUpdates
                       componentScopeRoot:(CKComponentScopeRoot *)componentScopeRoot
                                   parent:(CKComponentScopeHandle *)parent
{
  id updatedState = _state;
  const auto pendingUpdatesIt = stateUpdates.find(self);
  if (pendingUpdatesIt != stateUpdates.end()) {
    for (auto pendingUpdate: pendingUpdatesIt->second) {
      if (pendingUpdate != nil) {
        updatedState = pendingUpdate(updatedState);
      }
    }
  }

  [componentScopeRoot registerComponentController:_controller];
  return [[CKComponentScopeHandle alloc] initWithListener:_listener
                                         globalIdentifier:_globalIdentifier
                                           rootIdentifier:_rootIdentifier
                                           componentClass:_componentClass
                                                    state:updatedState
                                               controller:_controller
                                          scopedResponder:_scopedResponder
                                                   parent:parent];
}

- (instancetype)newHandleToBeReacquiredDueToScopeCollision
{
  return [[CKComponentScopeHandle alloc] initWithListener:_listener
                                         globalIdentifier:_globalIdentifier
                                           rootIdentifier:_rootIdentifier
                                           componentClass:_componentClass
                                                    state:_state
                                               controller:_controller
                                          scopedResponder:_scopedResponder
                                                   parent:_parent];
}

- (id<CKComponentControllerProtocol>)controller
{
  CKAssert(_resolved, @"Requesting controller from scope handle before resolution. The controller will be nil.");
  return _controller;
}

- (void)dealloc
{
  CKAssert(_resolved, @"Must be resolved before deallocation.");
}

#pragma mark - State

- (void)updateState:(id (^)(id))updateBlock
           metadata:(const CKStateUpdateMetadata &)metadata
               mode:(CKUpdateMode)mode
{
  CKAssertNotNil(updateBlock, @"The update block cannot be nil");
  if (![NSThread isMainThread]) {
    // Passing a const& into a block is scary, make a local copy to be safe.
    const auto metadataCopy = metadata;
    dispatch_async(dispatch_get_main_queue(), ^{
      [self updateState:updateBlock metadata:metadataCopy mode:mode];
    });
    return;
  }
  [_listener componentScopeHandle:self
                   rootIdentifier:_rootIdentifier
            didReceiveStateUpdate:updateBlock
                         metadata:metadata
                             mode:mode];
}

- (void)replaceState:(id)state
{
  CKAssertFalse(_resolved);
  _state = state;
}

#pragma mark - Component Scope Handle Acquisition

- (BOOL)acquireFromComponent:(id<CKComponentProtocol>)component
{
  if (!_acquired && [component isMemberOfClass:_componentClass]) {
    _acquired = YES;
    _acquiredComponent = component;
    return YES;
  } else {
    return NO;
  }
}

- (void)forceAcquireFromComponent:(id<CKComponentProtocol>)component
{
  CKAssert([component isMemberOfClass:_componentClass], @"%@ has to be a member of %@ class", component, _componentClass);
  CKAssert(!_acquired, @"scope handle cannot be acquired twice");
  _acquired = YES;
  _acquiredComponent = component;
}

- (void)setTreeNode:(id<CKTreeNodeProtocol>)treeNode
{
  CKAssert(_treeNode == nil, @"treeNode cannot be set twice");
  _treeNode = treeNode;
}

- (void)resolve
{
  CKAssertFalse(_resolved);
  // _acquiredComponent may be nil if a component scope was declared before an early return. In that case, the scope
  // handle will not be acquired, and we should avoid creating a component controller for the nil component.
  if (!_controller && _acquiredComponent) {
    CKThreadLocalComponentScope *currentScope = CKThreadLocalComponentScope::currentScope();
    CKAssert(currentScope != nullptr, @"Current scope should never be null here. Thread-local stack is corrupted.");

    const Class<CKComponentControllerProtocol> controllerClass = [_acquiredComponent.class controllerClass];
    if (controllerClass) {
      // The compiler is not happy when I don't explicitly cast as (Class)
      // See: http://stackoverflow.com/questions/21699755/create-an-instance-from-a-class-that-conforms-to-a-protocol
      _controller = [[(Class)controllerClass alloc] initWithComponent:_acquiredComponent];
      [currentScope->newScopeRoot registerComponentController:_controller];
    }
  }
  _resolved = YES;
}

- (CKScopedResponder *)scopedResponder
{
  if (!_scopedResponder) {
    CKAssertFalse(_resolved);
    _scopedResponder = [CKScopedResponder new];
    [_scopedResponder addHandleToChain:self];
  }

  return _scopedResponder;
}

@end

@implementation CKScopedResponder
{
  std::vector<__weak CKComponentScopeHandle *> _handles;
  std::mutex _mutex;
}

- (instancetype)init
{
  if (self = [super init]) {
    static CKScopedResponderUniqueIdentifier nextIdentifier = 0;
    _uniqueIdentifier = OSAtomicIncrement32(&nextIdentifier);
  }

  return self;
}

- (void)addHandleToChain:(CKComponentScopeHandle *)handle
{
  if (!handle) {
    return;
  }

  std::lock_guard<std::mutex> l(_mutex);
  _handles.push_back(handle);
}

- (CKScopedResponderKey)keyForHandle:(CKComponentScopeHandle *)handle
{
  static const CKScopedResponderKey notFoundKey = INT_MAX;

  if (handle == nil) {
    return notFoundKey;
  }

  std::lock_guard<std::mutex> l(_mutex);
  auto result = std::find(_handles.begin(), _handles.end(), handle);

  if (result == _handles.end()) {
    CKFailAssert(@"This scope handle is not associated with this Responder.");
    return notFoundKey;
  }

  // Returning the index of an element in a vector: https://stackoverflow.com/a/15099743
  return (int)std::distance(_handles.begin(), result);
}

- (id)responderForKey:(CKScopedResponderKey)key
{
  std::lock_guard<std::mutex> l(_mutex);

  const size_t numberOfHandles = _handles.size();
  if (key < 0 || key >= numberOfHandles) {
    CKFailAssert(@"Invalid key \"%d\" for responder with %zu handles", key, numberOfHandles);
    return nil;
  }

  for (int i = key; i < numberOfHandles; i++) {
      const auto handle = _handles[i];
      const id<CKComponentProtocol> responder = handle.acquiredComponent;
      if (responder != nil) {
        return responder;
      }
  }

  return nil;
}

@end
