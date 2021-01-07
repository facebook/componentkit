/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <RenderCore/CKDefines.h>

#if CK_NOT_SWIFT

#import <deque>
#import <string>
#import <unordered_map>
#import <unordered_set>
#import <utility>
#import <vector>

#import <UIKit/UIKit.h>

#import <RenderCore/CKComponentViewAttribute.h>
#import <RenderCore/CKComponentViewClass.h>
#import <RenderCore/CKDictionary.h>
#import <RenderCore/CKViewConfiguration.h>

@class CKComponent;

typedef void (^CKOptimisticViewMutationTeardown)(UIView *v);
typedef void (^CKOptimisticViewMutationOperation)(UIView *v);
typedef id CKOptimisticMutationToken;
constexpr id CKOptimisticMutationTokenNull = nil;

namespace CK {
  namespace Component {
    struct MountAnalyticsContext;

    struct OptimisticViewMutationInfo {
      int serial;
      CKOptimisticViewMutationOperation undo;
      CKOptimisticViewMutationOperation apply;
      CKOptimisticViewMutationOperation load;
    };

    struct ViewKey {
      /**
       Class of the CKComponent. Even if two different CKComponent classes have the same viewClassIdentifier, we don't
       recycle views between them.
       */
      Class componentClass;
      /**
       This differentiates components that have the same componentClass but different view types.
       */
      CKComponentViewClassIdentifier viewClassIdentifier;
      /**
       To recycle a view, its attribute identifiers must exactly match. Otherwise if you had an initial tree A:
       <View backgroundColor=blue />
       And an updated tree A':
       <View alpha=0.5 />
       And the view was recycled, the blue background color would persist incorrectly when recycling the view.
       We could someday have the concept of a "resettable attribute" but for now, this is the simplest option.
       */
      PersistentAttributeShape attributeShape;

      bool operator==(const ViewKey &other) const
      {
        return other.componentClass == componentClass
        && other.viewClassIdentifier == viewClassIdentifier
        && other.attributeShape == attributeShape;
      }
    };
  }
}

namespace CK {
  namespace Component {
    class ViewReusePool {
    public:
      ViewReusePool() : position(pool.begin()) {};
      ViewReusePool(ViewReusePool &&) = default;

      /** Unhides all views vended so far; hides others. Resets position to begin(). */
      void reset(MountAnalyticsContext *mountAnalyticsContext) noexcept;

      UIView *viewForClass(const CKComponentViewClass &viewClass, UIView *container, MountAnalyticsContext *mountAnalyticsContext) noexcept;

      /** Hide all views in viewpool of `view` and trigger `didHide` of descendant. */
      static void hideAll(UIView *view, MountAnalyticsContext *mountAnalyticsContext) noexcept;
    private:
      std::vector<UIView *> pool;
      /** Points to the next view in pool that has *not* yet been vended. */
      std::vector<UIView *>::iterator position;

      ViewReusePool(const ViewReusePool&) = delete;
      ViewReusePool &operator=(const ViewReusePool&) = delete;
    };

    class ViewReusePoolMap {
    public:
      static ViewReusePoolMap &viewReusePoolMapForView(UIView *view) noexcept;
      ViewReusePoolMap();

      /** Resets each individual pool inside the map. */
      void reset(UIView *container, MountAnalyticsContext *mountAnalyticsContext) noexcept;

      UIView *viewForConfiguration(Class componentClass,
                                   const CKViewConfiguration &config,
                                   UIView *container,
                                   MountAnalyticsContext *mountAnalyticsContext) noexcept
      {
        if (!config.viewClass().hasView()) {
          return nil;
        }

        const Component::ViewKey key = {
          componentClass,
          config.viewClass().getIdentifier(),
          config.attributeShape(),
        };
        // Note that operator[] creates a new ViewReusePool if one doesn't exist yet. This is what we want.
        auto const v = dictionary[key].viewForClass(config.viewClass(), container, mountAnalyticsContext);
        vendedViews.push_back(v);
        return v;
      }

      friend void ViewReusePool::hideAll(UIView *view, MountAnalyticsContext *mountAnalyticsContext) noexcept;
    private:
      Dictionary<ViewKey, ViewReusePool> dictionary;
      std::vector<UIView *> vendedViews;

      ViewReusePoolMap(const ViewReusePoolMap&) = delete;
      ViewReusePoolMap &operator=(const ViewReusePoolMap&) = delete;
    };

    class AttributeApplicator {
    public:
      static void apply(UIView *view, const CKViewConfiguration &config) noexcept
      {
        applyAttributes(view, config.attributes());
      }

      /** Internal implementation detail of CKPerformOptimisticViewMutation; don't use this directly. */
      static void addOptimisticViewMutationTeardown_Old(UIView *view, CKOptimisticViewMutationTeardown teardown) noexcept;
      /** Internal implementation detail of CKPerformOptimisticViewMutation; don't use this directly. */
      static CKOptimisticMutationToken addOptimisticViewMutation(UIView *view, CKOptimisticViewMutationOperation undo, CKOptimisticViewMutationOperation redo, CKOptimisticViewMutationOperation refresh) noexcept;
      /** Internal implementation detail of CKPerformOptimisticViewMutation; don't use this directly. */
      static void removeOptimisticViewMutation(CKOptimisticMutationToken token) noexcept;
      /** Internal implementation detail of CKPerformOptimisticViewMutation; don't use this directly. */
      static void resetOptimisticViewMutations(UIView *view) noexcept;

    private:
      static void applyAttributes(UIView *view, std::shared_ptr<const CKViewComponentAttributeValueMap> attributes) noexcept;
    };

    /**
     An interface to the ViewReusePoolMap for a given container view. The constructor looks up the ViewReusePoolMap for
     the given view; you can subsequently call viewForConfiguration() to fetch-or-create a view from the pool.

     This object's destructor unhides any views that were vended and hides any remaining views that were not vended,
     leaving them in place for the next recycling pass.

     This class leaves any subviews that were not created by the component infra untouched.
     */
    class ViewManager {
    public:
      ViewManager(UIView *v, MountAnalyticsContext *ma = nullptr) : view(v), viewReusePoolMap(ViewReusePoolMap::viewReusePoolMapForView(v)), mountAnalyticsContext(ma) {};
      ~ViewManager() { viewReusePoolMap.reset(view, mountAnalyticsContext); }

      /** The view being managed. */
      UIView *const view;

      /** Returns a recycled or newly created subview for the given configuration. */
      UIView *viewForConfiguration(Class componentClass,
                                   const CKViewConfiguration &config) noexcept
      {
        return viewReusePoolMap.viewForConfiguration(componentClass, config, view, mountAnalyticsContext);
      }

    private:
      ViewReusePoolMap &viewReusePoolMap;
      MountAnalyticsContext *mountAnalyticsContext;

      ViewManager(const ViewManager&) = delete;
      ViewManager &operator=(const ViewManager&) = delete;
    };
  }
}

#endif
