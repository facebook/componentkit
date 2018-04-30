/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKTreeNode.h"

#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKComponentInternal.h>
#import <ComponentKit/CKInternalHelpers.h>
#import <ComponentKit/CKRenderComponentProtocol.h>

#include <tuple>

#import "CKMutex.h"
#import "CKThreadLocalComponentScope.h"

@interface CKTreeNode ()
@property (nonatomic, strong, readwrite) CKComponent *component;
@property (nonatomic, strong, readwrite) CKComponentScopeHandle *handle;
@property (nonatomic, assign, readwrite) CKTreeNodeIdentifier nodeIdentifier;
@end

@implementation CKTreeNode
{
  CKComponentKey _componentKey;
}

- (instancetype)initWithComponent:(CKComponent *)component
                            owner:(id<CKTreeNodeWithChildrenProtocol>)owner
                    previousOwner:(id<CKTreeNodeWithChildrenProtocol>)previousOwner
                        scopeRoot:(CKComponentScopeRoot *)scopeRoot
                     stateUpdates:(const CKComponentStateUpdateMap &)stateUpdates
{

  static int32_t nextGlobalIdentifier = 0;

  if (self = [super init]) {

    _component = component;

    Class componentClass = [component class];
    _componentKey = [owner createComponentKeyForChildWithClass:componentClass];
    CKTreeNode *previousNode = [previousOwner childForComponentKey:_componentKey];

    if (previousNode) {
      _nodeIdentifier = previousNode.nodeIdentifier;
    } else {
      _nodeIdentifier = OSAtomicIncrement32(&nextGlobalIdentifier);
    }

    if (component.scopeHandle) {
      _handle = component.scopeHandle;
    } else {
      // In case we already had a component tree before.
      if (previousNode) {
        _handle = [previousNode.handle newHandleWithStateUpdates:stateUpdates
                                              componentScopeRoot:scopeRoot
                                                          parent:owner.handle];
      } else {
        // We need a scope handle only if the component has a controller or an initial state.
        id initialState = [self initialStateWithComponent:component];
        if (initialState != [CKTreeNodeEmptyState emptyState] || [componentClass controllerClass]) {
          _handle = [[CKComponentScopeHandle alloc] initWithListener:scopeRoot.listener
                                                      rootIdentifier:scopeRoot.globalIdentifier
                                                      componentClass:componentClass
                                                        initialState:initialState
                                                              parent:owner.handle];
        }
      }

      if (_handle) {
        [component acquireScopeHandle:_handle];
        [_handle resolve];
      }
    }

    // Set the link between the parent and the child.
    [owner setChild:self forComponentKey:_componentKey];
    
  }
  return self;
}

- (id)state
{
  return _handle.state;
}

- (const CKComponentKey &)componentKey
{
  return _componentKey;
}

- (id)initialStateWithComponent:(CKComponent *)component
{
  // For CKComponent, we bridge a `nil` initial state to `CKTreeNodeEmptyState`.
  // The base initializer will create a scope handle for the component only if the initial state is different than `CKTreeNodeEmptyState`.
  return [[component class] initialState] ?: [CKTreeNodeEmptyState emptyState];
}

@end

/**
 Implement a singletone empty state here.
 */
@implementation CKTreeNodeEmptyState
+ (id)emptyState
{
  static dispatch_once_t onceToken;
  static CKTreeNodeEmptyState *emptyState;
  dispatch_once(&onceToken, ^{
    emptyState = [CKTreeNodeEmptyState new];
  });
  return emptyState;
}
@end
