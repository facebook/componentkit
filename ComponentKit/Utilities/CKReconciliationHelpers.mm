/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKReconciliationHelpers.h"

#import <ComponentKit/CKBuildComponent.h>
#import <ComponentKit/CKTreeNodeProtocol.h>

namespace CKReconciliation {
  auto hasDirtyParent(id<CKTreeNodeProtocol> node,
                      id<CKTreeNodeWithChildrenProtocol> previousParent,
                      const CKBuildComponentTreeParams &params,
                      const CKBuildComponentConfig &config) -> BOOL {
    if (previousParent && params.buildTrigger == BuildTrigger::StateUpdate && (config.enableFasterStateUpdates || config.enableFasterPropsUpdates)) {
      auto const dirtyNodeId = params.treeNodeDirtyIds.find(node.nodeIdentifier);
      return dirtyNodeId != params.treeNodeDirtyIds.end();
    }
    return NO;
  }
}
