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
{
  id<CKDebugAnalyticsListener> _debugAnalyticsListener;
}

+ (instancetype)newWithDebugAnalyticsListener:(id<CKDebugAnalyticsListener>)debugAnalyticsListener
{
  auto const a = [super new];
  if (a) {
    a->_debugAnalyticsListener = debugAnalyticsListener;
  }
  return a;
}

- (void)willBuildComponentTreeWithScopeRoot:(CKComponentScopeRoot *)scopeRoot
                               buildTrigger:(BuildTrigger)buildTrigger
                               stateUpdates:(const CKComponentStateUpdateMap &)stateUpdates {}

- (void)didBuildComponentTreeWithScopeRoot:(CKComponentScopeRoot *)scopeRoot
                              buildTrigger:(BuildTrigger)buildTrigger
                                 component:(CKComponent *)component {}

- (void)willMountComponentTreeWithRootComponent:(CKComponent *)component
{
  _willMountComponentHitCount++;
}

- (void)didMountComponentTreeWithRootComponent:(CKComponent *)component
                         mountAnalyticsContext:(CK::Component::MountAnalyticsContext *)mountAnalyticsContext
{
  _didMountComponentHitCount++;
}

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
- (id<CKDebugAnalyticsListener>)debugAnalyticsListener { return _debugAnalyticsListener; }

- (BOOL)shouldCollectMountInformationForRootComponent:(CKComponent *)component { return NO; }

- (void)didReuseNode:(id<CKTreeNodeProtocol>)node inScopeRoot:(CKComponentScopeRoot *)scopeRoot fromPreviousScopeRoot:(CKComponentScopeRoot *)previousScopeRoot {}

@end
