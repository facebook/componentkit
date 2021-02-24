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

#import <ComponentKit/CKDefines.h>
#import <ComponentKit/CKBuildTrigger.h>
#import <ComponentKit/CKComponentScopeTypes.h>
#import <ComponentKit/CKTreeNodeTypes.h>
#import <ComponentKit/RCComponentCoalescingMode.h>

NS_ASSUME_NONNULL_BEGIN

@class CKComponentScopeRoot;

@protocol CKSystraceListener;

#if CK_NOT_SWIFT

/**
 Params struct for the `buildComponentTree:` method.
 **/
struct CKBuildComponentTreeParams {
  // Weak reference to the scope root of the new generation.
  __weak CKComponentScopeRoot *scopeRoot;

  // Weak reference to the scope root of the previous generation.
  __weak CKComponentScopeRoot *previousScopeRoot;

  // A map of state updates
  const CKComponentStateUpdateMap &stateUpdates;

  // Colleciton of nodes that are marked as dirty.
  // @discussion "Dirty nodes" are used to implement optimizations as faster state updates and faster props updates.
  const CKTreeNodeDirtyIds &treeNodeDirtyIds;

  // The trigger for initiating a new generation
  CKBuildTrigger buildTrigger;

  // The current systrace listener. Can be nil if systrace is not enabled.
  id<CKSystraceListener> _Nullable systraceListener;

  // Collect tree node information for logging.
  BOOL shouldCollectTreeNodeCreationInformation;

  // The current coalescing mode.
  RCComponentCoalescingMode coalescingMode = RCComponentCoalescingModeRender;
};

#endif

NS_ASSUME_NONNULL_END
