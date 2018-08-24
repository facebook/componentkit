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
#import <ComponentKit/CKComponentLayout.h>
#import <ComponentKit/CKTreeNodeProtocol.h>

@class CKComponentScopeRoot;
@class CKComponent;

enum class BuildTrigger {
  NewTree,
  StateUpdate,
  PropsUpdate,
};

/**
 A configuration struct for the build component method.
 **/
struct CKBuildComponentConfig {
  //  Enable faster state updates optimization for render components.
  BOOL enableFasterStateUpdates = NO;
  //  Enable faster props updates optimization for render components.
  BOOL enableFasterPropsUpdates = NO;
};

/**
 The results of a build operation.

 A bounds animations are returned in this method if a component in the hierarchy requested an animation from its prior
 state. These animations should be applied with CKComponentBoundsAnimationApply.
 */
struct CKBuildComponentResult {
  CKComponent *component;
  CKComponentScopeRoot *scopeRoot;
  CKComponentBoundsAnimation boundsAnimation;
};

/**
 Used to construct a component hierarchy. This is necessary to configure the thread-local state so that components
 can be properly connected to a scope root.

 @param previousRoot The previous scope root that was associated with the cell. May be nil if no prior root is available
 @param stateUpdates A map of state updates that have accumulated since the last component generation was constructed.
 @param componentFactory A block that constructs your component. Must not be nil.
 @param config Provides extra build configuration.
 */
CKBuildComponentResult CKBuildComponent(CKComponentScopeRoot *previousRoot,
                                        const CKComponentStateUpdateMap &stateUpdates,
                                        CKComponent *(^componentFactory)(void),
                                        CKBuildComponentConfig config = {});

/**
 The results of a build and layout operation.

 A bounds animations are returned in this method if a component in the hierarchy requested an animation from its prior
 state. These animations should be applied with CKComponentBoundsAnimationApply.

 The layout returned is the complete layout of the actual component tree

 THIS IS EXPERIMENTAL, LINKED WITH THE DEFERRED CHILD COMPONENT CREATION (-render:() RFC) - DO NOT USE DIRECTLY
 */

struct CKBuildAndLayoutComponentResult {
  CKBuildComponentResult buildComponentResult;
  CKComponentRootLayout computedLayout;
};

/**
 Used to construct and layout a component hierarchy. This is necessary to configure the thread-local state so that components
 can be properly connected to a scope root.

 @param previousRoot The previous scope root that was associated with the cell. May be nil if no prior root is available
 @param stateUpdates A map of state updates that have accumulated since the last component generation was constructed.
 @param sizeRange The size range to compute the component layout within.
 @param componentFactory A block that constructs your component. Must not be nil.
 @param config Provides extra build configuration.

 THIS IS EXPERIMENTAL, LINKED WITH THE DEFERRED CHILD COMPONENT CREATION (-render:() RFC) - DO NOT USE DIRECTLY
 */


CKBuildAndLayoutComponentResult CKBuildAndLayoutComponent(CKComponentScopeRoot *previousRoot,
                                                          const CKComponentStateUpdateMap &stateUpdates,
                                                          const CKSizeRange &sizeRange,
                                                          CKComponent *(^componentFactory)(void),
                                                          const std::unordered_set<CKComponentPredicate> &layoutPredicates,
                                                          CKBuildComponentConfig config = {});
