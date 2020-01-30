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

#import <unordered_set>

#import <ComponentKit/CKCollection.h>
#import <ComponentKit/CKComponentBoundsAnimation.h>
#import <ComponentKit/CKComponentScopeTypes.h>
#import <ComponentKit/CKComponentScopeEnumeratorProvider.h>
#import <ComponentKit/CKComponentControllerProtocol.h>
#import <ComponentKit/CKUpdateMode.h>

@protocol CKAnalyticsListener;
@protocol CKComponentProtocol;
@protocol CKComponentControllerProtocol;
@protocol CKTreeNodeProtocol;
@protocol CKTreeNodeWithChildrenProtocol;
@protocol CKComponentScopeFrameProtocol;

@class CKComponentScopeFrame;
@class CKComponentScopeRoot;

class CKRootTreeNode;
struct CKStateUpdateMetadata;

/** Component state announcements will always be made on the main thread. */
@protocol CKComponentStateListener <NSObject>

- (void)componentScopeHandle:(CKComponentScopeHandle *)handle
              rootIdentifier:(CKComponentScopeRootIdentifier)rootIdentifier
       didReceiveStateUpdate:(id (^)(id))stateUpdate
                    metadata:(const CKStateUpdateMetadata &)metadata
                        mode:(CKUpdateMode)mode;

@end

@interface CKComponentScopeRoot : NSObject <CKComponentScopeEnumeratorProvider>

/**
 Creates a conceptually brand new scope root. Prefer to use CKComponentScopeRootWithDefaultPredicates instead of this.

 @param listener A listener for state updates that flow through the scope root.
 @param analyticsListener A listener for analytics events for the components of this scope root.
 @param componentPredicates A vector of C functions that are executed on each component constructed within the scope
                            root. By passing in the predicates on initialization, we are able to cache which components
                            match the predicate for rapid enumeration later.
 @param componentControllerPredicates Same as componentPredicates above, but for component controllers.
 */
+ (instancetype)rootWithListener:(id<CKComponentStateListener>)listener
               analyticsListener:(id<CKAnalyticsListener>)analyticsListener
             componentPredicates:(const std::unordered_set<CKComponentPredicate> &)componentPredicates
   componentControllerPredicates:(const std::unordered_set<CKComponentControllerPredicate> &)componentControllerPredicates;

/** Creates a new version of an existing scope root, ready to be used for building a component tree */
- (instancetype)newRoot;

/** Must be called when initializing a component or controller. */
- (void)registerComponentController:(id<CKComponentControllerProtocol>)componentController;
- (void)registerComponent:(id<CKComponentProtocol>)component;

- (CKCocoaCollectionAdapter<id<CKComponentProtocol>>)componentsMatchingPredicate:(CKComponentPredicate)predicate;
- (CKCocoaCollectionAdapter<id<CKComponentControllerProtocol>>)componentControllersMatchingPredicate:(CKComponentControllerPredicate)predicate;

@property (nonatomic, weak, readonly) id<CKComponentStateListener> listener;
@property (nonatomic, strong, readonly) id<CKAnalyticsListener> analyticsListener;
@property (nonatomic, readonly) CKComponentScopeRootIdentifier globalIdentifier;

/** Render Support */
@property (nonatomic, assign) BOOL hasRenderComponentInTree;
- (CKRootTreeNode &)rootNode;

#if DEBUG
/** Returns a multi-line string describing all the components in this root. */
- (NSString *)debugDescription;
#endif

@end

#endif
