/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKMemoizingComponent.h"

#import <mutex>

#import "CKComponentMemoizer.h"
#import "CKComponentScope.h"
#import "CKComponentSubclass.h"

/**
 Memoizers work by preparing a thread-local stack. We want to be able to preserve this state between component tree
 creation and layout. We do this through the state associated with this component's scope. This is a "best attempt"
 approach at memoization. For instance, it's possible that a memoizable hierarchy is being built or laid out on two
 threads simultaneously. This state wrapper can therefore be used by multiple threads simultaneously. We protect the
 memoization state (which cannot be safely used by multiple threads simultaneously) by forcing the calling threads
 to take "ownership" over that state during the execution of its block. If any other threads attempt to access the
 memoization state while a block execution is ongoing, it will fail to access the memoization state that was already
 granted to the first calling thread, and memoization will fail there (that's OK, we just have to try our best at
 memoizing the results). Since this should be very rare, this isn't a big deal so long as the operation is safe.
 
 This is somewhat antithetical to the design of Components, in that we're storing a mutable value into our state without
 using the updateState: mechanism. Sadly, updateState: won't work here, since we would end up in an infinite loop of
 updates. We would receive an update from something, which would cause us to update our memoization state after
 computing the memoized hierarchy, then this would trigger another state update.
 */
@interface CKMemoizingComponentStateWrapper : NSObject

- (void)executeBlockWithMemoizationState:(id (^)(id memoizationState))block;

@end

@implementation CKMemoizingComponentStateWrapper
{
  id _memoizationState;
  std::mutex _mutex;
}

- (void)executeBlockWithMemoizationState:(id (^)(id))block
{
  // We have to avoid calling the block while we are locked. Components can be created or laid out on multiple threads
  // simultaneously, and this state wrapper may be shared between multiple threads simultaneously. If we were to just
  // lock for the block (even though that would be a little scary, it'd still be hard to deadlock), then we could
  // easily introduce a priority inversion as the main thread is stuck waiting on a bg thread component creation.
  id memoizationState = nil;
  {
    std::lock_guard<std::mutex> l(_mutex);
    memoizationState = _memoizationState;
    // Un-set it here within the protection of the lock, so any other threads accessing while we execute the block get
    // a nil memoization state.
    _memoizationState = nil;
  }

  const id newMemoizationState = block(memoizationState);

  {
    std::lock_guard<std::mutex> l(_mutex);
    _memoizationState = newMemoizationState;
  }
}

@end

@implementation CKMemoizingComponent
{
  CKMemoizingComponentStateWrapper *_wrapper;
  CKComponent *_component;
}

+ (id)initialState
{
  return [CKMemoizingComponentStateWrapper new];
}

+ (instancetype)newWithComponentBlock:(CKComponent *(^)())block
{
  CKComponentScope scope(self);

  CKMemoizingComponentStateWrapper *wrapper = scope.state();

  __block CKComponent *result = nil;

  [wrapper executeBlockWithMemoizationState:^id(id memoizationState) {
    CKComponentMemoizer memoizer(memoizationState);

    result = block();

    return memoizer.nextMemoizerState();
  }];

  CKMemoizingComponent *c = [super newWithView:{} size:{}];
  if (c) {
    c->_wrapper = wrapper;
    c->_component = result;
  }
  return c;
}

- (CKComponentLayout)computeLayoutThatFits:(CKSizeRange)constrainedSize
                          restrictedToSize:(const CKComponentSize &)size
                      relativeToParentSize:(CGSize)parentSize
{
  __block CKComponentLayout l;
  [_wrapper executeBlockWithMemoizationState:^id(id memoizationState) {
    CKComponentMemoizer memoizer(memoizationState);
    l = [_component layoutThatFits:constrainedSize parentSize:parentSize];
    return memoizer.nextMemoizerState();
  }];
  return {self, l.size, {{{0,0}, l}}};
}

@end
