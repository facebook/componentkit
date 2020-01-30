/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKDefines.h>

#if CK_NOT_SWIFT

#import <UIKit/UIKit.h>

#import <unordered_map>
#import <vector>

#import <ComponentKit/CKEqualityHelpers.h>
#import <ComponentKit/CKNonNull.h>

@class CKComponentRootView;

namespace CK {
  namespace Component {

    class ViewStorage {
      using RootViews = std::unordered_map<NSString *, std::vector<CKComponentRootView *>, hash<NSString *>, is_equal<NSString *>>;
      RootViews _rootViews;
      /** This is used to prevent mutation of view pool upon enumeration(reentrant mutation) */
      bool _locked;
    public:
      ViewStorage() : _rootViews({}), _locked(false) {};

      auto push(CKComponentRootView *rootView, NonNull<NSString *> category) -> void;
      auto pop(NonNull<NSString *> category) -> CKComponentRootView *;
      auto clear() -> void;
    };

    /**
     Root view pool stores a list of `CKComponentRootView` with category which could be reused when it's needed.
     All methods of `RootViewPool` are main thread affined.
     */
    class RootViewPool {
      std::shared_ptr<ViewStorage> _viewStorage;
    public:
      RootViewPool() : _viewStorage(std::make_shared<ViewStorage>()) {};

      /**
       Pop a `CKComponentRootView` from view pool which matches the specified category.
       `nil` will be returned if no such view is found.
       */
      auto popRootViewWithCategory(NonNull<NSString *> category) -> CKComponentRootView *;

      /**
       Push a `CKComponentRootView` into view pool with category.
       All views in local view pools of this root view will be hidden.
       @see CK::Component:ViewReusePool
       */
      auto pushRootViewWithCategory(NonNull<CKComponentRootView *> rootView,
                                    NonNull<NSString *> category) -> void;

      /**
       Clear all views in this view pool.
       */
      auto clear() -> void;
    };

    /**
     A global root view pool that could be shared in app.
     */
    auto GlobalRootViewPool() -> RootViewPool &;
  };
};

#endif
