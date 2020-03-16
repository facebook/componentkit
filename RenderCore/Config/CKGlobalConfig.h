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

@protocol CKAnalyticsListener;

struct CKGlobalConfig {
  /** Default analytics listener which will be used in cased that no other listener is provided */
  id<CKAnalyticsListener> defaultAnalyticsListener = nil;
  /** If enabled, CKBuildComponent will always build the component tree (CKTreeNode), even if there is no Render component in the tree*/
  BOOL alwaysBuildRenderTree = NO;
  /** Same as above, but only in DEBUG configuration */
  BOOL alwaysBuildRenderTreeInDebug = YES;
  /**
   Uses the composite component child size to assign size
   properties on yoga node instead of the size of composite component itself
   */
  BOOL skipCompositeComponentSize = YES;
  /**
   Avoid duplicate links in the tree nodes for owner/parent based nodes
   */
  BOOL mergeTreeNodesLinks = NO;
};

CKGlobalConfig CKReadGlobalConfig();

#endif
