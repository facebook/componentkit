/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <UIKit/UIKit.h>

#import <unordered_map>
#import <vector>

#import <ComponentKit/CKEqualityHashHelpers.h>
#import <ComponentKit/CKNonNull.h>

@class CKComponentRootView;

namespace CK {
  namespace Component {
    
    /**
     Root view pool stores a list of `CKComponentRootView` with category which could be reused when it's needed.
     All methods of `RootViewPool` are main thread affined.
     */
    class RootViewPool {
      using ViewStorage = std::unordered_map<NSString *, std::vector<CKComponentRootView *>, hash<NSString *>, is_equal<NSString *>>;
      std::shared_ptr <ViewStorage> _rootViews;
    public:
      RootViewPool() : _rootViews(std::make_shared<ViewStorage>()) {};

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
      auto pushRootViewWithCategory(NonNull<CKComponentRootView *> view,
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
