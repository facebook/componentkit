/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKThreadLocalComponentScope.h"

#import <pthread.h>
#import <stack>

#import <ComponentKit/CKAssert.h>

#import "CKComponentScopeRoot.h"

static pthread_key_t _threadKey() noexcept
{
  static pthread_key_t thread_key;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    (void)pthread_key_create(&thread_key, nullptr);
  });
  return thread_key;
}

CKThreadLocalComponentScope *CKThreadLocalComponentScope::currentScope() noexcept
{
  return (CKThreadLocalComponentScope *)pthread_getspecific(_threadKey());
}

CKThreadLocalComponentScope::CKThreadLocalComponentScope(CKComponentScopeRoot *previousScopeRoot,
                                                         const CKComponentStateUpdateMap &updates)
: newScopeRoot([previousScopeRoot newRoot]), stateUpdates(updates), stack(), enableLogging(false), previousScope(CKThreadLocalComponentScope::currentScope())
{
  stack.push({[newScopeRoot rootFrame], [previousScopeRoot rootFrame]});
  keys.push({});
  pthread_setspecific(_threadKey(), this);
}

CKThreadLocalComponentScope::~CKThreadLocalComponentScope()
{
  stack.pop();
  CKCAssert(stack.empty(), @"Didn't expect stack to contain anything in destructor");
  CKCAssert(keys.size() == 1 && keys.top().empty(), @"Expected keys to be at initial state in destructor");
  pthread_setspecific(_threadKey(), previousScope);
}

void CKThreadLocalComponentScope::markCurrentScopeWithRenderComponentInTree()
{
  CKThreadLocalComponentScope *currentScope = CKThreadLocalComponentScope::currentScope();
  if (currentScope != nullptr) {
    currentScope->newScopeRoot.hasRenderComponentInTree = YES;
  }
}
