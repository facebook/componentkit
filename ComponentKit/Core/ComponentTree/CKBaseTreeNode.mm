/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKBaseTreeNode.h"

#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKComponentInternal.h>
#import <ComponentKit/CKInternalHelpers.h>

#include <tuple>

#import "CKMutex.h"
#import "CKThreadLocalComponentScope.h"
#import "CKTreeNode.h"

@class CKTreeNode;

@implementation CKBaseTreeNode
{
  CKComponentKey _componentKey;
}

- (instancetype)initWithComponent:(CKComponent *)component
                            owner:(CKTreeNode *)owner
                    previousOwner:(CKTreeNode *)previousOwner
                        scopeRoot:(CKComponentScopeRoot *)scopeRoot
                     stateUpdates:(const CKComponentStateUpdateMap &)stateUpdates
{

  static int32_t nextGlobalIdentifier = 0;

  if (self = [super init]) {

    _component = component;

    Class componentClass = [component class];
    _componentKey = [owner createComponentKeyForChildWithClass:componentClass];
    CKBaseTreeNode *previousNode = [previousOwner childForComponentKey:_componentKey];

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
        // We need a scope handle only if there is a controller or a state.
        id initialState = [componentClass initialState];
        if (initialState || [componentClass controllerClass]) {
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

@end
