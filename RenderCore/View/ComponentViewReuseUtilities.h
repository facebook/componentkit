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

#import <vector>

#import <UIKit/UIKit.h>

struct CKComponentViewClass;

namespace CK {
  namespace Component {
    /** Will be used to collect information during mount. */
    struct MountAnalyticsContext {
      NSUInteger viewAllocations = 0;
      NSUInteger viewReuses = 0;
      NSUInteger viewHides = 0;
      NSUInteger viewUnhides = 0;
    };

    class ViewReuseUtilities {
    public:
      /** Called when Components will begin mounting in a root view */
      static void mountingInRootView(UIView *rootView);
      /** Called when Components creates a view */
      static void createdView(UIView *view, const CKComponentViewClass &viewClass, UIView *parent);
      /** Called when Components will begin mounting child components in a new child view */
      static void mountingInChildContext(UIView *view, UIView *parent);

      /** Called when Components is about to hide a Components-managed view */
      static void didHide(UIView *view, MountAnalyticsContext *mountAnalyticsContext);
      /** Called when Components is about to unhide a Components-managed view */
      static void willUnhide(UIView *view, MountAnalyticsContext *mountAnalyticsContext);
    };
  }
}

#endif
