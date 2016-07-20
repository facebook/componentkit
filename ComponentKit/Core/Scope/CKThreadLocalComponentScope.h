/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <stack>

#import <Foundation/Foundation.h>

#import <ComponentKit/CKAssert.h>
#import <ComponentKit/CKComponentScopeFrame.h>

class CKThreadLocalComponentScope {
public:
  CKThreadLocalComponentScope(CKComponentScopeRoot *previousScopeRoot,
                              const CKComponentStateUpdateMap &updates);
  ~CKThreadLocalComponentScope();

  /** Returns nullptr if there isn't a current scope */
  static CKThreadLocalComponentScope *currentScope();

  CKComponentScopeRoot *const newScopeRoot;
  const CKComponentStateUpdateMap stateUpdates;
  std::stack<CKComponentScopeFramePair> stack;
};

/**
 Temporarily overrides the current thread's component scope.
 Use for testing and advanced integration purposes only.
 */
class CKThreadLocalComponentScopeOverride {
public:
  CKThreadLocalComponentScopeOverride(CKThreadLocalComponentScope *scope);
  ~CKThreadLocalComponentScopeOverride();

private:
  CKThreadLocalComponentScope *const previousScope;
};
