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
#import <RenderCore/CKComponentBasedAccessibilityMode.h>

@protocol CKAnalyticsListener;

struct CKGlobalConfig {
  /** Default analytics listener which will be used in cased that no other listener is provided */
  id<CKAnalyticsListener> defaultAnalyticsListener = nil;
  /** If enabled, CKBuildComponent will always build the component tree (CKTreeNode), even if there is no Render component in the tree*/
  BOOL alwaysBuildRenderTree = NO;
  /**
   Uses the overlayout layout component child size to assign size
   properties on yoga node instead of the size of overlayout component itself
   */
  BOOL useNodeSizeOverlayComponent = NO;
  /**
   Instead of setting resolving the percentage size manually from parent size
   set the percent on the yoga node itself instead
   */
  BOOL setPercentOnChildNode = NO;
  /**
   Use new method of performing optimistic mutations which can last beyond next mount
   */
  BOOL useNewStyleOptimisticMutations = NO;
  /**
   Component coalescing mode.
   */
  CKComponentCoalescingMode coalescingMode = CKComponentCoalescingModeNone;
  /**
   When true, use -[CKComponent layoutThatFits_ExtractedAssertions:parentSize:]
   */
  BOOL stackSizeRegressionCKComponentLayoutThatFitsExtractAssertions = NO;
  /**
    Component based accessibility mode
   */
   CKComponentBasedAccessibilityMode componentAXMode = CKComponentBasedAccessibilityModeDisabled;
};

CKGlobalConfig CKReadGlobalConfig();

#endif
