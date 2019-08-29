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

#import "CKAssert.h"
#import "CKComponentRootViewInternal.h"
#import "ComponentViewManager.h"

using namespace CK::Component;

auto RootViewPool::clear() -> void
{
  CKCAssertMainThread();
  _rootViews->clear();
}

auto RootViewPool::popRootViewWithCategory(CK::NonNull<NSString *> category) -> CKComponentRootView *
{
  CKCAssertMainThread();

  const auto it = _rootViews->find(category);
  if (it == _rootViews->end() || it->second.empty()) {
    return nil;
  } else {
    const auto rootView = it->second.back();
    it->second.pop_back();
    return rootView;
  }
}

auto RootViewPool::pushRootViewWithCategory(CK::NonNull<CKComponentRootView *> rootView,
                                            CK::NonNull<NSString *> category) -> void
{
  CKCAssertMainThread();

  // Before pushing `rootView` to the view pool, we need to hide all subviews of `rootView`.
  // This also makes sure lifecycle method `didEnterReusePool` is properly called.
  ViewReusePool::hideAll(rootView, nullptr);
  [rootView willEnterViewPool];
  (*_rootViews)[category].push_back(rootView);
}

auto CK::Component::GlobalRootViewPool() -> RootViewPool &
{
  static RootViewPool *globalRootViewPool = nullptr;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    globalRootViewPool = new RootViewPool();
  });
  return *globalRootViewPool;
}
