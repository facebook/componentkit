/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <unordered_map>
#import <unordered_set>
#import <utility>
#import <vector>

#import <UIKit/UIKit.h>

#import <ComponentKit/CKAssert.h>
#import <ComponentKit/CKBuildComponent.h>
#import <ComponentKit/CKComponentAnimationPredicates.h>
#import <ComponentKit/CKComponentScopeTypes.h>
#import <ComponentKit/CKEqualityHashHelpers.h>
#import <ComponentKit/CKOptional.h>
#import <ComponentKit/CKSizeRange.h>

@class CKComponent;
@class CKComponentController;
@class CKComponentScopeRoot;

@protocol CKAnalyticsListener;

struct CKComponentLayoutChild;

/** Deletes the target off the main thread; important since component layouts are large recursive structures. */
struct CKOffMainThreadDeleter {
  void operator()(std::vector<CKComponentLayoutChild> *target) noexcept;
};

/** Represents the computed size of a component, as well as the computed sizes and positions of its children. */
struct CKComponentLayout {
  CKComponent *component;
  CGSize size;
  std::shared_ptr<const std::vector<CKComponentLayoutChild>> children;
  NSDictionary *extra;

  CKComponentLayout(CKComponent *c, CGSize s) noexcept
  : component(c), size(s), children(emptyChildren()), extra(nil) {
    CKCAssertNotNil(c, @"Nil components are not allowed");
  };

  CKComponentLayout(CKComponent *c, CGSize s, std::vector<CKComponentLayoutChild> ch, NSDictionary *e = nil) noexcept
  : component(c), size(s), children(new std::vector<CKComponentLayoutChild>(std::move(ch)), CKOffMainThreadDeleter()), extra(e) {
    CKCAssertNotNil(c, @"Nil components are not allowed");
  };

  CKComponentLayout() noexcept
  : component(nil), size({0, 0}), children(emptyChildren()), extra(nil) {};

  void enumerateLayouts(const std::function<void(const CKComponentLayout &)> &f) const;

private:
  static std::shared_ptr<const std::vector<CKComponentLayoutChild>> emptyChildren() noexcept;
};

struct CKComponentLayoutChild {
  CGPoint position;
  CKComponentLayout layout;
};

struct CKComponentRootLayout {
  /** Layout cache for components that have controller. */
  using ComponentLayoutCache = std::unordered_map<CKComponent *, CKComponentLayout, CK::hash<CKComponent *>, CK::is_equal<CKComponent *>>;
  using ComponentsByPredicateMap = std::unordered_map<CKComponentPredicate, std::vector<CKComponent *>>;

  CKComponentRootLayout() {}
  explicit CKComponentRootLayout(CKComponentLayout layout)
  : CKComponentRootLayout(layout, {}, {}) {}
  explicit CKComponentRootLayout(CKComponentLayout layout, ComponentLayoutCache layoutCache, ComponentsByPredicateMap componentsByPredicate)
  : _layout(std::move(layout)), _layoutCache(std::move(layoutCache)), _componentsByPredicate(std::move(componentsByPredicate)) {}

  /**
   This method returns a CKComponentLayout from the cache for the component if it has a controller.
   @param component The component to look for the layout with.
   */
  auto cachedLayoutForScopedComponent(CKComponent *const scopedComponent) const
  {
    const auto it = _layoutCache.find(scopedComponent);
    return it != _layoutCache.end() ? it->second : CKComponentLayout {};
  }

  auto componentsMatchingPredicate(const CKComponentPredicate p) const
  {
    const auto it = _componentsByPredicate.find(p);
    return it != _componentsByPredicate.end() ? it->second : std::vector<CKComponent *> {};
  }

  void enumerateComponentControllers(void(^block)(CKComponentController *, CKComponent *)) const;

  const auto &layout() const { return _layout; }
  auto component() const { return _layout.component; }
  auto size() const { return _layout.size; }

private:
  CKComponentLayout _layout;
  ComponentLayoutCache _layoutCache;
  ComponentsByPredicateMap _componentsByPredicate;
};

struct CKMountComponentLayoutResult {
  NSSet *mountedComponents;
  NSSet *unmountedComponents;
};

/**
 Recursively mounts the layout in the view, returning a set of the mounted components.
 @param layout The layout to mount, usually returned from a call to -layoutThatFits:parentSize:
 @param view The view in which to mount the layout.
 @param previouslyMountedComponents If a previous layout was mounted, pass the return value of the previous call to
        CKMountComponentLayout; any components that are not present in the new layout will be unmounted.
 @param supercomponent Usually pass nil; if you are mounting a subtree of a layout, pass the parent component so the
        component responder chain can be connected correctly.
 @param analyticsListener analytics listener used to log mount time.
 @param isUpdate Indicates whether the mount is due to an (state/props) update.
 */
CKMountComponentLayoutResult CKMountComponentLayout(const CKComponentLayout &layout,
                                                    UIView *view,
                                                    NSSet *previouslyMountedComponents,
                                                    CKComponent *supercomponent,
                                                    id<CKAnalyticsListener> analyticsListener = nil,
                                                    BOOL isUpdate = NO);

/**
 Safely computes the layout of the given root component by guarding against nil components.
 @param rootComponent The root component to compute the layout for.
 @param sizeRange The size range to compute the component layout within.
 @param analyticsListener analytics listener used to log layout time.
 */
CKComponentRootLayout CKComputeRootComponentLayout(CKComponent *rootComponent,
                                                   const CKSizeRange &sizeRange,
                                                   id<CKAnalyticsListener> analyticsListener = nil,
                                                   CK::Optional<BuildTrigger> buildTrigger = CK::none,
                                                   std::unordered_set<CKComponentPredicate> predicates = CKComponentAnimationPredicates());

/**
 Safely computes the layout of the given component by guarding against nil components.
 @param component The component to compute the layout for.
 @param sizeRange The size range to compute the component layout within.
 @param parentSize The parent size of the component to compute the layout for.
 */
CKComponentLayout CKComputeComponentLayout(CKComponent *component,
                                           const CKSizeRange &sizeRange,
                                           const CGSize parentSize);

/** Unmounts all components returned by a previous call to CKMountComponentLayout. */
void CKUnmountComponents(NSSet *componentsToUnmount);
