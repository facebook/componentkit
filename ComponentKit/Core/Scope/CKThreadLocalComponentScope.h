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
#import <vector>

#import <Foundation/Foundation.h>

#import <ComponentKit/CKAssert.h>
#import <ComponentKit/CKBuildComponent.h>
#import <ComponentKit/CKComponentScopeFrame.h>
#import <ComponentKit/CKComponentScopeHandle.h>

@protocol CKSystraceListener;

class CKThreadLocalComponentScope {
public:
  CKThreadLocalComponentScope(CKComponentScopeRoot *previousScopeRoot,
                              const CKComponentStateUpdateMap &updates,
                              BuildTrigger trigger = BuildTrigger::NewTree);
  ~CKThreadLocalComponentScope();

  /** Returns nullptr if there isn't a current scope */
  static CKThreadLocalComponentScope *currentScope() noexcept;

  /**
   Marks the current component scope as containing a component tree.
   This is used to ensure that during build component time we are initiating a component tree generation by calling `buildComponentTree:` on the root component.
   */
  static void markCurrentScopeWithRenderComponentInTree();

  CKComponentScopeRoot *const newScopeRoot;
  const CKComponentStateUpdateMap stateUpdates;
  std::stack<CKComponentScopeFramePair> stack;
  std::stack<std::vector<id<NSObject>>> keys;

  /** The current systrace listener. Can be nil if systrace is not enabled. */
  id<CKSystraceListener> systraceListener;
  
  /** Build trigger of the corsposnding component creation */
  BuildTrigger buildTrigger;

  /** Component Allocations */
  NSUInteger componentAllocations;

private:
  CKThreadLocalComponentScope *const previousScope;
};
