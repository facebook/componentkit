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
#import <ComponentKit/CKAnalyticsListener.h>
#import <ComponentKit/CKRootTreeNode.h>
#import <ComponentKit/CKRenderHelpers.h>

#import "CKComponentScopeRoot.h"
#import "CKScopeTreeNode.h"

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
                                                         const CKComponentStateUpdateMap &updates,
                                                         CKBuildTrigger trigger,
                                                         BOOL enableComponentReuseOptimizations,
                                                         BOOL shouldCollectTreeNodeCreationInformation,
                                                         BOOL alwaysBuildRenderTree,
                                                         BOOL shouldSkipControllerRegistrationOnRenderToNil,
                                                         CKComponentCoalescingMode coalescingMode,
                                                         BOOL enforceCKComponentSubclasses)
: newScopeRoot([previousScopeRoot newRoot]),
  previousScopeRoot(previousScopeRoot),
  stateUpdates(updates),
  stack(),
  systraceListener(previousScopeRoot.analyticsListener.systraceListener),
  buildTrigger(trigger),
  componentAllocations(0),
  treeNodeDirtyIds(CKRender::treeNodeDirtyIdsFor(previousScopeRoot, stateUpdates, trigger)),
  enableComponentReuseOptimizations(enableComponentReuseOptimizations),
  shouldCollectTreeNodeCreationInformation(shouldCollectTreeNodeCreationInformation),
  coalescingMode(coalescingMode),
  enforceCKComponentSubclasses(enforceCKComponentSubclasses),
  shouldSkipControllerRegistrationOnRenderToNil(shouldSkipControllerRegistrationOnRenderToNil),
  previousScope(CKThreadLocalComponentScope::currentScope())
{
  stack.push({newScopeRoot.rootNode.node(), previousScopeRoot.rootNode.node()});
  keys.push({});
  ancestorHasStateUpdate.push(NO);
  pthread_setspecific(_threadKey(), this);
}

CKThreadLocalComponentScope::~CKThreadLocalComponentScope()
{
  stack.pop();
  CKCAssert(stack.empty(), @"Didn't expect stack to contain anything in destructor");
  CKCAssert(keys.size() == 1 && keys.top().empty(), @"Expected keys to be at initial state in destructor");
  CKCAssert(ancestorHasStateUpdate.size() == 1 && ancestorHasStateUpdate.top() == NO, @"Expected ancestorHasStateUpdate to be at initial state in destructor");
  pthread_setspecific(_threadKey(), previousScope);
}

void CKThreadLocalComponentScope::push(CKComponentScopePair scopePair, BOOL keysSupportEnabled) {
  stack.push(std::move(scopePair));
  if (keysSupportEnabled) {
    keys.push({});
  }
}

void CKThreadLocalComponentScope::push(CKComponentScopePair scopePair, BOOL keysSupportEnabled, BOOL ancestorHasStateUpdateValue) {
  push(scopePair, keysSupportEnabled);
  ancestorHasStateUpdate.push(ancestorHasStateUpdateValue);
}

void CKThreadLocalComponentScope::pop(BOOL keysSupportEnabled, BOOL ancestorStateUpdateSupportEnabled) {
  stack.pop();
  if (keysSupportEnabled) {
    CKCAssert(
        keys.top().empty(),
        @"Expected keys to be cleared on pop");
    keys.pop();
  }

  if (ancestorStateUpdateSupportEnabled) {
    ancestorHasStateUpdate.pop();
  }
}

void CKThreadLocalComponentScope::markCurrentScopeWithRenderComponentInTree()
{
  CKThreadLocalComponentScope *currentScope = CKThreadLocalComponentScope::currentScope();
  if (currentScope != nullptr) {
    currentScope->newScopeRoot.hasRenderComponentInTree = YES;
    // `markCurrentScopeWithRenderComponentInTree` is being called for every render component from the base constructor of `CKComponent`.
    // We can rely on this infomration to increase the `componentAllocations` counter.
    currentScope->componentAllocations++;
  }
}
