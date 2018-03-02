/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKBuildComponent.h"

#import "CKAnalyticsListener.h"
#import "CKComponentBoundsAnimation.h"
#import "CKComponentEvents.h"
#import "CKComponentInternal.h"
#import "CKComponentScopeRoot.h"
#import "CKComponentSubclass.h"
#import "CKThreadLocalComponentScope.h"
#import "CKOwnerTreeNode.h"

CKBuildComponentResult CKBuildComponent(CKComponentScopeRoot *previousRoot,
                                        const CKComponentStateUpdateMap &stateUpdates,
                                        CKComponent *(^componentFactory)(void),
                                        BOOL buildComponentTree)
{
  CKCAssertNotNil(componentFactory, @"Must have component factory to build a component");
  const auto analyticsListener = [previousRoot analyticsListener];
  [analyticsListener willBuildComponentTreeWithScopeRoot:previousRoot];
  CKThreadLocalComponentScope threadScope(previousRoot, stateUpdates);
  // Order of operations matters, so first store into locals and then return a struct.
  CKComponent *const component = componentFactory();

  if (buildComponentTree && threadScope.newScopeRoot.hasRenderComponentInTree) {
    // Build the component tree from the render function.
    [component buildComponentTree:threadScope.newScopeRoot.rootNode
                    previousOwner:previousRoot.rootNode
                        scopeRoot:threadScope.newScopeRoot
                     stateUpdates:stateUpdates];
  }

  CKComponentScopeRoot *newScopeRoot = threadScope.newScopeRoot;
  [analyticsListener didBuildComponentTreeWithScopeRoot:newScopeRoot component:component];
  return {
    .component = component,
    .scopeRoot = newScopeRoot,
    .boundsAnimation = CKComponentBoundsAnimationFromPreviousScopeRoot(newScopeRoot, previousRoot)
  };
}

