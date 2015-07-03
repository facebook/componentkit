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
    _state = childPair.frame.handle.state;
  }
}

id CKComponentScope::state() const
{
  return _state;
}
