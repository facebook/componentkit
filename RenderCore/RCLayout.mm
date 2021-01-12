/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "RCLayout.h"

#import <stack>
#import <sstream>
#import <unordered_map>

/** Deletes the target off the main thread; important since component layouts are large recursive structures. */
struct CKOffMainThreadDeleter {
  void operator()(std::vector<RCLayoutChild> *target) noexcept;
};

using namespace CK::Component;

RCLayout::RCLayout(id<CKMountable> c, CGSize s) noexcept
: component(c), size(s), children(emptyChildren()), extra(nil) {
  CKCAssertNotNil(c, @"Nil components are not allowed");
};

RCLayout::RCLayout(id<CKMountable> c, CGSize s, const std::vector<RCLayoutChild> &ch, NSDictionary *e) noexcept
: component(c), size(s), children(new std::vector<RCLayoutChild>(ch), CKOffMainThreadDeleter()), extra(e) {
  CKCAssertNotNil(c, @"Nil components are not allowed");
};

RCLayout::RCLayout(id<CKMountable> c, CGSize s, std::vector<RCLayoutChild> &&ch, NSDictionary *e) noexcept
: component(c), size(s), children(new std::vector<RCLayoutChild>(std::move(ch)), CKOffMainThreadDeleter()), extra(e) {
  CKCAssertNotNil(c, @"Nil components are not allowed");
};

RCLayout::RCLayout() noexcept
: component(nil), size({0, 0}), children(emptyChildren()), extra(nil) {};

std::string RCLayout::description(int indent) const
{
  std::stringstream s;
  s << std::string(indent, ' ') << "{" << std::endl;
  s << std::string(indent + 2, ' ') << "size: {" << size.width << ", " << size.height << "}," << std::endl;
  if (!children->empty()) {
    s << std::string(indent + 2, ' ') << "[" << std::endl;
    for (const auto &child : *children) {
      s << std::string(indent + 4, ' ') << "{" << std::endl;
      s << std::string(indent + 6, ' ') << "position: {" << child.position.x << ", " << child.position.y << "}," << std::endl;
      s << child.layout.description(indent + 6);
      s << std::string(indent + 4, ' ') << "}," << std::endl;
    }
    s << std::string(indent + 2, ' ') << "]" << std::endl;
  }
  s << std::string(indent, ' ') << "}" << std::endl;
  return s.str();
}

static void _deleteComponentLayoutChild(void *target) noexcept
{
  delete (std::vector<RCLayoutChild> *)target;
}

void CKOffMainThreadDeleter::operator()(std::vector<RCLayoutChild> *target) noexcept
{
  // When deallocating a large layout tree this is called first on the root node
  // so we dispatch once and deallocate the whole tree on a background thread.
  // However, if you have a RCLayout as an ivar/variable, it will be initialized
  // with the default contstructor and an empty vector. When you set the ivar, this method is called
  // to deallocate the empty layout, and in this case it's not worth doing the dispatch.
  if ([NSThread isMainThread] && target && !target->empty()) {
    // use dispatch_async_f to avoid block allocations
    dispatch_async_f(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), target, &_deleteComponentLayoutChild);
  } else {
    delete target;
  }
}

std::shared_ptr<const std::vector<RCLayoutChild>> RCLayout::emptyChildren() noexcept
{
  static std::shared_ptr<const std::vector<RCLayoutChild>> cached(new std::vector<RCLayoutChild>());
  return cached;
}

NSSet<id<CKMountable>> *CKMountLayout(const RCLayout &layout,
                                      UIView *view,
                                      NSSet<id<CKMountable>> *previouslyMountedComponents,
                                      id<CKMountable> supercomponent,
                                      CK::Component::MountAnalyticsContext *mountAnalyticsContext,
                                      id<CKMountLayoutListener> listener)
{
  struct MountItem {
    const RCLayout &layout;
    MountContext mountContext;
    id<CKMountable> supercomponent;
    BOOL visited;
  };

  // Using a stack to mount ensures that the components are mounted
  // in a DFS fashion which is handy if you want to animate a subpart
  // of the tree
  std::stack<MountItem> stack;
  stack.push({layout, MountContext::RootContext(view, mountAnalyticsContext), supercomponent, NO});
  auto const mountedComponents = CK::makeNonNull([NSMutableSet set]);

  while (!stack.empty()) {
    MountItem &item = stack.top();
    if (item.visited) {
      if (auto const c = item.layout.component) {
        [c childrenDidMount];
        [listener didMountComponent:c];
      }
      stack.pop();
    } else {
      item.visited = YES;
      if (item.layout.component == nil) {
        continue; // Nil components in a layout struct are invalid, but handle them gracefully
      }
      [listener willMountComponent:item.layout.component];
      const MountResult mountResult = [item.layout.component mountInContext:item.mountContext
                                                                     layout:item.layout
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

  // Unmount any components that were in previouslyMountedComponents but are no longer in mountedComponents.
  for (id<CKMountable> component in previouslyMountedComponents) {
    if (![mountedComponents containsObject:component]) {
      [component unmount];
    }
  }
  return mountedComponents;
}

void CKUnmountComponents(NSSet<id<CKMountable>> *componentsToUnmount)
{
  for (id<CKMountable> component in componentsToUnmount) {
    [component unmount];
  }
}
