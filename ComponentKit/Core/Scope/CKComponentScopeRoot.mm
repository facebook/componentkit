/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentScopeRoot.h"
#import "CKComponentScopeRootInternal.h"

#import <libkern/OSAtomic.h>

#import "CKComponentController.h"
#import "CKComponentInternal.h"
#import "CKComponentSubclass.h"
#import "CKInternalHelpers.h"
#import "CKThreadLocalComponentScope.h"

typedef std::unordered_map<CKComponentAnnouncedEvent, SEL, std::hash<NSUInteger>, std::equal_to<NSUInteger>> CKAnounceableEventMap;

static const CKAnounceableEventMap &announceableEvents()
{
  // Avoid the static destructor fiasco, use a pointer:
  static const CKAnounceableEventMap *announceableEvents = new CKAnounceableEventMap({
    {CKComponentAnnouncedEventTreeWillAppear, @selector(componentTreeWillAppear)},
    {CKComponentAnnouncedEventTreeDidDisappear, @selector(componentTreeDidDisappear)},
  });
  return *announceableEvents;
}

CKBuildComponentResult CKBuildComponent(CKComponentScopeRoot *previousRoot,
                                        const CKComponentStateUpdateMap &stateUpdates,
                                        CKComponent *(^function)(void))
{
  CKThreadLocalComponentScope threadScope(previousRoot, stateUpdates);
  // Order of operations matters, so first store into locals and then return a struct.
  CKComponent *component = function();
  return {
    .component = component,
    .scopeRoot = threadScope.newScopeRoot,
    .boundsAnimation = [threadScope.newScopeRoot boundsAnimationFromPreviousScopeRoot:previousRoot],
  };
}

@implementation CKComponentScopeRoot
{
  std::unordered_multimap<CKComponentAnnouncedEvent, CKComponentController *, std::hash<NSUInteger>, std::equal_to<NSUInteger>> _eventRegistration;
  NSHashTable *_boundsAnimationComponents; // weakly held
}

+ (instancetype)rootWithListener:(id<CKComponentStateListener>)listener
{
  static int32_t nextGlobalIdentifier = 0;
  return [[CKComponentScopeRoot alloc] initWithListener:listener globalIdentifier:OSAtomicIncrement32(&nextGlobalIdentifier)];
}

- (instancetype)newRoot
{
  return [[CKComponentScopeRoot alloc] initWithListener:_listener globalIdentifier:_globalIdentifier];
}

- (instancetype)initWithListener:(id<CKComponentStateListener>)listener
                globalIdentifier:(CKComponentScopeRootIdentifier)globalIdentifier
{
  if (self = [super init]) {
    _listener = listener;
    _globalIdentifier = globalIdentifier;
    _rootFrame = [[CKComponentScopeFrame alloc] initWithHandle:nil];
    _boundsAnimationComponents = [NSHashTable weakObjectsHashTable];
  }
  return self;
}

- (void)registerAnnounceableEventsForController:(CKComponentController *)controller
{
  for (const auto &announceableEvent : announceableEvents()) {
    if (CKSubclassOverridesSelector([CKComponentController class], [controller class], announceableEvent.second)) {
      _eventRegistration.insert({{announceableEvent.first, controller}});
    }
  }
}

- (void)announceEventToControllers:(CKComponentAnnouncedEvent)announcedEvent
{
  const auto range = _eventRegistration.equal_range(announcedEvent);
  const SEL sel = announceableEvents().at(announcedEvent);
  for (auto it = range.first; it != range.second; ++it) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [it->second performSelector:sel];
#pragma clang diagnostic pop
  }
}

- (void)registerBoundsAnimationComponent:(CKComponent *)component
{
  [_boundsAnimationComponents addObject:component];
}

- (NSHashTable *)boundsAnimationComponents
{
  return _boundsAnimationComponents;
}

- (CKComponentBoundsAnimation)boundsAnimationFromPreviousScopeRoot:(CKComponentScopeRoot *)previousRoot
{
  NSMapTable *scopeFrameTokenToOldComponent = [NSMapTable strongToStrongObjectsMapTable];
  for (CKComponent *oldComponent in [previousRoot boundsAnimationComponents]) {
    id scopeFrameToken = [oldComponent scopeFrameToken];
    if (scopeFrameToken) {
      [scopeFrameTokenToOldComponent setObject:oldComponent forKey:scopeFrameToken];
    }
  }

  for (CKComponent *newComponent in [self boundsAnimationComponents]) {
    id scopeFrameToken = [newComponent scopeFrameToken];
    if (scopeFrameToken) {
      CKComponent *oldComponent = [scopeFrameTokenToOldComponent objectForKey:scopeFrameToken];
      if (oldComponent) {
        const CKComponentBoundsAnimation ba = [newComponent boundsAnimationFromPreviousComponent:oldComponent];
        if (ba.duration != 0) {
          return ba;
        }
      }
    }
  }

  return {};
}

@end
