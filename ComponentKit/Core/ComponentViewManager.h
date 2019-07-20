/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <deque>
#import <string>
#import <unordered_map>
#import <unordered_set>
#import <utility>
#import <vector>

#import <UIKit/UIKit.h>

#import <ComponentKit/CKComponentViewAttribute.h>
#import <ComponentKit/CKComponentViewClass.h>

@class CKComponent;
struct CKComponentViewConfiguration;

typedef void (^CKOptimisticViewMutationTeardown)(UIView *v);

namespace CK {
  namespace Component {
    struct MountAnalyticsContext;
    /**
     Describes a set of attribute *identifiers* for attributes that can't be un-applied (unapplicator is nil).
     Any two components that have a different PersistentAttributeShape cannot recycle the same view.
     */
    class PersistentAttributeShape {
    public:
      PersistentAttributeShape(const CKViewComponentAttributeValueMap &attributes)
      : _identifier(computeIdentifier(attributes)) {};

      bool operator==(const PersistentAttributeShape &other) const {
        return _identifier == other._identifier;
      }

    private:
      friend struct ::std::hash<PersistentAttributeShape>;
      /**
       This is a int32_t since they are compared on the main thread where we want optimal performance.
       Behind the scenes, these are looked up/created using a map of unordered_set<string> -> int32_t.
       */
      int32_t _identifier;
      static int32_t computeIdentifier(const CKViewComponentAttributeValueMap &attributes);
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
    
    struct ViewKeyWithStringIdentifier {
      /**
       Class of the CKComponent. Even if two different CKComponent classes have the same viewClassIdentifier, we don't
       recycle views between them.
       */
      Class componentClass;
      /**
       This differentiates components that have the same componentClass but different view types.
       */
      std::string viewClassIdentifier;
      /**
       To recycle a view, its attribute identifiers must exactly match. Otherwise if you had an initial tree A:
       <View backgroundColor=blue />
       And an updated tree A':
       <View alpha=0.5 />
       And the view was recycled, the blue background color would persist incorrectly when recycling the view.
       We could someday have the concept of a "resettable attribute" but for now, this is the simplest option.
       */
      PersistentAttributeShape attributeShape;
      
      bool operator==(const ViewKeyWithStringIdentifier &other) const
      {
        return other.componentClass == componentClass
        && other.viewClassIdentifier == viewClassIdentifier
        && other.attributeShape == attributeShape;
      }
    };
  }
}

/** Specialize std::hash. */
namespace std {
  template<> struct hash<CK::Component::PersistentAttributeShape>
  {
    size_t operator()(const CK::Component::PersistentAttributeShape &s) const
    {
      return std::hash<int32_t>()(s._identifier);
    }
  };

  template <> struct hash<CK::Component::ViewKey>
  {
    size_t operator()(const CK::Component::ViewKey &k) const
    {
      return [k.componentClass hash]
              ^ hash<CKComponentViewClassIdentifier>()(k.viewClassIdentifier)
              ^ std::hash<CK::Component::PersistentAttributeShape>()(k.attributeShape);
    }
  };
  
  template <> struct hash<CK::Component::ViewKeyWithStringIdentifier>
  {
    size_t operator()(const CK::Component::ViewKeyWithStringIdentifier &k) const
    {
      return [k.componentClass hash]
      ^ hash<std::string>()(k.viewClassIdentifier)
      ^ std::hash<CK::Component::PersistentAttributeShape>()(k.attributeShape);
    }
  };
}

struct CKComponentViewClass;

namespace CK {
  namespace Component {
    class ViewReusePool {
    public:
      ViewReusePool() : position(pool.begin()) {};

      /** Unhides all views vended so far; hides others. Resets position to begin(). */
      void reset(MountAnalyticsContext *mountAnalyticsContext);

      UIView *viewForClass(const CKComponentViewClass &viewClass, UIView *container, MountAnalyticsContext *mountAnalyticsContext);
    private:
      std::vector<UIView *> pool;
      /** Points to the next view in pool that has *not* yet been vended. */
      std::vector<UIView *>::iterator position;

      ViewReusePool(const ViewReusePool&) = delete;
      ViewReusePool &operator=(const ViewReusePool&) = delete;
    };

    class ViewReusePoolMap {
    public:
      static ViewReusePoolMap &viewReusePoolMapForView(UIView *view);
      ViewReusePoolMap();

      /** Resets each individual pool inside the map. */
      void reset(UIView *container, MountAnalyticsContext *mountAnalyticsContext);

      UIView *viewForConfiguration(Class componentClass,
                                   const CKComponentViewConfiguration &config,
                                   UIView *container,
                                   MountAnalyticsContext *mountAnalyticsContext);
    private:
      bool usingStringIdentifier;
      std::unordered_map<ViewKey, ViewReusePool> map;
      std::unordered_map<ViewKeyWithStringIdentifier, ViewReusePool> mapWithStringIdentifier;
      std::vector<UIView *> vendedViews;

      ViewReusePoolMap(const ViewReusePoolMap&) = delete;
      ViewReusePoolMap &operator=(const ViewReusePoolMap&) = delete;
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
                                   const CKComponentViewConfiguration &config);

    private:
      ViewReusePoolMap &viewReusePoolMap;
      MountAnalyticsContext *mountAnalyticsContext;

      ViewManager(const ViewManager&) = delete;
      ViewManager &operator=(const ViewManager&) = delete;
    };

    class AttributeApplicator {
    public:
      static void apply(UIView *view, const CKComponentViewConfiguration &config);

      /** Internal implementation detail of CKPerformOptimisticViewMutation; don't use this directly. */
      static void addOptimisticViewMutationTeardown(UIView *view, CKOptimisticViewMutationTeardown teardown);
    };
  }
}
