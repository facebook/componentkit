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

#import <ComponentKit/ComponentMountContext.h>
#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKComponentLayout.h>
#import <ComponentKit/CKComponentScopeEnumeratorProvider.h>
#import <ComponentKit/CKBuildComponent.h>

/**
 Params struct for the `buildComponentTree:` method.
 **/
struct CKBuildComponentTreeParams {
  __weak CKComponentScopeRoot *scopeRoot;
  const CKComponentStateUpdateMap &stateUpdates;
  const CKTreeNodeDirtyIds &treeNodeDirtyIds;
  BuildTrigger buildTrigger;
};

@class CKComponentScopeRoot;
@protocol CKTreeNodeWithChildrenProtocol;

@interface CKComponent ()

/**
 Mounts the component in the given context:
 - Stores references to the supercomponent and superview for -nextResponder and -viewConfiguration.
 - Creates or updates a controller for this component, if one should exist.
 - If this component has a view, creates or recycles a view by fetching one from the given MountContext, and:
   - Unmounts the view's previous component (if any).
   - Applies attributes to the view.
   - Stores a reference to the view in _mountedView (for -viewContext, transient view state, and -unmount).
   - Stores a reference back to this component in view.ck_component. (This sets up a retain cycle which must be torn
     down in -unmount.)

 Override this if your component wants to perform a custom mounting action, but this should be very rare!

 @param context The component's content should be positioned within the given view at the given position.
 @param size The size for this component
 @param children The positioned children for this component. Normally this parameter is ignored.
 @param supercomponent This component's parent component
 @return An updated mount context. In most cases, this is just be the passed-in context. If a view was created, this is
 used to specify that subcomponents should be mounted inside the view.
 */
- (CK::Component::MountResult)mountInContext:(const CK::Component::MountContext &)context
                                        size:(const CGSize)size
                                    children:(std::shared_ptr<const std::vector<CKComponentLayoutChild>>)children
                              supercomponent:(CKComponent *)supercomponent NS_REQUIRES_SUPER;

/**
 For internal use only; don't use this initializer.

 @param view A struct describing the view for this component. Pass {} to specify that no view should be created.
 @param size A size constraint that should apply to this component. Pass {} to specify no size constraint.
 @param isLayoutComponent should be YES if it's being called from an internal layout component.

 This initializer will not try to acquire the scope handle from the thread local store.
 */
+ (instancetype)newRenderComponentWithView:(const CKComponentViewConfiguration &)view
                                      size:(const CKComponentSize &)size
                         isLayoutComponent:(BOOL)isLayoutComponent;

/**
 Unmounts the component:
 - Clears the references to supercomponent and superview.
 - If the component has a _mountedView:
   - Clears the view's reference back to this component in ck_component.
   - Clears _mountedView.
 */
- (void)unmount;

- (const CKComponentViewConfiguration &)viewConfiguration;

- (id)nextResponderAfterController;

/** Called when the component and all its children have been mounted. */
- (void)childrenDidMount;

/** Used to get the root component in the responder chain; don't touch this. */
@property (nonatomic, weak) UIView *rootComponentMountedView;

/** For internal use only; don't touch this. */
@property (nonatomic, strong, readonly) id<NSObject> scopeFrameToken;

/** The size that was passed into the component; don't touch this. */
@property (nonatomic, assign, readonly) CKComponentSize size;

/** Used to get the scope root enumerator; during component creation only */
@property (nonatomic, strong, readonly) id<CKComponentScopeEnumeratorProvider> scopeEnumeratorProvider;

/** Indicates that a scope conflict has been found and either this component or an ancestor is involved in the conflict */
@property (nonatomic, readonly) BOOL componentOrAncestorHasScopeConflict;

/** If the component owns its own view and is mounted, returns it. */
@property (nonatomic, readonly) UIView *mountedView;

/** For internal use only; don't touch this. */
@property (nonatomic, strong, readonly) CKComponentScopeHandle *scopeHandle;

/** For internal use only; don't touch this. */
- (void)acquireScopeHandle:(CKComponentScopeHandle *)scopeHandle;

/**
 For internal use only; don't touch this.

 This method translates the component render method into a 'CKTreeNode'; a component tree.
 It's being called by the infra during the component tree creation.
 */
- (void)buildComponentTree:(id<CKTreeNodeWithChildrenProtocol>)parent
            previousParent:(id<CKTreeNodeWithChildrenProtocol>)previousParent
                    params:(const CKBuildComponentTreeParams &)params
                    config:(const CKBuildComponentConfig &)config
            hasDirtyParent:(BOOL)hasDirtyParent;

@end
