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

#import <Foundation/Foundation.h>

#import <ComponentKit/CKBuildComponentResult.h>
#import <ComponentKit/CKComponentScopeTypes.h>
#import <ComponentKit/CKGlobalConfig.h>
#import <ComponentKit/RCComponentCoalescingMode.h>

@class CKComponentScopeRoot;
@class CKComponent;

/**
 Used to derive the build trigger that issued a new component hierarchy.

 @param scopeRoot The scope root that is associated with the component .hierarchy
 @param stateUpdates A map of state updates that have accumulated since the last component generation was constructed.
 @param treeEnvironmentChanged Indicates that the tree needs a complete reflow because env changed (results in ignoring all reuse optimizations).
 @param treeHasPropsUpdate Indicates that the tree has some updated props.
 @return The related build trigger given the in input parameters
 */

auto CKBuildComponentTrigger(CK::NonNull<CKComponentScopeRoot *> scopeRoot,
                             const CKComponentStateUpdateMap &stateUpdates,
                             BOOL treeEnvironmentChanged,
                             BOOL treeHasPropsUpdate) -> CKBuildTrigger;

/**
 Used to construct a component hierarchy. This is necessary to configure the thread-local state so that components
 can be properly connected to a scope root.

 @param previousRoot The previous scope root that was associated with the cell.
 @param stateUpdates A map of state updates that have accumulated since the last component generation was constructed.
 @param componentFactory A block that constructs your component. Must not be nil.
 */

CKBuildComponentResult CKBuildComponent(CK::NonNull<CKComponentScopeRoot *> previousRoot,
                                        const CKComponentStateUpdateMap &stateUpdates,
                                        NS_NOESCAPE CKComponent *(^componentFactory)(void));


/**
 Used to construct a component hierarchy. This is necessary to configure the thread-local state so that components
 can be properly connected to a scope root.

 @param previousRoot The previous scope root that was associated with the cell.
 @param stateUpdates A map of state updates that have accumulated since the last component generation was constructed.
 @param componentFactory A block that constructs your component. Must not be nil.
 @param buildTrigger An enum that indicates why the component tree has been (re)generated
 @param reflowTrigger An enum that indicates why the components tree has been reflown.
 @param coalescingMode Defines the coalescing mode to use for the current component tree.
 */
CKBuildComponentResult CKBuildComponent(CK::NonNull<CKComponentScopeRoot *> previousRoot,
                                        const CKComponentStateUpdateMap &stateUpdates,
                                        NS_NOESCAPE CKComponent *(^componentFactory)(void),
                                        CKBuildTrigger buildTrigger,
                                        CKReflowTrigger reflowTrigger,
                                        RCComponentCoalescingMode coalescingMode = CKReadGlobalConfig().coalescingMode);

#endif
