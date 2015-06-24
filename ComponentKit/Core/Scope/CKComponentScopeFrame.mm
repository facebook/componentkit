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

  // Find the existing child, if any, in the old frame
  CKComponentScopeFrame *existingChild;
  if (pair.equivalentPreviousFrame) {
    const auto &equivalentPreviousFrameChildren = pair.equivalentPreviousFrame->_children;
    const auto it = equivalentPreviousFrameChildren.find({componentClass, identifier});
    existingChild = (it == equivalentPreviousFrameChildren.end()) ? nil : it->second;
  }

  CKComponentScopeHandle *newHandle =
  existingChild ? [existingChild.handle newHandleWithStateUpdates:stateUpdates] :
  [[CKComponentScopeHandle alloc] initWithListener:newRoot.listener
                                    rootIdentifier:newRoot.globalIdentifier
                                    componentClass:componentClass
                               initialStateCreator:initialStateCreator];

  [newRoot registerAnnounceableEventsForController:newHandle.controller];

  CKComponentScopeFrame *newChild = [[CKComponentScopeFrame alloc] initWithHandle:newHandle];
  const auto result = pair.frame->_children.insert({{componentClass, identifier}, newChild});
  CKAssert(result.second, @"Scope collision: attempting to create duplicate scope %@:%@", componentClass, identifier);
  return {.frame = newChild, .equivalentPreviousFrame = existingChild};
}

- (instancetype)initWithHandle:(CKComponentScopeHandle *)handle
{
  if (self = [super init]) {
    _handle = handle;
  }
  return self;
}

@end
