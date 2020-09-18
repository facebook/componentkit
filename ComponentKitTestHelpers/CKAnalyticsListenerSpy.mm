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

using namespace CK::AnalyticsListenerSpy;

@interface CKAnalyticsListenerSpy ()
@property(atomic) NSInteger willBuildComponentTreeHitCount;
@property(atomic) NSInteger didBuildComponentTreeHitCount;
@property(atomic) NSInteger willLayoutComponentTreeHitCount;
@property(atomic) NSInteger didLayoutComponentTreeHitCount;
@property(atomic) NSInteger willCollectAnimationsHitCount;
@property(atomic) NSInteger didCollectAnimationsHitCount;
@property(atomic) NSInteger willMountComponentHitCount;
@end

@implementation CKAnalyticsListenerSpy {
  dispatch_queue_t _propertyAccessQueue;
  NSUInteger _viewAllocationsCount;
  NSUInteger _didMountComponentHitCount;
  std::vector<CK::AnalyticsListenerSpy::Event> _events;
}
@dynamic viewAllocationsCount, didMountComponentHitCount, events;

- (instancetype)init {
  self = [super init];
  if (self) {
    _propertyAccessQueue = dispatch_queue_create("ComponentKitTestHelpers.CKAnalyticsListener.PropertyAccessQueue", DISPATCH_QUEUE_SERIAL);
  }
  return self;
}

- (void)willBuildComponentTreeWithScopeRoot:(CKComponentScopeRoot *)scopeRoot
                               buildTrigger:(CKBuildTrigger)buildTrigger
                               stateUpdates:(const CKComponentStateUpdateMap &)stateUpdates
{
  self.willBuildComponentTreeHitCount++;
}

- (void)didBuildComponentTreeWithScopeRoot:(CKComponentScopeRoot *)scopeRoot
                              buildTrigger:(CKBuildTrigger)buildTrigger
                              stateUpdates:(const CKComponentStateUpdateMap &)stateUpdates
                                 component:(CKComponent *)component
                           boundsAnimation:(const CKComponentBoundsAnimation &)boundsAnimation
{
  self.didBuildComponentTreeHitCount++;
}

- (void)willMountComponentTreeWithRootComponent:(id<CKMountable>)component
{
  self.willMountComponentHitCount++;
}

- (void)didMountComponentTreeWithRootComponent:(id<CKMountable>)component
                         mountAnalyticsContext:(CK::Optional<CK::Component::MountAnalyticsContext>)mountAnalyticsContext
{
  dispatch_sync(_propertyAccessQueue, ^{
    _didMountComponentHitCount++;
    mountAnalyticsContext.apply([&](const auto &mc) {
      _viewAllocationsCount += mc.viewAllocations;
    });
  });
}

- (void)willCollectAnimationsFromComponentTreeWithRootComponent:(id<CKMountable>)component
{
  self.willCollectAnimationsHitCount++;
}

- (void)didCollectAnimations:(const CKComponentAnimations &)animations
              fromComponents:(const CK::ComponentTreeDiff &)animatedComponents
inComponentTreeWithRootComponent:(id<CKMountable>)component
         scopeRootIdentifier:(CKComponentScopeRootIdentifier)scopeRootID
{
  self.didCollectAnimationsHitCount++;
}

- (void)willLayoutComponentTreeWithRootComponent:(id<CKMountable>)component buildTrigger:(CK::Optional<CKBuildTrigger>)buildTrigger
{
  self.willLayoutComponentTreeHitCount++;
}
- (void)didLayoutComponentTreeWithRootComponent:(id<CKMountable>)component {
  self.didLayoutComponentTreeHitCount++;
}

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

- (void)didReceiveStateUpdateFromScopeHandle:(CKComponentScopeHandle *)handle rootIdentifier:(CKComponentScopeRootIdentifier)rootID {
  dispatch_sync(_propertyAccessQueue, ^{
    _events.push_back(DidReceiveStateUpdate{handle, rootID});
  });
}

- (NSInteger)didMountComponentHitCount {
  __block NSInteger result;
  dispatch_sync(_propertyAccessQueue, ^{ result = _didMountComponentHitCount; });
  return result;
}

- (NSInteger)viewAllocationsCount {
  __block NSInteger result;
  dispatch_sync(_propertyAccessQueue, ^{ result = _viewAllocationsCount; });
  return result;
}

- (std::vector<CK::AnalyticsListenerSpy::Event>)events {
  __block std::vector<CK::AnalyticsListenerSpy::Event> result;
  dispatch_sync(_propertyAccessQueue, ^{ result = _events; });
  return result;
}

@end
