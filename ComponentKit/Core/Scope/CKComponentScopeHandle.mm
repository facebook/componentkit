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

#import <ComponentKit/CKInternalHelpers.h>
#import <ComponentKit/CKScopeTreeNode.h>
#import <ComponentKit/CKMutex.h>

#import "CKComponentScopeRoot.h"
#import "CKComponentSubclass.h"
#import "CKComponentInternal.h"
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

- (instancetype)initWithListener:(id<CKComponentStateListener>)listener
                  rootIdentifier:(CKComponentScopeRootIdentifier)rootIdentifier
               componentTypeName:(const char *)componentTypeName
                    initialState:(id)initialState
{
  static int32_t nextGlobalIdentifier = 0;
  return [self initWithListener:listener
               globalIdentifier:OSAtomicIncrement32(&nextGlobalIdentifier)
                 rootIdentifier:rootIdentifier
              componentTypeName:componentTypeName
                          state:initialState
                     controller:nil  // Controllers are built on resolution of the handle.
                scopedResponder:nil];  // Scoped responders are created lazily. Once they exist, we use that reference for future handles.
}

- (instancetype)initWithListener:(id<CKComponentStateListener>)listener
                globalIdentifier:(CKComponentScopeHandleIdentifier)globalIdentifier
                  rootIdentifier:(CKComponentScopeRootIdentifier)rootIdentifier
               componentTypeName:(const char *)componentTypeName
                           state:(id)state
                      controller:(id<CKComponentControllerProtocol>)controller
                 scopedResponder:(CKScopedResponder *)scopedResponder
{
  if (self = [super init]) {
    _listener = listener;
    _globalIdentifier = globalIdentifier;
    _rootIdentifier = rootIdentifier;
    _componentTypeName = componentTypeName;
    _state = state;
    _controller = controller;

    _scopedResponder = scopedResponder;
    [scopedResponder addHandleToChain:self];
  }
  return self;
}

- (instancetype)newHandleWithStateUpdates:(const CKComponentStateUpdateMap &)stateUpdates
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

  return [[CKComponentScopeHandle alloc] initWithListener:_listener
                                         globalIdentifier:_globalIdentifier
                                           rootIdentifier:_rootIdentifier
                                        componentTypeName:_componentTypeName
                                                    state:updatedState
                                               controller:_controller
                                          scopedResponder:_scopedResponder];
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
  if (![NSThread isMainThread] && [(id<CKComponentStateListener>)[_listener class] requiresMainThreadAffinedStateUpdates]) {
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
  if (!_acquired && component.typeName == _componentTypeName) {
    _acquired = YES;
    _acquiredComponent = component;
    return YES;
  } else {
    return NO;
  }
}

- (void)relinquishComponent
{
  _acquiredComponent = nil;
}

- (void)forceAcquireFromComponent:(id<CKComponentProtocol>)component
{
  CKAssert(component.typeName == _componentTypeName, @"%s has to be a member of %s class", component.typeName, _componentTypeName);
  CKAssert(!_acquired, @"scope handle cannot be acquired twice");
  _acquired = YES;
  _acquiredComponent = component;
}

- (void)setTreeNode:(id<CKTreeNodeProtocol>)treeNode
{
  CKAssertWithCategory(_treeNodeIdentifier == 0,
                       NSStringFromClass([_acquiredComponent class]),
                       @"_treeNodeIdentifier cannot be set twice");
  _treeNodeIdentifier = treeNode.nodeIdentifier;
  _treeNode = treeNode;
}

- (void)resolveAndRegisterInScopeRoot:(CKComponentScopeRoot *)scopeRoot
{
  [self resolveInScopeRoot:scopeRoot];
  [self registerInScopeRoot:scopeRoot];
}

- (void)resolveInScopeRoot:(CKComponentScopeRoot *)scopeRoot
{
  CKAssertFalse(_resolved);

  // Strong ref: _acquiredComponent may be nil when rendering-to-nil as the
  // handle won't be acquired.
  const auto acquiredComponent = _acquiredComponent;
  if (acquiredComponent != nil && _controller == nil) {
    // Build the controller on the first non nil component.
    _controller = [acquiredComponent buildController];
  }

  _resolved = YES;
}

- (void)registerInScopeRoot:(CKComponentScopeRoot *)scopeRoot
{
  // Register after scope handle resolution so the controller can be accessed
  // in the predicates.
  [scopeRoot registerComponent:_acquiredComponent];
  [scopeRoot registerComponentController:_controller];
}

- (CKScopedResponder *)scopedResponder
{
  if (!_scopedResponder) {
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
  auto result = CK::find(_handles, handle);

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
