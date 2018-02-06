/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentLayout.h"

#import <stack>
#import <unordered_map>

#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>

#import "ComponentUtilities.h"
#import "CKAnalyticsListener.h"
#import "CKComponentInternal.h"
#import "CKComponentSubclass.h"
#import "CKDetectComponentScopeCollisions.h"
#import "CKComponentLayoutCache.h"

using namespace CK::Component;

static NSString *const kComponentCacheKey = @"componentCacheKey";

static void _deleteComponentLayoutChild(void *target) noexcept
{
  delete (std::vector<CKComponentLayoutChild> *)target;
}

static void CKBuildScopedComponentLayoutCache(CKComponentLayout &layout);

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

NSSet *CKMountComponentLayout(const CKComponentLayout &layout,
                              UIView *view,
                              NSSet *previouslyMountedComponents,
                              CKComponent *supercomponent,
                              id<CKAnalyticsListener> analyticsListener)
{
  struct MountItem {
    const CKComponentLayout &layout;
    MountContext mountContext;
    CKComponent *supercomponent;
    BOOL visited;
  };

  [analyticsListener willMountComponentTreeWithRootComponent:layout.component];
  // Using a stack to mount ensures that the components are mounted
  // in a DFS fashion which is handy if you want to animate a subpart
  // of the tree
  std::stack<MountItem> stack;
  stack.push({layout, MountContext::RootContext(view, CKComponentLayoutOrAncestorHasScopeConflict(layout)), supercomponent, NO});
  NSMutableSet *mountedComponents = [NSMutableSet set];

  layout.component.rootComponentMountedView = view;

  while (!stack.empty()) {
    MountItem &item = stack.top();
    if (item.visited) {
      [item.layout.component childrenDidMount];
      stack.pop();
    } else {
      item.visited = YES;
      if (item.layout.component == nil) {
        continue; // Nil components in a layout struct are invalid, but handle them gracefully
      }
      const MountResult mountResult = [item.layout.component mountInContext:item.mountContext
                                                                       size:item.layout.size
                                                                   children:item.layout.children
                                                             supercomponent:item.supercomponent];
      [mountedComponents addObject:item.layout.component];

      if (mountResult.mountChildren) {
        // Ordering of components should correspond to ordering of mount. Push components on backwards so the
        // bottom-most component is mounted first.
        for (auto riter = item.layout.children->rbegin(); riter != item.layout.children->rend(); riter ++) {
          BOOL hasScopeConflict = CKComponentLayoutOrAncestorHasScopeConflict(item.layout);
          stack.push({riter->layout, mountResult.contextForChildren.offset(riter->position, item.layout.size, riter->layout.size, hasScopeConflict), item.layout.component, NO});
        }
      }
    }
  }

  if (previouslyMountedComponents) {
    // Unmount any components that were in previouslyMountedComponents but are no longer in mountedComponents.
    NSMutableSet *componentsToUnmount = [previouslyMountedComponents mutableCopy];
    [componentsToUnmount minusSet:mountedComponents];
    CKUnmountComponents(componentsToUnmount);
  }
  [analyticsListener didMountComponentTreeWithRootComponent:layout.component];

  return mountedComponents;
}

CKComponentLayout CKComputeRootComponentLayout(CKComponent *rootComponent,
                                               const CKSizeRange &sizeRange,
                                               id<CKAnalyticsListener> analyticsListener,
                                               BOOL buildComponentLayoutCache)
                                             {
  [analyticsListener willLayoutComponentTreeWithRootComponent:rootComponent];
  CKComponentLayout layout = CKComputeComponentLayout(rootComponent, sizeRange, sizeRange.max);
  CKDetectComponentScopeCollisions(layout);
  if (buildComponentLayoutCache) {
    CKBuildScopedComponentLayoutCache(layout);
  }
  [analyticsListener didLayoutComponentTreeWithRootComponent:rootComponent];
  return layout;
}

CKComponentLayout CKComputeComponentLayout(CKComponent *component,
                                           const CKSizeRange &sizeRange,
                                           const CGSize parentSize)
{
  return component ? [component layoutThatFits:sizeRange parentSize:parentSize] : (CKComponentLayout){};
}

void CKUnmountComponents(NSSet *componentsToUnmount)
{
  for (CKComponent *component in componentsToUnmount) {
    [component unmount];
  }
}

static void CKBuildScopedComponentLayoutCache(CKComponentLayout &layout)
{
  // Build the cache.
  CKComponentLayoutCache *cache = [CKComponentLayoutCache newWithLayout:layout];

  // Store it in the root node.
  NSDictionary *extra = layout.extra;
  if (extra) {
    NSMutableDictionary *extraWithCache = [NSMutableDictionary dictionaryWithDictionary:extra];
    extraWithCache[kComponentCacheKey] = cache;
    layout.extra = extraWithCache;
  } else {
    layout.extra = @{kComponentCacheKey : cache};
  }
}

CKComponentLayout CKComponentLayout::cachedLayoutForScopedComponent(CKComponent *scopedComponent) const
{
  CKComponentLayoutCache *cache = extra[kComponentCacheKey];
  if (cache) {
    return [cache layoutForComponent:scopedComponent];
  }
  return {};
}
