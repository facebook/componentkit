/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentScopeFrame.h"

#import <unordered_map>
#import <libkern/OSAtomic.h>

#import "CKAssert.h"
#import "CKComponentController.h"
#import "CKComponentInternal.h"
#import "CKComponentScopeHandle.h"
#import "CKComponentScopeRootInternal.h"
#import "CKComponentSubclass.h"
#import "CKEqualityHashHelpers.h"
#import "CKMacros.h"
#import "CKThreadLocalComponentScope.h"

typedef struct _CKStateScopeKey {
  Class __unsafe_unretained componentClass;
  id identifier;

  bool operator==(const _CKStateScopeKey &v) const {
    return (CKObjectIsEqual(this->componentClass, v.componentClass) && CKObjectIsEqual(this->identifier, v.identifier));
  }
} _CKStateScopeKey;

namespace std {
  template <>
  struct hash<_CKStateScopeKey> {
    size_t operator ()(_CKStateScopeKey k) const {
      NSUInteger subhashes[] = { [k.componentClass hash], [k.identifier hash] };
      return CKIntegerArrayHash(subhashes, CK_ARRAY_COUNT(subhashes));
    }
  };
}

@implementation CKComponentScopeFrame
{
  std::unordered_map<_CKStateScopeKey, CKComponentScopeFrame *> _children;
}

+ (CKComponentScopeFramePair)childPairForPair:(const CKComponentScopeFramePair &)pair
                                      newRoot:(CKComponentScopeRoot *)newRoot
                               componentClass:(Class)componentClass
                                   identifier:(id)identifier
                          initialStateCreator:(id (^)())initialStateCreator
                                 stateUpdates:(const CKComponentStateUpdateMap &)stateUpdates
{
  CKCAssert([componentClass isSubclassOfClass:[CKComponent class]], @"%@ is not a component", NSStringFromClass(componentClass));
  CKAssertNotNil(pair.frame, @"Must have frame");

  CKComponentScopeFrame *existingChildFrameOfEquivalentPreviousFrame;
  if (pair.equivalentPreviousFrame) {
    const auto &equivalentPreviousFrameChildren = pair.equivalentPreviousFrame->_children;
    const auto it = equivalentPreviousFrameChildren.find({componentClass, identifier});
    existingChildFrameOfEquivalentPreviousFrame = (it == equivalentPreviousFrameChildren.end()) ? nil : it->second;
  }

  const auto existingChild = pair.frame->_children.find({componentClass, identifier});
  if (!pair.frame->_children.empty() && (existingChild != pair.frame->_children.end())) {
    /*
     The component was involved in a scope collision and the scope handle needs to be reacquired.
     In the event of a component scope collision the component scope frames reuses the existing scope handle; any
     existing state will be made available to the component that introduced the scope collision. This leads to some
     interesting side effects:

       1. Any component state associated with the scope handle will be shared between components with colliding scopes
       2. Any component controller associated with the scope handle will be responsible for each component with
          colliding scopes; resulting in strange behavior while components are mounted, unmounted, etc.

     Reusing the existing scope handle allows ComponentKit to detect component scope collisions during layout. Moving
     component scope collision detection to component layout makes it possible to create multiple components that may
     normally result in a scope collision even if only one component actually makes it to layout.
    */
    CKComponentScopeHandle *newHandle = [existingChild->second.handle newHandleToBeReacquiredDueToScopeCollision];
    CKComponentScopeFrame *newChild = [[CKComponentScopeFrame alloc] initWithHandle:newHandle];
    return {.frame = newChild, .equivalentPreviousFrame = existingChildFrameOfEquivalentPreviousFrame};
  }

  CKComponentScopeHandle *newHandle =
  existingChildFrameOfEquivalentPreviousFrame
  ? [existingChildFrameOfEquivalentPreviousFrame.handle newHandleWithStateUpdates:stateUpdates]
  : [[CKComponentScopeHandle alloc] initWithListener:newRoot.listener
                                      rootIdentifier:newRoot.globalIdentifier
                                      componentClass:componentClass
                                 initialStateCreator:initialStateCreator];

  [newRoot registerAnnounceableEventsForController:newHandle.controller];

  CKComponentScopeFrame *newChild = [[CKComponentScopeFrame alloc] initWithHandle:newHandle];
  pair.frame->_children.insert({{componentClass, identifier}, newChild});
  return {.frame = newChild, .equivalentPreviousFrame = existingChildFrameOfEquivalentPreviousFrame};
}

- (instancetype)initWithHandle:(CKComponentScopeHandle *)handle
{
  if (self = [super init]) {
    _handle = handle;
  }
  return self;
}

@end
