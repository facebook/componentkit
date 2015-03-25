/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant 
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <memory>

#import <UIKit/UIKit.h>

#import <ComponentKit/ComponentUtilities.h>
#import <ComponentKit/ComponentViewManager.h>
#import <ComponentKit/ComponentViewReuseUtilities.h>

namespace CK {
  namespace Component {
    struct MountContext {
      /** Constructs a new mount context for the given view. */
      static MountContext RootContext(UIView *v) {
        ViewReuseUtilities::mountingInRootView(v);
        std::shared_ptr<ViewManager> rootViewManager(new ViewManager(v));
        return MountContext(rootViewManager, {0,0}, rootViewManager, UIEdgeInsetsZero);
      }

      /** The view manager for the context. Components should be mounted using this view manager. */
      std::shared_ptr<CK::Component::ViewManager> viewManager;
      /** An offset within viewManager's view. Subviews should be positioned relative to this position. */
      CGPoint position;

      /**
       The view manager for the root view.
       Components may use this to mount in the root view when bleeding outside of their logical frame.
       */
      std::shared_ptr<CK::Component::ViewManager> rootViewManager;
      /**
       The layoutGuide indicates the distance to each edge of the root component's logical frame.
       Components may use this to bleed outside of their logical frame and extend to the root edge.
       */
      UIEdgeInsets layoutGuide;

      MountContext offset(CGPoint p, CGSize parentSize, CGSize childSize) const {
        return MountContext(viewManager, position + p, rootViewManager,
                            adjustedGuide(layoutGuide, p, parentSize, childSize));
      };

      MountContext childContextForSubview(UIView *subview) const {
        ViewReuseUtilities::mountingInChildContext(subview, viewManager->view);
        return MountContext(std::shared_ptr<ViewManager>(new ViewManager(subview)), {0,0}, rootViewManager, layoutGuide);
      };

      /** Avoid using this unless you need to. Prefer using RootContext() and offset/childContextForSubview. */
      MountContext(const std::shared_ptr<ViewManager> &m,
                   const CGPoint p,
                   const std::shared_ptr<ViewManager> &r,
                   const UIEdgeInsets l)
      : viewManager(m), position(p), rootViewManager(r), layoutGuide(l) {}

    private:
      static UIEdgeInsets adjustedGuide(const UIEdgeInsets layoutGuide, const CGPoint offset,
                                        const CGSize parentSize, const CGSize childSize) {
        return {
          .left = layoutGuide.left + offset.x,
          .top = layoutGuide.top + offset.y,
          .right = layoutGuide.right + (parentSize.width - childSize.width) - offset.x,
          .bottom = layoutGuide.bottom + (parentSize.height - childSize.height) - offset.y,
        };
      };
    };

    struct MountResult {
      /**
       Should children of this component be recursively mounted? (This is all or nothing; you can't specify this for
       individual children.) Usually YES; some components use this to defer mounting of children (e.g. h-scroll).
       */
      BOOL mountChildren;
      /** The context within which children should be mounted. */
      CK::Component::MountContext contextForChildren;
    };
  }
}
