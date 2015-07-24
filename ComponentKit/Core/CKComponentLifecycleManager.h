/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKComponentBoundsAnimation.h>
#import <ComponentKit/CKComponentLayout.h>
#import <ComponentKit/CKDimension.h>

@class CKComponent;
@class CKComponentScopeRoot;

@protocol CKComponentProvider;
@protocol CKComponentLifecycleManagerDelegate;
@protocol CKComponentLifecycleManagerAsynchronousUpdateHandler;

struct CKComponentLifecycleManagerState {
  id model;
  id<NSObject> context;
  CKSizeRange constrainedSize;
  CKComponentLayout layout;
  CKComponentScopeRoot *root;
  id memoizerState;
  CKComponentBoundsAnimation boundsAnimation;
};

extern const CKComponentLifecycleManagerState CKComponentLifecycleManagerStateEmpty;

@interface CKComponentLifecycleManager : NSObject

/** Designated initializer */
- (instancetype)initWithComponentProvider:(Class<CKComponentProvider>)componentProvider;

/** See @protocol CKComponentLifecycleManagerAsynchronousUpdateHandler */
@property (nonatomic, weak) id<CKComponentLifecycleManagerAsynchronousUpdateHandler> asynchronousUpdateHandler;

@property (nonatomic, weak) id<CKComponentLifecycleManagerDelegate> delegate;

- (CKComponentLifecycleManagerState)prepareForUpdateWithModel:(id)model constrainedSize:(CKSizeRange)constrainedSize context:(id<NSObject>)context;

/**
 Updates the state to the new one without mounting the view.

 If you are lazily mounting and unmounting the view (like in a datasource), this is the method to call
 during a state mutation.
 */
- (void)updateWithStateWithoutMounting:(const CKComponentLifecycleManagerState &)state;

/**
 Updates the state to the new one.

 If we have a view mounted, we remount the view to pick up the new state.
 */
- (void)updateWithState:(const CKComponentLifecycleManagerState &)state;

/**
 Attaches the manager to the given view. This will display the component in the view and update the view whenever the
 component is updated due to a model or state change.

 Only one manager can be attached to a view at a time. If the given view already has a manager attached, the previous
 manager will be detached before this manager attaches.

 This method efficiently recycles subviews from the previously attached manager whenever possible. Any subviews that
 could not be reused are hidden for future reuse.

 Attaching will not modify any subviews in the view that were not created by the components infrastructure.
 */
- (void)attachToView:(UIView *)view;

/**
 Detaches the manager from its view. This stops the manager from updating the view's subviews as its component updates.

 This does not remove or hide the existing views in the view. If you attach a new manager to the view, it will recycle
 the existing views.
 */
- (void)detachFromView;

/** Returns whether the lifecycle manager is attached to a view. */
- (BOOL)isAttachedToView;

/** The current top-level layout size for the component */
- (CGSize)size;

/** The last model associated with this lifecycle manager */
- (id)model;

/** The current scope frame associated with this lifecycle manager */
- (CKComponentScopeRoot *)scopeRoot;

/** The current component layout associated with this lifecycle manager */
- (const CKComponentLayout &)componentLayout;

@end


@protocol CKComponentLifecycleManagerDelegate <NSObject>

/**
 Sent when the size of the component layout changes due to a state change within a subcomponent or due to a call
 to [CKComponentLifecycleManager -updateWithState:].
 */
- (void)componentLifecycleManager:(CKComponentLifecycleManager *)manager
       sizeDidChangeWithAnimation:(const CKComponentBoundsAnimation &)animation;

@end
