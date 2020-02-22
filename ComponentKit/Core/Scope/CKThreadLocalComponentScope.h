/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKDefines.h>

#if CK_NOT_SWIFT

#import <stack>
#import <vector>

#import <Foundation/Foundation.h>

#import <ComponentKit/CKAssert.h>
#import <ComponentKit/CKBuildComponent.h>
#import <ComponentKit/CKComponentScopeFrame.h>
#import <ComponentKit/CKComponentScopeHandle.h>
#import <ComponentKit/CKGlobalConfig.h>
#import <ComponentKit/CKTreeNodeProtocol.h>

@protocol CKSystraceListener;

class CKThreadLocalComponentScope {
public:
  CKThreadLocalComponentScope(CKComponentScopeRoot *previousScopeRoot,
                              const CKComponentStateUpdateMap &updates,
                              CKBuildTrigger trigger = CKBuildTrigger::NewTree,
                              BOOL merge = NO);
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
  CKBuildTrigger buildTrigger;

  /** Component Allocations */
  NSUInteger componentAllocations;

  /** Avoid duplicate links in the tree nodes for owner/parent based nodes */
  BOOL mergeTreeNodesLinks;

private:
  CKThreadLocalComponentScope *const previousScope;
};

#endif
