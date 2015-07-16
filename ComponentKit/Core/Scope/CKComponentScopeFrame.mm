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
#import <vector>

#import <ComponentKit/CKAssert.h>
#import <ComponentKit/CKMacros.h>
#import <ComponentKit/CKComponentSubclass.h>

#import "CKInternalHelpers.h"
#import "CKComponentController.h"
#import "CKComponentInternal.h"
#import "CKComponentScopeInternal.h"
#import "CKCompositeComponent.h"

#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

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

static const std::vector<SEL> announceableEvents = {
  @selector(componentTreeWillAppear),
  @selector(componentTreeDidDisappear),
};

@interface CKComponentScopeFrame ()
@property (nonatomic, weak, readwrite) CKComponentScopeFrame *root;
@end

@implementation CKComponentScopeFrame {
  id _modifiedState;
  std::unordered_map<_CKStateScopeKey, CKComponentScopeFrame *> _children;
  std::unordered_multimap<SEL, CKComponentController *> _eventRegistration;
}

- (instancetype)initWithListener:(id<CKComponentStateListener>)listener
                           class:(Class __unsafe_unretained)aClass
                      identifier:(id)identifier
                           state:(id)state
                      controller:(CKComponentController *)controller
                            root:(CKComponentScopeFrame *)rootFrame
{
  if (self = [super init]) {
    _listener = listener;
    _componentClass = aClass;
    _identifier = identifier;
    _state = state;
    _controller = controller;
    _root = rootFrame ? rootFrame : self;

    for (const auto announceableEvent : announceableEvents) {
      if (CKSubclassOverridesSelector([CKComponentController class], [controller class], announceableEvent)) {
        [_root registerController:controller forSelector:announceableEvent];
      }
    }
  }
  return self;
}

- (instancetype)init
{
  CK_NOT_DESIGNATED_INITIALIZER();
}

+ (instancetype)rootFrameWithListener:(id<CKComponentStateListener>)listener
{
  return [[self alloc] initWithListener:listener class:Nil identifier:nil state:nil controller:nil root:nil];
}

- (instancetype)childFrameWithComponentClass:(Class __unsafe_unretained)aClass
                                  identifier:(id)identifier
                                       state:(id)state
                                  controller:(CKComponentController *)controller
{
  CKComponentScopeFrame *child = [[[self class] alloc] initWithListener:_listener
                                                                  class:aClass
                                                             identifier:identifier
                                                                  state:state
                                                             controller:controller
                                                                   root:_root];
  const auto result = _children.insert({{child.componentClass, child.identifier}, child});
  CKCAssert(result.second, @"Scope collision! Attempting to create scope %@::%@ when it already exists.",
            aClass, identifier);
  return child;
}

- (CKComponentScopeFrame *)existingChildFrameWithClass:(__unsafe_unretained Class)aClass identifier:(id)identifier
{
  const auto it = _children.find({aClass, identifier});
  return (it == _children.end()) ? nil : it->second;
}

- (CKComponentBoundsAnimation)boundsAnimationFromPreviousFrame:(CKComponentScopeFrame *)previousFrame
{
  if (previousFrame == nil) {
    return {};
  }

  // _owningComponent is __weak, so we must store into strong locals to prevent racing with it becoming nil.
  CKComponent *newComponent = _owningComponent;
  CKComponent *oldComponent = previousFrame->_owningComponent;
  if (newComponent && oldComponent) {
    const CKComponentBoundsAnimation anim = [newComponent boundsAnimationFromPreviousComponent:oldComponent];
    if (anim.duration != 0) {
      return anim;
    }
  }

  const auto &oldChildren = previousFrame->_children;
  for (const auto &newIt : _children) {
    const auto oldIt = oldChildren.find(newIt.first);
    if (oldIt != oldChildren.end()) {
      const CKComponentBoundsAnimation anim = [newIt.second boundsAnimationFromPreviousFrame:oldIt->second];
      if (anim.duration != 0) {
        return anim;
      }
    }
  }

  return {};
}

#pragma mark - State

- (id)updatedState
{
  return _modifiedState ?: _state;
}

- (void)updateState:(id (^)(id))updateFunction tryAsynchronousUpdate:(BOOL)tryAsynchronousUpdate
{
  CKAssertNotNil(updateFunction, @"The block for updating state cannot be nil. What would that even mean?");

  _modifiedState = updateFunction(_state);
  [_listener componentStateDidEnqueueStateModificationWithTryAsynchronousUpdate:tryAsynchronousUpdate];
}

#pragma mark - Component State Acquisition

- (void)markAcquiredByComponent:(CKComponent *)component
{
  CKAssert(_acquired == NO, @"To acquire state for this component you must declare a scope in the -init method with "
           "CKComponentScope([%@ class], identifier).", NSStringFromClass([component class]));

  /* We keep a separate boolean since _owningComponent is __weak and we want this to be write-once. */
  _acquired = YES;
  _owningComponent = component;
}

- (void)registerController:(CKComponentController *)controller forSelector:(SEL)selector
{
  _eventRegistration.insert({{selector, controller}});
}

- (void)announceEventToControllers:(SEL)selector
{
  CKAssert(std::find(announceableEvents.begin(), announceableEvents.end(), selector) != announceableEvents.end(),
           @"Can only announce a whitelisted events, and %@ is not on the list.", NSStringFromSelector(selector));
  auto range = _eventRegistration.equal_range(selector);
  for (auto it = range.first; it != range.second; ++it) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [it->second performSelector:selector];
#pragma clang diagnostic pop
  }
}

@end
