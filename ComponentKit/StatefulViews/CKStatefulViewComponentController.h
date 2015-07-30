/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKComponentController.h>

/**
 CKStatefulViewComponentController acts as an escape hatch for views that don't play nicely with the assumptions made
 by the Components infrastructure.

 Stateful views have two distinguishing characteristics from regular component views:
 - The stateful view will move between superviews if the root mounted view changes.
   (Normally, an entirely new view in the new root view would be used.)
 - The controller can delay the relinquishing of a stateful view, preventing it from returning to the reuse pool.
   (Normally, Components expects to be in control of view lifecycles and may return a view to the pool at any time.)

 Examples of where stateful views may be useful:
 - Photos, when tapped, may wish to animate the photo to fullscreen. When the photo is dismissed, it should return to
   the place from which it came, even if table view cell recycling has resulted in an entirely new cell being used for
   the photo's story.
 - Swapping from one video view to another (because the underlying table view cell was recycled) will result in a
   noticeable pause in video playback. By using stateful views, the video view will simply be moved to the new cell
   instead.
 - Text fields have lots of state that cannot be accessed externally (autocomplete status; precise scroll position).
   By making the text field a stateful view, it will be moved between cells and maintain this state.

 This controller's corresponding component must subclass CKStatefulViewComponent.
 */
@interface CKStatefulViewComponentController : CKComponentController

/** Return a new instance of the stateful view type used by this controller. Views are automatically recycled. */
+ (UIView *)newStatefulView:(id)context;

/**
 Optionally override this to return a context that should be passed to +newStatefulView.
 Views will be recycled based on the context returned here. The default is nil.
 */
+ (id)contextForNewStatefulView:(CKComponent *)component;

/**
 Configure a given instance of a stateful view with the state from a given CKComponent instance. This has two purposes:
 - Configuring a view for the first time, before it appears in the view hierarchy;
 - Reconfiguring the current view when the CKComponent instance is updated and remounted.
 */
+ (void)configureStatefulView:(UIView *)statefulView
                 forComponent:(CKComponent *)component;

/**
 Optionally override this to return the maximum number of stateful components that should be enqueued into the
 reuse pool. After this limit is reached, relinquished components will no longer be retained.
 */
+ (NSInteger)maximumPoolSize:(id)context;

/**
 The current stateful view owned by this controller, if any.

 - Do not override this method. (Override +newStatefulView instead.)
 - Do not remove this view from its superview. (Its children can be removed from the stateful view itself, of course.)
 - Do not change this view's size. (Trigger a component reflow to change the value passed to +newWithSize: for the
   corresponding component instead.)
 */
- (UIView *)statefulView;

/**
 Called when a stateful view has been acquired (either created or recycled) and configured.
 You could use this method to e.g. set the component controller as the view's delegate.
 */
- (void)didAcquireStatefulView:(UIView *)statefulView NS_REQUIRES_SUPER;

/**
 Called when the controller is about to relinquish the given stateful view, returning it to the reuse pool.
 This will be called when the component controller is not mounted and -canRelinquishStatefulView returns YES.

 Relinquishing the view happens asynchronously after the component is unmounted. When this method is called
 the view might already have been removed from its superview so consider carefully where you need to cleanup
 your view's state.
 */
- (void)willRelinquishStatefulView:(UIView *)statefulView NS_REQUIRES_SUPER;

/**
 Override this method to delay relinquishing a stateful view when the controller's component is unmounted.
 The default implementation returns YES. See -canRelinquishStatefulViewDidChange for an example of how this may be used.
 */
- (BOOL)canRelinquishStatefulView;

/**
 Call this method when the value returned by -canRelinquishStatefulView has changed. This may trigger the controller
 to relinquish the stateful view.

 For example, a video component controller may return NO from -canRelinquishStatefulView while the video view is
 fullscreen. After the video exits fullscreen, call this method to signal that -canRelinquishStatefulView will now
 return YES.
 */
- (void)canRelinquishStatefulViewDidChange;

@end
