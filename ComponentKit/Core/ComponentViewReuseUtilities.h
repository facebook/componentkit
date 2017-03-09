/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <vector>

#import <UIKit/UIKit.h>

class CKComponentViewClass;

namespace CK {
  namespace Component {
    class ViewReuseUtilities {
    public:
      /** Called when Components will begin mounting in a root view */
      static void mountingInRootView(UIView *rootView);
      /** Called when Components creates a view */
      static void createdView(UIView *view, const CKComponentViewClass &viewClass, UIView *parent);
      /** Called when Components will begin mounting child components in a new child view */
      static void mountingInChildContext(UIView *view, UIView *parent);

      /** Called when Components is about to hide a Components-managed view */
      static void didHide(UIView *view);
      /** Called when Components is about to unhide a Components-managed view */
      static void willUnhide(UIView *view);
    };
  }
}
