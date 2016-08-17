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
  }
}

CKComponentScope::CKComponentScope(Class __unsafe_unretained componentClass, id identifier, id (^initialStateCreator)(void))
{
  _threadLocalScope = CKThreadLocalComponentScope::currentScope();
  if (_threadLocalScope != nullptr) {
    const auto childPair = [CKComponentScopeFrame childPairForPair:_threadLocalScope->stack.top()
                                                           newRoot:_threadLocalScope->newScopeRoot
                                                    componentClass:componentClass
                                                        identifier:identifier
                                               initialStateCreator:initialStateCreator
                                                      stateUpdates:_threadLocalScope->stateUpdates];
    _threadLocalScope->stack.push({.frame = childPair.frame, .equivalentPreviousFrame = childPair.equivalentPreviousFrame});
    _scopeHandle = childPair.frame.handle;
  }
}

id CKComponentScope::state(void) const
{
  return _scopeHandle.state;
}

CKComponentStateUpdater CKComponentScope::stateUpdater(void) const
{
  // We must capture _scopeHandle in a local, since this may be destroyed by the time the block executes.
  CKComponentScopeHandle *const scopeHandle = _scopeHandle;
  return ^(id (^update)(id), CKUpdateMode mode){ [scopeHandle updateState:update mode:mode]; };
}
