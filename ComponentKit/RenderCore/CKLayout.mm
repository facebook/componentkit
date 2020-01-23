/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKLayout.h"

#import <stack>
#import <unordered_map>

/** Deletes the target off the main thread; important since component layouts are large recursive structures. */
struct CKOffMainThreadDeleter {
  void operator()(std::vector<CKComponentLayoutChild> *target) noexcept;
};

using namespace CK::Component;

CKComponentLayout::CKComponentLayout(id<CKMountable> c, CGSize s) noexcept
: component(c), size(s), children(emptyChildren()), extra(nil) {
  CKCAssertNotNil(c, @"Nil components are not allowed");
};

CKComponentLayout::CKComponentLayout(id<CKMountable> c, CGSize s, const std::vector<CKComponentLayoutChild> &ch, NSDictionary *e) noexcept
: component(c), size(s), children(new std::vector<CKComponentLayoutChild>(ch), CKOffMainThreadDeleter()), extra(e) {
  CKCAssertNotNil(c, @"Nil components are not allowed");
};

CKComponentLayout::CKComponentLayout(id<CKMountable> c, CGSize s, std::vector<CKComponentLayoutChild> &&ch, NSDictionary *e) noexcept
: component(c), size(s), children(new std::vector<CKComponentLayoutChild>(std::move(ch)), CKOffMainThreadDeleter()), extra(e) {
  CKCAssertNotNil(c, @"Nil components are not allowed");
};

CKComponentLayout::CKComponentLayout() noexcept
: component(nil), size({0, 0}), children(emptyChildren()), extra(nil) {};

static void _deleteComponentLayoutChild(void *target) noexcept
{
  delete (std::vector<CKComponentLayoutChild> *)target;
}

void CKOffMainThreadDeleter::operator()(std::vector<CKComponentLayoutChild> *target) noexcept
{
  // When deallocating a large layout tree this is called first on the root node
  // so we dispatch once and deallocate the whole tree on a background thread.
  // However, if you have a CKComponentLayout as an ivar/variable, it will be initialized
  // with the default contstructor and an empty vector. When you set the ivar, this method is called
  // to deallocate the empty layout, and in this case it's not worth doing the dispatch.
  if ([NSThread isMainThread] && target && !target->empty()) {
    // use dispatch_async_f to avoid block allocations
    dispatch_async_f(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), target, &_deleteComponentLayoutChild);
  } else {
    delete target;
  }
}

std::shared_ptr<const std::vector<CKComponentLayoutChild>> CKComponentLayout::emptyChildren() noexcept
{
  static std::shared_ptr<const std::vector<CKComponentLayoutChild>> cached(new std::vector<CKComponentLayoutChild>());
  return cached;
}

CKMountLayoutResult CKMountLayout(const CKComponentLayout &layout,
                                  UIView *view,
                                  NSSet *previouslyMountedComponents,
                                  id<CKMountable> supercomponent,
                                  BOOL isUpdate,
                                  BOOL shouldCollectMountInfo,
                                  id<CKMountLayoutListener> listener)
{
  struct MountItem {
    const CKComponentLayout &layout;
    MountContext mountContext;
    id<CKMountable> supercomponent;
    BOOL visited;
  };

  // Using a stack to mount ensures that the components are mounted
  // in a DFS fashion which is handy if you want to animate a subpart
  // of the tree
  std::stack<MountItem> stack;
  MountAnalyticsContext mountAnalyticsContext;
  auto const mountAnalyticsContextPointer = shouldCollectMountInfo ? &mountAnalyticsContext : nullptr;
  stack.push({layout, MountContext::RootContext(view, mountAnalyticsContextPointer, isUpdate), supercomponent, NO});
  auto const mountedComponents = CK::makeNonNull([NSMutableSet set]);

  while (!stack.empty()) {
    MountItem &item = stack.top();
    if (item.visited) {
      [item.layout.component childrenDidMount];
      [listener didMountComponent:item.layout.component];
      stack.pop();
    } else {
      item.visited = YES;
      if (item.layout.component == nil) {
        continue; // Nil components in a layout struct are invalid, but handle them gracefully
      }
      [listener willMountComponent:item.layout.component];
      const MountResult mountResult = [item.layout.component mountInContext:item.mountContext
                                                                       size:item.layout.size
                                                                   children:item.layout.children
                                                             supercomponent:item.supercomponent];
      [mountedComponents addObject:item.layout.component];

      if (mountResult.mountChildren) {
        // Ordering of components should correspond to ordering of mount. Push components on backwards so the
        // bottom-most component is mounted first.
        for (auto riter = item.layout.children->rbegin(); riter != item.layout.children->rend(); riter ++) {
          stack.push({riter->layout, mountResult.contextForChildren.offset(riter->position, item.layout.size, riter->layout.size), item.layout.component, NO});
        }
      }
    }
  }

  NSMutableSet *componentsToUnmount;
  if (previouslyMountedComponents) {
    // Unmount any components that were in previouslyMountedComponents but are no longer in mountedComponents.
    componentsToUnmount = [previouslyMountedComponents mutableCopy];
    [componentsToUnmount minusSet:mountedComponents];
    CKUnmountComponents(componentsToUnmount);
  }
  return {
    mountedComponents,
    componentsToUnmount,
    shouldCollectMountInfo ? CK::Optional<MountAnalyticsContext> {mountAnalyticsContext} : CK::none,
  };
}

void CKUnmountComponents(NSSet<id<CKMountable>> *componentsToUnmount)
{
  for (id<CKMountable> component in componentsToUnmount) {
    [component unmount];
  }
}
