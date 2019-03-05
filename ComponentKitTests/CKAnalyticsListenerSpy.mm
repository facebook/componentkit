/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKAnalyticsListenerSpy.h"

#import <ComponentKit/CKComponentScopeRoot.h>

@implementation CKAnalyticsListenerSpy

- (void)willBuildComponentTreeWithScopeRoot:(CKComponentScopeRoot *)scopeRoot
                               buildTrigger:(BuildTrigger)buildTrigger
                               stateUpdates:(const CKComponentStateUpdateMap &)stateUpdates {}
- (void)didBuildComponentTreeWithScopeRoot:(CKComponentScopeRoot *)scopeRoot component:(CKComponent *)component {}

- (void)willMountComponentTreeWithRootComponent:(CKComponent *)component {}
- (void)didMountComponentTreeWithRootComponent:(CKComponent *)component
                         mountAnalyticsContext:(CK::Component::MountAnalyticsContext *)mountAnalyticsContext {}

- (void)willCollectAnimationsFromComponentTreeWithRootComponent:(CKComponent *)component
{
  _willCollectAnimationsHitCount++;
}

- (void)didCollectAnimationsFromComponentTreeWithRootComponent:(CKComponent *)component
{
  _didCollectAnimationsHitCount++;
}

- (void)willLayoutComponentTreeWithRootComponent:(CKComponent *)component { _willLayoutComponentTreeHitCount++; }
- (void)didLayoutComponentTreeWithRootComponent:(CKComponent *)component { _didLayoutComponentTreeHitCount++; }

- (void)willBuildComponent:(Class)componentClass {}
- (void)didBuildComponent:(Class)componentClass {}

- (void)willMountComponent:(CKComponent *)component {}
- (void)didMountComponent:(CKComponent *)component {}

- (void)willLayoutComponent:(CKComponent *)component {}
- (void)didLayoutComponent:(CKComponent *)component {}

- (id<CKSystraceListener>)systraceListener { return nil; }

- (BOOL)shouldCollectMountInformationForRootComponent:(CKComponent *)component { return NO; }

- (void)didReuseNode:(id<CKTreeNodeProtocol>)node inScopeRoot:(CKComponentScopeRoot *)scopeRoot fromPreviousScopeRoot:(CKComponentScopeRoot *)previousScopeRoot {}

@end
