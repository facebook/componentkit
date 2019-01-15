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
#import <ComponentKit/CKComponentSubclass.h>
#import <ComponentKit/CKInternalHelpers.h>
#import <ComponentKit/CKRenderComponentProtocol.h>
#import <ComponentKit/CKRootTreeNode.h>

#include <tuple>

#import "CKMutex.h"
#import "CKThreadLocalComponentScope.h"

@interface CKTreeNode ()
@property (nonatomic, strong, readwrite) id<CKTreeNodeComponentProtocol> component;
@property (nonatomic, strong, readwrite) CKComponentScopeHandle *handle;
@property (nonatomic, assign, readwrite) CKTreeNodeIdentifier nodeIdentifier;
@end

@implementation CKTreeNode
{
  CKTreeNodeComponentKey _componentKey;
}

- (instancetype)initWithComponent:(id<CKTreeNodeComponentProtocol>)component
                           parent:(id<CKTreeNodeWithChildrenProtocol>)parent
                   previousParent:(id<CKTreeNodeWithChildrenProtocol>)previousParent
                        scopeRoot:(CKComponentScopeRoot *)scopeRoot
                     stateUpdates:(const CKComponentStateUpdateMap &)stateUpdates
{
  static int32_t nextGlobalIdentifier = 0;

  if (self = [super init]) {
    _component = component;

    Class componentClass = [component class];
    _componentKey = [parent createComponentKeyForChildWithClass:componentClass];
    CKTreeNode *previousNode = [previousParent childForComponentKey:_componentKey];

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
                                                          parent:parent.handle];
      } else {
        // We need a scope handle only if the component has a controller or an initial state.
        id initialState = [self initialStateWithComponent:component];
        if (initialState != [CKTreeNodeEmptyState emptyState] ||
            [componentClass controllerClass] ||
            [self componentRequiresScopeHandle:componentClass]) {
          _handle = [[CKComponentScopeHandle alloc] initWithListener:scopeRoot.listener
                                                      rootIdentifier:scopeRoot.globalIdentifier
                                                      componentClass:componentClass
                                                        initialState:initialState
                                                              parent:parent.handle];
        }
      }

      if (_handle) {
        [component acquireScopeHandle:_handle];
        [scopeRoot registerComponent:component];
        [_handle resolve];
      }
    }

    // Set the link between the parent and the child.
    [parent setChild:self forComponentKey:_componentKey];
    scopeRoot.rootNode.registerNode(self, parent);

    // Set the link between the tree node and the scope handle.
    [_handle setTreeNodeIdentifier:_nodeIdentifier];
  }
  return self;
}

- (id)state
{
  return _handle.state;
}

- (const CKTreeNodeComponentKey &)componentKey
{
  return _componentKey;
}

- (void)didReuseInScopeRoot:(CKComponentScopeRoot *)scopeRoot fromPreviousScopeRoot:(CKComponentScopeRoot *)previousScopeRoot
{
  auto const parent = previousScopeRoot.rootNode.parentForNodeIdentifier(_nodeIdentifier);
  CKAssert(parent != nil, @"The parent cannot be nil; every node should have a valid parent.");
  scopeRoot.rootNode.registerNode(self, parent);
  if (_handle) {
    // Register the reused comopnent in the new scope root.
    [scopeRoot registerComponent:_component];
    auto const controller = _handle.controller;
    if (controller) {
      // Register the controller in the new scope root.
      [scopeRoot registerComponentController:controller];
    }
  }
}

- (id)initialStateWithComponent:(id<CKTreeNodeComponentProtocol>)component
{
  // For CKComponent, we bridge a `nil` initial state to `CKTreeNodeEmptyState`.
  // The base initializer will create a scope handle for the component only if the initial state is different than `CKTreeNodeEmptyState`.
  return [[component class] initialState] ?: [CKTreeNodeEmptyState emptyState];
}

// For non-render comopnents, we don't need to check this code as the comopnent creates its scope handle.
- (BOOL)componentRequiresScopeHandle:(Class<CKTreeNodeComponentProtocol>)componentClass
{
  return NO;
}

#if DEBUG
/** Returns a multi-line string describing this node and its children nodes */
- (NSString *)debugDescription
{
  return [[self debugDescriptionNodes] componentsJoinedByString:@"\n"];
}

- (NSArray<NSString *> *)debugDescriptionNodes
{
  return @[[NSString stringWithFormat:@"- %@ %d - %@",
            [_component class],
            _nodeIdentifier,
            self]];
}
#endif

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
