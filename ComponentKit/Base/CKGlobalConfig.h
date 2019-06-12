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

#import <ComponentKit/CKAnalyticsListener.h>

struct CKGlobalConfig {
  /** Default analytics listener which will be used in cased that no other listener is provided */
  id<CKAnalyticsListener> defaultAnalyticsListener = nil;
  /** If enabled, CKBuildComponent will always build the component tree (CKTreeNode), even if there is no Render component in the tree*/
  BOOL alwaysBuildRenderTree = NO;
  /** Same as above, but only in DEBUG configuration */
  BOOL alwaysBuildRenderTreeInDebug = NO;
  /** If enabled, we will cache the layout in render components and reuse it during a component reuse. */
  BOOL enableLayoutCacheInRender = NO;
};

CKGlobalConfig CKReadGlobalConfig();
