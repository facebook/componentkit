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
#import <ComponentKit/CKEqualityHelpers.h>
#import <ComponentKit/CKMountable.h>
#import <ComponentKit/CKNonNull.h>
#import <ComponentKit/CKOptional.h>
#import <ComponentKit/CKSizeRange.h>

@protocol CKAnalyticsListener;
@protocol CKMountable;

struct CKComponentLayoutChild;

/** Deletes the target off the main thread; important since component layouts are large recursive structures. */
struct CKOffMainThreadDeleter {
  void operator()(std::vector<CKComponentLayoutChild> *target) noexcept;
};

/** Represents the computed size of a component, as well as the computed sizes and positions of its children. */
struct CKComponentLayout { // This is pending renaming
  id<CKMountable> component;
  CGSize size;
  std::shared_ptr<const std::vector<CKComponentLayoutChild>> children;
  NSDictionary *extra;

  CKComponentLayout(id<CKMountable> c, CGSize s) noexcept;
  CKComponentLayout(id<CKMountable> c, CGSize s, std::vector<CKComponentLayoutChild> ch, NSDictionary *e = nil) noexcept;

  CKComponentLayout() noexcept;

  void enumerateLayouts(const std::function<void(const CKComponentLayout &)> &f) const;

private:
  static std::shared_ptr<const std::vector<CKComponentLayoutChild>> emptyChildren() noexcept;
};

struct CKComponentLayoutChild {
  CGPoint position;
  CKComponentLayout layout;
};

struct CKComponentRootLayout { // This is pending renaming
  /** Layout cache for components that have controller. */
  using ComponentLayoutCache = std::unordered_map<id<CKMountable>, CKComponentLayout, CK::hash<id<CKMountable>>, CK::is_equal<id<CKMountable>>>;
  using ComponentsByPredicateMap = std::unordered_map<CKMountablePredicate, std::vector<id<CKMountable>>>;

  CKComponentRootLayout() {}
  explicit CKComponentRootLayout(CKComponentLayout layout)
  : CKComponentRootLayout(layout, {}, {}) {}
  explicit CKComponentRootLayout(CKComponentLayout layout, ComponentLayoutCache layoutCache, ComponentsByPredicateMap componentsByPredicate)
  : _layout(std::move(layout)), _layoutCache(std::move(layoutCache)), _componentsByPredicate(std::move(componentsByPredicate)) {}

  /**
   This method returns a CKComponentLayout from the cache for the component if it has a controller.
   @param component The component to look for the layout with.
   */
  auto cachedLayoutForComponent(id<CKMountable> component) const
  {
    const auto it = _layoutCache.find(component);
    return it != _layoutCache.end() ? it->second : CKComponentLayout {};
  }

  auto componentsMatchingPredicate(const CKMountablePredicate p) const
  {
    const auto it = _componentsByPredicate.find(p);
    return it != _componentsByPredicate.end() ? it->second : std::vector<id<CKMountable>> {};
  }

  void enumerateCachedLayout(void(^block)(const CKComponentLayout &layout)) const;

  const auto &layout() const { return _layout; }
  auto component() const { return _layout.component; }
  auto size() const { return _layout.size; }

private:
  CKComponentLayout _layout;
  ComponentLayoutCache _layoutCache;
  ComponentsByPredicateMap _componentsByPredicate;
};

struct CKMountLayoutResult {
  CK::NonNull<NSSet *> mountedComponents;
  NSSet *unmountedComponents;
  CK::Optional<CK::Component::MountAnalyticsContext> mountAnalyticsContext;
};

@protocol CKMountLayoutListener <NSObject>

/**
 Called before/after mounting a component.
 */
- (void)willMountComponent:(id<CKMountable>)component;
- (void)didMountComponent:(id<CKMountable>)component;

@end

/**
 Recursively mounts the layout in the view, returning a set of the mounted components.
 @param layout The layout to mount, usually returned from a call to -layoutThatFits:parentSize:
 @param view The view in which to mount the layout.
 @param previouslyMountedComponents If a previous layout was mounted, pass the return value of the previous call to
        CKMountLayout; any components that are not present in the new layout will be unmounted.
 @param supercomponent Usually pass nil; if you are mounting a subtree of a layout, pass the parent component so the
        component responder chain can be connected correctly.

 @param isUpdate Indicates whether the mount is due to an (state/props) update.
 @param shouldCollectMountInfo should mount information be collected and returned in `CKMountLayoutResult`.
 @param willMountLayout Called before mounting each layout in the layout tree.
 @param didMountLayout Called after mounting each layout in the layout tree.
 */
CKMountLayoutResult CKMountLayout(const CKComponentLayout &layout,
                                  UIView *view,
                                  NSSet *previouslyMountedComponents,
                                  id<CKMountable> supercomponent,
                                  BOOL isUpdate = NO,
                                  BOOL shouldCollectMountInfo = NO,
                                  id<CKMountLayoutListener> listener = nil);

/**
 Safely computes the layout of the given root component by guarding against nil components.
 @param rootComponent The root component to compute the layout for.
 @param sizeRange The size range to compute the component layout within.
 @param predicates Predicates that is used for building a lookup map in `CKComponentRootLayout`.
 */
CKComponentRootLayout CKComputeRootLayout(id<CKMountable> rootComponent,
                                          const CKSizeRange &sizeRange,
                                          const std::unordered_set<CKMountablePredicate> &predicates = {});

/**
 Safely computes the layout of the given component by guarding against nil components.
 @param component The component to compute the layout for.
 @param sizeRange The size range to compute the component layout within.
 @param parentSize The parent size of the component to compute the layout for.
 */
CKComponentLayout CKComputeComponentLayout(id<CKMountable> component,
                                           const CKSizeRange &sizeRange,
                                           const CGSize parentSize);

/** Unmounts all components returned by a previous call to CKMountComponentLayout. */
void CKUnmountComponents(NSSet<id<CKMountable>> *componentsToUnmount);
