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
        return MountContext(std::make_shared<ViewManager>(v), {0,0}, {}, NO);
      }

      /** The view manager for the context. Components should be mounted using this view manager. */
      std::shared_ptr<CK::Component::ViewManager> viewManager;
      /** An offset within viewManager's view. Subviews should be positioned relative to this position. */
      CGPoint position;
      /** The distance to each edge of the root component's frame. May be used to e.g. bleed out to the root edge. */
      UIEdgeInsets layoutGuide;
      /** If YES, then [CATransaction +setDisableActions:] is used to disable animations while mounting. */
      BOOL shouldBlockAnimations;

      MountContext offset(const CGPoint p, const CGSize parentSize, const CGSize childSize) const {
        const UIEdgeInsets guide = adjustedGuide(layoutGuide, p, parentSize, childSize);
        return MountContext(viewManager, position + p, guide, shouldBlockAnimations);
      };

      MountContext childContextForSubview(UIView *subview, const BOOL didBlockAnimations) const {
        ViewReuseUtilities::mountingInChildContext(subview, viewManager->view);
        const BOOL shouldBlockChildAnimations = shouldBlockAnimations || didBlockAnimations;
        return MountContext(std::make_shared<ViewManager>(subview), {0,0}, layoutGuide, shouldBlockChildAnimations);
      };

    private:
      MountContext(const std::shared_ptr<ViewManager> &m, const CGPoint p, const UIEdgeInsets l, const BOOL b)
      : viewManager(m), position(p), layoutGuide(l), shouldBlockAnimations(b) {}

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
