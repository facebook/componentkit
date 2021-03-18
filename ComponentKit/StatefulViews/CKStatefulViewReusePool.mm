/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */
#import "CKStatefulViewComponentController.h"

#import <RenderCore/RCAssert.h>
#import <ComponentKit/CKCollection.h>
#import <ComponentKit/RCDispatch.h>

#import "CKStatefulViewReusePool.h"

#import <unordered_map>

struct FBStatefulReusePoolItemEntry {
  UIView *view;
  CKStatefulViewReusePoolPendingMayRelinquishBlock block;
};

class FBStatefulReusePoolItem {
public:
  UIView *viewWithPreferredSuperview(UIView *preferredSuperview) noexcept
  {
    if (_entries.empty()) {
      return nil;
    }
    // Preferentially return the parent view.
    auto preferIt = CK::find_if(_entries,
                           [preferredSuperview](const FBStatefulReusePoolItemEntry &entry)->bool {
                             return entry.view == preferredSuperview;
                           });
    if (preferIt != _entries.end()) {
      FBStatefulReusePoolItemEntry entry = *preferIt;
      _entries.erase(preferIt);
      if (entry.block == NULL || entry.block()) {
        return entry.view;
      }
    }

    // We didn't find the item preferentially. Time to fall back to going from start to finish.
    auto it = _entries.begin();
    while (it != _entries.end()) {
      FBStatefulReusePoolItemEntry entry = *it;
      // erase returns the next iterator
      it = _entries.erase(it);
      if (entry.block == NULL || entry.block()) {
        // The block tells us it's OK to reuse this view
        return entry.view;
      }
    }

    return nil;
  };

  NSUInteger viewCount() noexcept
  {
    return _entries.size();
  };

  void addEntry(const FBStatefulReusePoolItemEntry &entry) noexcept
  {
    _entries.push_back(entry);
  };

  void absorbPendingPool(const FBStatefulReusePoolItem &otherPool, NSInteger maxEntries) noexcept
  {
    for (const FBStatefulReusePoolItemEntry &entry : otherPool._entries) {
      // In the future, we should consider not evaluating the block here immediately, and letting it move into the
      // normal reuse pool. That way we can let stateful components hold onto their own views without any
      // reconfiguration for a longer period of time.
      if (entry.block == NULL || entry.block()) {
        // The stateful view component can decide not to allow reuse of its view if the component has re-mounted before
        // the block is evaluated.
        if (maxEntries < 0 || viewCount() < maxEntries) {
          _entries.push_back({entry.view});
        }
      }
    }
  }

private:
  std::vector<FBStatefulReusePoolItemEntry> _entries;
};

struct PoolKeyHasher {
  std::size_t operator()(const std::pair<__unsafe_unretained Class, id> &pair) const
  {
    return [pair.first hash] ^ [pair.second hash];
  }
};

@implementation CKStatefulViewReusePool
{
  std::unordered_map<std::pair<__unsafe_unretained Class, id>, FBStatefulReusePoolItem, PoolKeyHasher> _pool;
  std::unordered_map<std::pair<__unsafe_unretained Class, id>, FBStatefulReusePoolItem, PoolKeyHasher> _pendingPool;
  BOOL _enqueuedPendingPurge;
  BOOL _clearingPendingPool;
}

+ (instancetype)sharedPool
{
  static CKStatefulViewReusePool *pool;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    pool = [[CKStatefulViewReusePool alloc] init];
  });
  return pool;
}

- (UIView *)dequeueStatefulViewForControllerClass:(Class)controllerClass
                               preferredSuperview:(UIView *)preferredSuperview
                                          context:(id)context
{
  RCAssertMainThread();
  RCAssertNotNil(controllerClass, @"Must provide a controller class");
  const std::pair<__unsafe_unretained Class, id> key = std::make_pair(controllerClass, context);
  const auto it = _pool.find(key);
  if (it == _pool.end()) { // Avoid overhead of creating the item unless it already exists
    return nil;
  }
  if (![it->first.first isContextValid:it->first.second]) {
    // Context is invalid. This generally should not happen
    // since invalid context == non reacreatable context
    // But we still handle it to make sure that behaviour is
    // well defined

    // Remove views with invalid context from reuse pool
    _pool.erase(it);
    return nil;
  }
  UIView *candidate = it->second.viewWithPreferredSuperview(preferredSuperview);
  if (candidate) {
    return candidate;
  }
  const auto pendingIt = _pendingPool.find(key);
  if (pendingIt == _pendingPool.end()) {
    return nil;
  }
  return pendingIt->second.viewWithPreferredSuperview(preferredSuperview);
}

- (void)enqueueStatefulView:(UIView *)view
         forControllerClass:(Class)controllerClass
                    context:(id)context
         mayRelinquishBlock:(CKStatefulViewReusePoolPendingMayRelinquishBlock)mayRelinquishBlock
{
  RCAssertMainThread();
  RCAssertNotNil(view, @"Must provide a view");
  RCAssertNotNil(controllerClass, @"Must provide a controller class");
  RCAssertNotNil(mayRelinquishBlock, @"Must provide a relinquish block");

  // Shortcut for invalid contexts. If context is invalid
  // by the time when it is being added to the pool, we should
  // drop it immediately
  if (![controllerClass isContextValid:context]) {
    return;
  }

  auto const addEntry = ^{
    auto &poolItem = _pendingPool[std::make_pair(controllerClass, context)];
    poolItem.addEntry({view, mayRelinquishBlock});
  };
  if (!_clearingPendingPool) {
    addEntry();
  } else {
    // Using this function instead of dispatch_async to make sure there are no ordering issues with regard to enqueueing
    // the pending purge below.
    RCDispatchMainDefaultMode(addEntry);
  }

  if (_enqueuedPendingPurge) {
    return;
  }
  _enqueuedPendingPurge = YES;
  // Wait for the run loop to turn over before trying to relinquish the view. That ensures that if we are remounted on
  // a different root view, we reuse the same view (since didMount will be called immediately after didUnmount).
  RCDispatchMainDefaultMode(^{
    self->_enqueuedPendingPurge = NO;
    [self purgePendingPool];
    [self dropViewsWithInvalidContext];
  });
}

- (void)purgePendingPool
{
  RCAssertMainThread();
  for (const auto &it : _pendingPool) {
    // Ignore items that already can't be reused to save some cycles
    BOOL isContextValid = [it.first.first isContextValid:it.first.second];
    if (!isContextValid) {
      continue;
    }

    // maximumPoolSize will be -1 by default
    NSInteger maximumPoolSize = [it.first.first maximumPoolSize:it.first.second];

    FBStatefulReusePoolItem &poolItem = _pool[it.first];
    poolItem.absorbPendingPool(it.second, maximumPoolSize);
  }
  _clearingPendingPool = YES;
  _pendingPool.clear();
  _clearingPendingPool = NO;
}

- (void)dropViewsWithInvalidContext {
  RCAssertMainThread();
  for (auto it = _pool.begin(); it != _pool.end();) {
    if (![it->first.first isContextValid:it->first.second]) {
      it = _pool.erase(it);
    } else {
      ++it;
    }
  }
}

@end
