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

#import "CKComponentScopeFrame.h"
#import "CKComponentScopeHandle.h"
#import "CKThreadLocalComponentScope.h"

CKComponentScope::~CKComponentScope()
{
  if (_threadLocalScope != nullptr) {
    [_scopeHandle resolve];
    _threadLocalScope->stack.pop();
    CKCAssert(_threadLocalScope->keys.top().empty(), @"Expected keys to be cleared by destructor time");
    _threadLocalScope->keys.pop();
  }
}

CKComponentScope::CKComponentScope(Class __unsafe_unretained componentClass, id identifier, id (^initialStateCreator)(void)) noexcept
{
  _threadLocalScope = CKThreadLocalComponentScope::currentScope();
  if (_threadLocalScope != nullptr) {
    const auto childPair = [CKComponentScopeFrame childPairForPair:_threadLocalScope->stack.top()
                                                           newRoot:_threadLocalScope->newScopeRoot
                                                    componentClass:componentClass
                                                        identifier:identifier
                                                              keys:_threadLocalScope->keys.top()
                                               initialStateCreator:initialStateCreator
                                                      stateUpdates:_threadLocalScope->stateUpdates];
    _threadLocalScope->stack.push({.frame = childPair.frame, .equivalentPreviousFrame = childPair.equivalentPreviousFrame});
    _scopeHandle = childPair.frame.handle;
    _threadLocalScope->keys.push({});
  }
}

id CKComponentScope::state(void) const noexcept
{
  return _scopeHandle.state;
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
