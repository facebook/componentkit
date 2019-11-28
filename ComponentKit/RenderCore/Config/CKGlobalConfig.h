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

@protocol CKAnalyticsListener;

struct CKGlobalConfig {
  /** Default analytics listener which will be used in cased that no other listener is provided */
  id<CKAnalyticsListener> defaultAnalyticsListener = nil;
  /** If enabled, CKBuildComponent will always build the component tree (CKTreeNode), even if there is no Render component in the tree*/
  BOOL alwaysBuildRenderTree = NO;
  /** Same as above, but only in DEBUG configuration */
  BOOL alwaysBuildRenderTreeInDebug = YES;
  /**
   `componentController.component` will be updated right after commponent build if this is enabled.
   This is only for running expeirment in ComponentKit. Please DO NOT USE.
   */
  BOOL updateComponentInControllerAfterBuild = NO;
  /**
   `CK::Component::GlobalRootViewPool` will be used in `CKComponentHostingView` when this is enabled.
   */
  BOOL enableGlobalRootViewPoolInHostingView = NO;
  /**
   This enables acquiring lock when updating component in component controller.
   */
  BOOL shouldAcquireLockWhenUpdatingComponentInController = NO;
};

CKGlobalConfig CKReadGlobalConfig();
