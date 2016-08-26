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

     In the event of a component scope collision the component scope frame reuses the existing scope handle; any
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
    /*
     Share the initial component scope tree across all colliding component scopes.

     This behavior ensures the initial component scope tree "wins" in the event of a component scope collision:

                                       +-------+         +-------+         +-------+
                                       |       |         |       |         |       |
                                       |   A   |         |   A   |         |   A   |
                                       |      1|         |      2|         |      3|
                                       +-------+         +-------+         +-------+
                                           |                 | collision       | collision
                                           +-----------------+-----------------+
                                          /|\
                                         / | \
                                        /  |  \
                                   +---+ +---+ +---+
                                   | 1 | | 2 | | 3 |
                                   +---+ +---+ +---+
                                    / \
                                +---+ +---+
                                | 4 | | 5 |
                                +---+ +---+

     In the example above the component scope frames labeled as "A" are involved in scope collisions. Notice that only
     one component scope tree exists for all three component scope frames involved in the collision. Any component state
     or component controllers present in the intial component scope tree are now present across all colliding component
     scope frames.

     Now assume each component scope frame above is paired with a matching component. Component scope frame A1 belongs
     to component A1, colliding component scope frame A2 belongs to component A2, component scope frame 4 belongs to
     component 4, and so on. If only component A2 finds its way to layout (i.e. both A1 and A3 were simply created and
     not added to the component hierarchy) this behavior guarantees that component 4 always acquires the same component
     scope.

     Compare this behavior to the behavior that would exist if the initial component scope tree were not shared:

                                       +-------+         +-------+         +-------+
                                       |       |         |       |         |       |
                                       |   A   |         |   A   |         |   A   |
                                       |      1|         |      2|         |      3|
                                       +-------+         +-------+         +-------+
                                           |                 | collision       | collision
                                           +-----------------+-----------------+
                                          /|\                .                /|\
                                         / | \               .               / | \
                                        /  |  \              .              /  |  \
                                   +---+ +---+ +---+                   +---+ +---+ +---+
                                   | 1 | | 2 | | 3 |                   | 1'| | 2'| | 3'|
                                   +---+ +---+ +---+                   +---+ +---+ +---+
                                    / \                                 / \
                                +---+ +---+                         +---+ +---+
                                | 4 | | 5 |                         | 4'| | 5'|
                                +---+ +---+                         +---+ +---+

     Each component scope frame participating in the collision now has its own unique component scope tree. For
     component scope frame A1 the outcome is largely the same. Things get a bit more interesting for A2 and A3. Notice
     that A3 now has its own, nearly identical, component scope tree. The structure is the same but the component state
     and component controllers are different.

     Problems arise when the component that owns component scope frame A3 is added to the component hierarchy. Suppose
     A3 is building its component scope tree for the first time. The component that owns component scope frame 4' will
     acquire a new component controller as there is no equivalent previous frame, as expected.

     The next time the component hierarchy is created (e.g. after a component state update) component scope frame 4'
     actually finds component scope frame 4 in the equivalent previous frame. This means component 4' will acquire a
     DIFFERENT component controller instance than it had originally. Why? Because the component scope frame above
     component scope frame A will only ever have A1 as a child because A1 was inserted before A2 and A3.
     */
    newChild->_children = existingChild->second->_children;
    return {.frame = newChild, .equivalentPreviousFrame = existingChildFrameOfEquivalentPreviousFrame};
  }

  CKComponentScopeHandle *newHandle =
  existingChildFrameOfEquivalentPreviousFrame
  ? [existingChildFrameOfEquivalentPreviousFrame.handle newHandleWithStateUpdates:stateUpdates]
  : [[CKComponentScopeHandle alloc] initWithListener:newRoot.listener
                                      rootIdentifier:newRoot.globalIdentifier
                                      componentClass:componentClass
                                 initialStateCreator:initialStateCreator];

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
