/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentScope.h"

#import "CKAnalyticsListener.h"
#import "CKComponentScopeHandle.h"
#import "CKComponentScopeRoot.h"
#import "CKThreadLocalComponentScope.h"
#import "CKScopeTreeNode.h"
#import "CKTreeNodeProtocol.h"

static auto toInitialStateCreator(id (^initialStateCreator)(void), Class componentClass) {
  return initialStateCreator ?: ^{
    return [componentClass initialState];
  };
}

CKComponentScope::~CKComponentScope()
{
  if (_threadLocalScope != nullptr) {
    [_scopeHandle resolve];

    if (_threadLocalScope->systraceListener) {
      auto const componentClass = _threadLocalScope->stack.top().node.scopeHandle.componentClass;
      [_threadLocalScope->systraceListener didBuildComponent:componentClass];
    }

    _threadLocalScope->stack.pop();
    CKCAssert(_threadLocalScope->keys.top().empty(), @"Expected keys to be cleared by destructor time");
    _threadLocalScope->keys.pop();
  }
}

CKComponentScope::CKComponentScope(Class __unsafe_unretained componentClass, id identifier, id (^initialStateCreator)(void)) noexcept
{
  _threadLocalScope = CKThreadLocalComponentScope::currentScope();
  if (_threadLocalScope != nullptr) {

    [_threadLocalScope->systraceListener willBuildComponent:componentClass];

    const auto childPair = [CKScopeTreeNode childPairForPair:_threadLocalScope->stack.top()
                                                     newRoot:_threadLocalScope->newScopeRoot
                                              componentClass:componentClass
                                                  identifier:identifier
                                                        keys:_threadLocalScope->keys.top()
                                         initialStateCreator:toInitialStateCreator(initialStateCreator, componentClass)
                                                stateUpdates:_threadLocalScope->stateUpdates
                                         mergeTreeNodesLinks:_threadLocalScope->mergeTreeNodesLinks
                                         requiresScopeHandle:YES];
    _threadLocalScope->stack.push({.node = childPair.node, .previousNode = childPair.previousNode});
    _scopeHandle = childPair.node.scopeHandle;
    _threadLocalScope->keys.push({});
  }
  CKCAssertWithCategory(_threadLocalScope != nullptr,
                        NSStringFromClass(componentClass),
                        @"Component with scope must be created inside component provider function.");
}

id CKComponentScope::state(void) const noexcept
{
  return _scopeHandle.state;
}

CKComponentScopeHandleIdentifier CKComponentScope::identifier(void) const noexcept
{
  return _scopeHandle.globalIdentifier;
}

void CKComponentScope::replaceState(const CKComponentScope &scope, id state)
{
  [scope._scopeHandle replaceState:state];
}

CKComponentStateUpdater CKComponentScope::stateUpdater(void) const noexcept
{
  // We must capture _scopeHandle in a local, since this may be destroyed by the time the block executes.
  CKComponentScopeHandle *const scopeHandle = _scopeHandle;
  return ^(id (^stateUpdate)(id), NSDictionary<NSString *, id> *userInfo, CKUpdateMode mode) {
    [scopeHandle updateState:stateUpdate
                    metadata:{.userInfo = userInfo}
                        mode:mode];
  };
}

CKComponentScopeHandle *CKComponentScope::scopeHandle(void) const noexcept
{
  return _scopeHandle;
}
