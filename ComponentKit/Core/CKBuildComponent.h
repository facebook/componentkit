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

@class CKComponentScopeRoot;
@class CKComponent;

namespace CKBuildComponentHelpers {
  /**
   Depending on the scope root and the list of state updates the proper build trigger is derived.

   @return The related build trigger given the in input parameters
   */
  auto getBuildTrigger(CKComponentScopeRoot *scopeRoot, const CKComponentStateUpdateMap &stateUpdates) -> CKBuildTrigger;
}

/**
 Used to construct a component hierarchy. This is necessary to configure the thread-local state so that components
 can be properly connected to a scope root.

 @param previousRoot The previous scope root that was associated with the cell. May be nil if no prior root is available
 @param stateUpdates A map of state updates that have accumulated since the last component generation was constructed.
 @param componentFactory A block that constructs your component. Must not be nil.
 @param enableComponentReuseOptimizations If `NO`, all the comopnents will be regenerated (no component reuse optimiztions). `YES` by default.
 @param mergeTreeNodesLinks if `YES`, the tree nodes tree will merge owner/parent based links.
 */
CKBuildComponentResult CKBuildComponent(CKComponentScopeRoot *previousRoot,
                                        const CKComponentStateUpdateMap &stateUpdates,
                                        CKComponent *(^componentFactory)(void),
                                        BOOL enableComponentReuseOptimizations = YES,
                                        BOOL mergeTreeNodesLinks = CKReadGlobalConfig().mergeTreeNodesLinks);

#endif
