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

#import <Foundation/Foundation.h>
#import <ComponentKit/CKBuildComponent.h>
#import <ComponentKit/CKComponentScopeTypes.h>
#import <ComponentKit/ComponentMountContext.h>
#import <ComponentKit/CKOptional.h>
#import <ComponentKit/CKTreeNodeProtocol.h>
#import <ComponentKit/CKSystraceListener.h>

@protocol CKMountable;
@protocol CKTreeNodeProtocol;

@class CKComponent;
@class CKComponentScopeRoot;

/**
 This protocol is being used by the infrastructure to collect data about the component tree life cycle.
 */
@protocol CKAnalyticsListener <NSObject>

/**
 Called before the component tree creation.

 @param scopeRoot Scope root for component tree. Use that to identify tree between will/didBuild.
 @param buildTrigger The build trigger (new tree, state update, props updates) for this component tree creation.
 @param stateUpdates The state updates map for the component tree creation.
 @param enableComponentReuseOptimizations If `NO` any optimization for component reuse is turned off.
 */
- (void)willBuildComponentTreeWithScopeRoot:(CKComponentScopeRoot *)scopeRoot
                               buildTrigger:(CKBuildTrigger)buildTrigger
                               stateUpdates:(const CKComponentStateUpdateMap &)stateUpdates
          enableComponentReuseOptimizations:(BOOL)enableComponentReuseOptimizations;

/**
 Called after the component tree creation.

 @param scopeRoot Scope root for component tree. Use that to identify tree between will/didBuild
 @param buildTrigger The build trigger (new tree, state update, props updates) for this component tree creation.
 @param stateUpdates The state updates map for the component tree creation.
 @param component Root component for created tree
 @param enableComponentReuseOptimizations If `NO` any optimization for component reuse is turned off.
 */
- (void)didBuildComponentTreeWithScopeRoot:(CKComponentScopeRoot *)scopeRoot
                              buildTrigger:(CKBuildTrigger)buildTrigger
                              stateUpdates:(const CKComponentStateUpdateMap &)stateUpdates
                                 component:(CKComponent *)component
         enableComponentReuseOptimizations:(BOOL)enableComponentReuseOptimizations;

/**
 Called before component tree layout.

 @param component The root component that was laid out.
 @param buildTrigger The build trigger that caused the layout computaion
                     Can be CK::none, in case that the layout was computed due to a re-layout measurment.

 @discussion Please not that this callback can be called on the same component from different threads in undefined order, for instance:
 ThreadA, willLayout Component1
 ThreadB, willLayout Component1
 ThreadA, didLayout Component1
 ThreadB, didLayout Component1
 To identify matching will/didLayout events between callbacks, please use Thread id and Component id
 */
- (void)willLayoutComponentTreeWithRootComponent:(id<CKMountable>)component buildTrigger:(CK::Optional<CKBuildTrigger>)buildTrigger;

/**
 Called after component tree layout.

 @param component The root component that was laid out.

 @discussion Please not that this callback can be called on the same component from different threads in undefined order, for instance:
 ThreadA, willLayout Component1
 ThreadB, willLayout Component1
 ThreadA, didLayout Component1
 ThreadB, didLayout Component1
 To identify matching will/didLayout events between callbacks, please use Thread id and Component id
*/
- (void)didLayoutComponentTreeWithRootComponent:(id<CKMountable>)component;

/**
 Called before/after mounting a component tree

 @param component Root component for mounted tree
 */

- (void)willMountComponentTreeWithRootComponent:(id<CKMountable>)component;
- (void)didMountComponentTreeWithRootComponent:(id<CKMountable>)component
                         mountAnalyticsContext:(CK::Optional<CK::Component::MountAnalyticsContext>)mountAnalyticsContext;

/**
 Called before mounting a component tree.

 If returns YES, an extra information will be collected during the mount process.
 The extra information will be provided back in `didMountComponentTreeWithRootComponent` callback.
 */
- (BOOL)shouldCollectMountInformationForRootComponent:(id<CKMountable>)component;

/**
 Called before/after collecting animations from a component tree.

 @param component Root component for the tree that is about to be mounted.
 */
- (void)willCollectAnimationsFromComponentTreeWithRootComponent:(id<CKMountable>)component;
- (void)didCollectAnimationsFromComponentTreeWithRootComponent:(id<CKMountable>)component;

/** Render Components **/

/**
 Called after a component tree's node has been reused

 @param node The tree node that has been reused.
 @param scopeRoot Scope root for component tree.
 @param previousScopeRoot The previous scope root of the component tree
 @warning A node is only reused if conforming to the render protocol.
 */
- (void)didReuseNode:(id<CKTreeNodeProtocol>)node
         inScopeRoot:(CKComponentScopeRoot *)scopeRoot
fromPreviousScopeRoot:(CKComponentScopeRoot *)previousScopeRoot;

/**
 Provides a systrace listener. Can be nil if systrace is not enabled.
 */
- (id<CKSystraceListener>)systraceListener;

/**
 If returns true, `didBuildTreeNodeForPrecomputedChild` will be called for non-render component during the component tree creation.
 */
- (BOOL)shouldCollectTreeNodeCreationInformation:(CKComponentScopeRoot *)scopeRoot;

/**
 Will be called for every component with pre-computed child (CKCompositeComponent for example) during the component tree creation.
 */
- (void)didBuildTreeNodeForPrecomputedChild:(id<CKTreeNodeComponentProtocol>)component
                                       node:(id<CKTreeNodeProtocol>)node
                                     parent:(id<CKTreeNodeWithChildrenProtocol>)parent
                                     params:(const CKBuildComponentTreeParams &)params
                       parentHasStateUpdate:(BOOL)parentHasStateUpdate;

@end

#endif
