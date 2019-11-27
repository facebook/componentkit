/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "ComponentRootViewPool.h"

#import <ComponentKit/CKAssert.h>
#import <ComponentKit/ComponentViewManager.h>

#import "CKComponentRootViewInternal.h"

using namespace CK::Component;

auto ViewStorage::clear() -> void
{
  if (_locked) {
    return;
  }
  // Upon clearing view pool, views are deallocated and it's possible that views will be added to view pool
  // at this point and it will crash because we can't mutate view pool while enumerating the underlying vector.
  // In order to prevent this from happening, we need to mark view pool as locked and ignore all mutations until it's unlocked.
  _locked = true;
  _rootViews.clear();
  _locked = false;
}

auto ViewStorage::push(CKComponentRootView *rootView, NonNull<NSString *> category) -> void
{
  if (_locked) {
    return;
  }
  // Before pushing `rootView` to the view pool, we need to hide all subviews of `rootView`.
  // This also makes sure lifecycle method `didEnterReusePool` is properly called.
  ViewReusePool::hideAll(rootView, nullptr);
  [rootView willEnterViewPool];
  _rootViews[category].push_back(rootView);
}

auto ViewStorage::pop(NonNull<NSString *> category) -> CKComponentRootView *
{
  if (_locked) {
    return nil;
  }
  const auto it = _rootViews.find(category);
  if (it == _rootViews.end() || it->second.empty()) {
    return nil;
  } else {
    const auto rootView = it->second.back();
    it->second.pop_back();
    return rootView;
  }
}

auto RootViewPool::clear() -> void
{
  CKCAssertMainThread();
  _viewStorage->clear();
}

auto RootViewPool::popRootViewWithCategory(CK::NonNull<NSString *> category) -> CKComponentRootView *
{
  CKCAssertMainThread();
  return _viewStorage->pop(category);
}

auto RootViewPool::pushRootViewWithCategory(CK::NonNull<CKComponentRootView *> rootView,
                                            CK::NonNull<NSString *> category) -> void
{
  CKCAssertMainThread();
  _viewStorage->push(rootView, category);
}

auto CK::Component::GlobalRootViewPool() -> RootViewPool &
{
  static RootViewPool *globalRootViewPool = nullptr;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    globalRootViewPool = new RootViewPool();
    [[NSNotificationCenter defaultCenter]
     addObserverForName:UIApplicationDidReceiveMemoryWarningNotification
     object:nil
     queue:[NSOperationQueue mainQueue]
     usingBlock:^(NSNotification * _Nonnull note) {
       globalRootViewPool->clear();
     }];
  });
  return *globalRootViewPool;
}
