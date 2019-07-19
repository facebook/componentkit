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

#import "ComponentLayoutContext.h"
#import "ComponentUtilities.h"
#import "CKAnalyticsListener.h"
#import "CKComponentEvents.h"
#import "CKComponentInternal.h"
#import "CKComponentSubclass.h"
#import "CKDetectDuplicateComponent.h"

using namespace CK::Component;

static void _deleteComponentLayoutChild(void *target) noexcept
{
  delete (std::vector<CKComponentLayoutChild> *)target;
}

static auto buildComponentsByPredicateMap(const CKComponentLayout &layout, const std::unordered_set<CKComponentPredicate> &predicates)
{
  auto componentsByPredicate = CKComponentRootLayout::ComponentsByPredicateMap {};
  if (predicates.empty()) { return componentsByPredicate; }

  layout.enumerateLayouts([&](const auto &l){
    if (l.component == nil) { return; }
    for (const auto &p : predicates) {
      if (p(l.component)) {
        componentsByPredicate[p].push_back(l.component);
      }
    }
  });
  return componentsByPredicate;
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

CKMountComponentLayoutResult CKMountComponentLayout(const CKComponentLayout &layout,
                                                    UIView *view,
                                                    NSSet *previouslyMountedComponents,
                                                    CKComponent *supercomponent,
                                                    id<CKAnalyticsListener> analyticsListener,
                                                    BOOL isUpdate)
{
  struct MountItem {
    const CKComponentLayout &layout;
    MountContext mountContext;
    CKComponent *supercomponent;
    BOOL visited;
  };

  [analyticsListener willMountComponentTreeWithRootComponent:layout.component];
  auto const systraceListener = [analyticsListener systraceListener];
  // Using a stack to mount ensures that the components are mounted
  // in a DFS fashion which is handy if you want to animate a subpart
  // of the tree
  std::stack<MountItem> stack;
  CK::Component::MountAnalyticsContext mountAnalyticsContext;
  auto const mountAnalyticsContextPointer = [analyticsListener shouldCollectMountInformationForRootComponent:layout.component] ? &mountAnalyticsContext : nullptr;
  stack.push({layout, MountContext::RootContext(view, mountAnalyticsContextPointer, isUpdate), supercomponent, NO});
  NSMutableSet *mountedComponents = [NSMutableSet set];

  layout.component.rootComponentMountedView = view;

  while (!stack.empty()) {
    MountItem &item = stack.top();
    if (item.visited) {
      [item.layout.component childrenDidMount:systraceListener];
      stack.pop();
    } else {
      item.visited = YES;
      if (item.layout.component == nil) {
        continue; // Nil components in a layout struct are invalid, but handle them gracefully
      }
      const MountResult mountResult = [item.layout.component mountInContext:item.mountContext
                                                                       size:item.layout.size
                                                                   children:item.layout.children
                                                             supercomponent:item.supercomponent
                                                           systraceListener:systraceListener];
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
  [analyticsListener didMountComponentTreeWithRootComponent:layout.component
                                      mountAnalyticsContext:mountAnalyticsContextPointer];
  return {mountedComponents, componentsToUnmount};
}

CKComponentRootLayout CKComputeRootComponentLayout(CKComponent *rootComponent,
                                                   const CKSizeRange &sizeRange,
                                                   id<CKAnalyticsListener> analyticsListener,
                                                   CK::Optional<BuildTrigger> buildTrigger,
                                                   std::unordered_set<CKComponentPredicate> predicates)
{
  [analyticsListener willLayoutComponentTreeWithRootComponent:rootComponent buildTrigger:buildTrigger];
  LayoutSystraceContext systraceContext([analyticsListener systraceListener]);
  CKComponentLayout layout = CKComputeComponentLayout(rootComponent, sizeRange, sizeRange.max);
  CKDetectDuplicateComponent(layout);
  auto layoutCache = CKComponentRootLayout::ComponentLayoutCache {};
  layout.enumerateLayouts([&](const auto &l){
    if (l.component.controller) {
      layoutCache[l.component] = l;
    }
  });
  const auto componentsByPredicate = buildComponentsByPredicateMap(layout, predicates);
  [analyticsListener didLayoutComponentTreeWithRootComponent:rootComponent];
  return CKComponentRootLayout {
    layout,
    layoutCache,
    componentsByPredicate,
  };
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

void CKComponentLayout::enumerateLayouts(const std::function<void(const CKComponentLayout &)> &f) const
{
  f(*this);

  if (children == nil) { return; }
  for (const auto &child : *children) {
    child.layout.enumerateLayouts(f);
  }
}

void CKComponentRootLayout::enumerateComponentControllers(void(^block)(CKComponentController *, CKComponent *)) const
{
  for (const auto &it : _layoutCache) {
    const auto &component = it.first;
    block(component.controller, component);
  }
}
