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

- (void)didBuildComponentTreeWithScopeRoot:(CKComponentScopeRoot *)scopeRoot
                              buildTrigger:(BuildTrigger)buildTrigger
                              stateUpdates:(const CKComponentStateUpdateMap &)stateUpdates
                                 component:(CKComponent *)component {}

- (void)willMountComponentTreeWithRootComponent:(CKComponent *)component
{
  _willMountComponentHitCount++;
}

- (void)didMountComponentTreeWithRootComponent:(CKComponent *)component
                         mountAnalyticsContext:(CK::Component::MountAnalyticsContext *)mountAnalyticsContext
{
  _didMountComponentHitCount++;
  if (const auto mc = mountAnalyticsContext) {
    _viewAllocationsCount += mc->viewAllocations;
  }
}

- (void)willCollectAnimationsFromComponentTreeWithRootComponent:(CKComponent *)component
{
  _willCollectAnimationsHitCount++;
}

- (void)didCollectAnimationsFromComponentTreeWithRootComponent:(CKComponent *)component
{
  _didCollectAnimationsHitCount++;
}

- (void)willLayoutComponentTreeWithRootComponent:(CKComponent *)component buildTrigger:(CK::Optional<BuildTrigger>)buildTrigger
{
  _willLayoutComponentTreeHitCount++;
}
- (void)didLayoutComponentTreeWithRootComponent:(CKComponent *)component { _didLayoutComponentTreeHitCount++; }

- (void)willBuildComponent:(Class)componentClass {}
- (void)didBuildComponent:(Class)componentClass {}

- (void)willMountComponent:(CKComponent *)component {}
- (void)didMountComponent:(CKComponent *)component {}

- (void)willLayoutComponent:(CKComponent *)component {}
- (void)didLayoutComponent:(CKComponent *)component {}

- (void)willStartBlockTrace:(const char *const)blockName {}
- (void)didEndBlockTrace:(const char *const)blockName {}

- (id<CKSystraceListener>)systraceListener { return nil; }
- (BOOL)shouldCollectTreeNodeCreationInformation:(CKComponentScopeRoot *)scopeRoot { return NO; }

- (void)didBuildTreeNodeForPrecomputedChild:(id<CKTreeNodeComponentProtocol>)component
                                       node:(id<CKTreeNodeProtocol>)node
                                     parent:(id<CKTreeNodeWithChildrenProtocol>)parent
                                     params:(const CKBuildComponentTreeParams &)params
                       parentHasStateUpdate:(BOOL)parentHasStateUpdate {}

- (BOOL)shouldCollectMountInformationForRootComponent:(CKComponent *)component { return YES; }

- (void)didReuseNode:(id<CKTreeNodeProtocol>)node inScopeRoot:(CKComponentScopeRoot *)scopeRoot fromPreviousScopeRoot:(CKComponentScopeRoot *)previousScopeRoot {}

@end
