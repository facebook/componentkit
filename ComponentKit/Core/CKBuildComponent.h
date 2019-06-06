/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <Foundation/Foundation.h>

#import <ComponentKit/CKComponentScopeTypes.h>
#import <ComponentKit/CKComponentBoundsAnimation.h>

@class CKComponentScopeRoot;
@class CKComponent;

struct CKBuildComponentTreeParams;

// Collection of events that trigger a new component generation.
enum class BuildTrigger {
  NewTree,
  StateUpdate,
  PropsUpdate,
};

namespace CKBuildComponentHelpers {
  /**
   Depending on the scope root and the list of state updates the proper build trigger is derived.

   @return The related build trigger given the in input parameters
   */
  auto getBuildTrigger(CKComponentScopeRoot *scopeRoot, const CKComponentStateUpdateMap &stateUpdates) -> BuildTrigger;
}

/**
 The results of a build operation.

 A bounds animations are returned in this method if a component in the hierarchy requested an animation from its prior
 state. These animations should be applied with CKComponentBoundsAnimationApply.
 */
struct CKBuildComponentResult {
  CKComponent *component;
  CKComponentScopeRoot *scopeRoot;
  CKComponentBoundsAnimation boundsAnimation;
  BuildTrigger buildTrigger;
};

/**
 Used to construct a component hierarchy. This is necessary to configure the thread-local state so that components
 can be properly connected to a scope root.

 @param previousRoot The previous scope root that was associated with the cell. May be nil if no prior root is available
 @param stateUpdates A map of state updates that have accumulated since the last component generation was constructed.
 @param componentFactory A block that constructs your component. Must not be nil.
 @param ignoreComponentReuseOptimizations When enabled, all the comopnents will be regenerated (no component reuse optimiztions).
 */
CKBuildComponentResult CKBuildComponent(CKComponentScopeRoot *previousRoot,
                                        const CKComponentStateUpdateMap &stateUpdates,
                                        CKComponent *(^componentFactory)(void),
                                        BOOL ignoreComponentReuseOptimizations = NO);

#if DEBUG
void CKDidBuildComponentTree(const CKBuildComponentTreeParams &params, id<CKComponentProtocol> component);
#endif
