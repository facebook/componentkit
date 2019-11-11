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
                               buildTrigger:(CKBuildTrigger)buildTrigger
                               stateUpdates:(const CKComponentStateUpdateMap &)stateUpdates
          enableComponentReuseOptimizations:(BOOL)enableComponentReuseOptimizations {}

- (void)didBuildComponentTreeWithScopeRoot:(CKComponentScopeRoot *)scopeRoot
                              buildTrigger:(CKBuildTrigger)buildTrigger
                              stateUpdates:(const CKComponentStateUpdateMap &)stateUpdates
                                 component:(CKComponent *)component
        enableComponentReuseOptimizations:(BOOL)enableComponentReuseOptimizations {}

- (void)willMountComponentTreeWithRootComponent:(id<CKMountable>)component
{
  _willMountComponentHitCount++;
}

- (void)didMountComponentTreeWithRootComponent:(id<CKMountable>)component
                         mountAnalyticsContext:(CK::Optional<CK::Component::MountAnalyticsContext>)mountAnalyticsContext
{
  _didMountComponentHitCount++;
  mountAnalyticsContext.apply([&](const auto &mc) {
    _viewAllocationsCount += mc.viewAllocations;
  });
}

- (void)willCollectAnimationsFromComponentTreeWithRootComponent:(id<CKMountable>)component
{
  _willCollectAnimationsHitCount++;
}

- (void)didCollectAnimationsFromComponentTreeWithRootComponent:(id<CKMountable>)component
{
  _didCollectAnimationsHitCount++;
}

- (void)willLayoutComponentTreeWithRootComponent:(id<CKMountable>)component buildTrigger:(CK::Optional<CKBuildTrigger>)buildTrigger
{
  _willLayoutComponentTreeHitCount++;
}
- (void)didLayoutComponentTreeWithRootComponent:(id<CKMountable>)component { _didLayoutComponentTreeHitCount++; }

- (void)willBuildComponent:(Class)componentClass {}
- (void)didBuildComponent:(Class)componentClass {}

- (void)willMountComponent:(id<CKMountable>)component {}
- (void)didMountComponent:(id<CKMountable>)component {}

- (void)willLayoutComponent:(id<CKMountable>)component {}
- (void)didLayoutComponent:(id<CKMountable>)component {}

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
