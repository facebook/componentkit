/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <RenderCore/CKDefines.h>

#if CK_NOT_SWIFT

#import <Foundation/Foundation.h>
#import <RenderCore/CKComponentCoalescingMode.h>

@protocol CKAnalyticsListener;

struct CKGlobalConfig {
  /** Default analytics listener which will be used in cased that no other listener is provided */
  id<CKAnalyticsListener> defaultAnalyticsListener = nil;
  /** If enabled, CKBuildComponent will always build the component tree (CKTreeNode), even if there is no Render component in the tree*/
  BOOL alwaysBuildRenderTree = NO;
  /**
   Uses the composite component child size to assign size
   properties on yoga node instead of the size of composite component itself
   */
  BOOL skipCompositeComponentSize = YES;
  /**
   Use new method of performing optimistic mutations which can last beyond next mount
   */
  BOOL useNewStyleOptimisticMutations = NO;
  /**
   Component coalescing mode.
   */
   CKComponentCoalescingMode coalescingMode = CKComponentCoalescingModeNone;
};

CKGlobalConfig CKReadGlobalConfig();

#endif
