/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <Foundation/Foundation.h>

#import <unordered_set>

#import <ComponentKit/CKComponentBoundsAnimation.h>
#import <ComponentKit/CKComponentScopeTypes.h>
#import <ComponentKit/CKScopedComponentController.h>
#import <ComponentKit/CKUpdateMode.h>

@protocol CKScopedComponent;
@protocol CKScopedComponentController;

@class CKComponentScopeFrame;
@class CKComponentScopeRoot;

/**
 Scope predicates are a tool used by the framework to register components and controllers on initialization that have
 specific characteristics. These predicates allow rapid enumeration over matching components and controllers.
 */
typedef BOOL (*CKComponentScopePredicate)(id<CKScopedComponent>);
typedef BOOL (*CKComponentControllerScopePredicate)(id<CKScopedComponentController>);

/**
 Enumerator blocks allow a consumer to enumerate over all of the components or controllers that matched a predicate.
 */
typedef void (^CKComponentScopeEnumerator)(id<CKScopedComponent>);
typedef void (^CKComponentControllerScopeEnumerator)(id<CKScopedComponentController>);

/** Component state announcements will always be made on the main thread. */
@protocol CKComponentStateListener <NSObject>

- (void)componentScopeHandleWithIdentifier:(CKComponentScopeHandleIdentifier)globalIdentifier
                            rootIdentifier:(CKComponentScopeRootIdentifier)rootIdentifier
                     didReceiveStateUpdate:(id (^)(id))stateUpdate
                                  userInfo:(NSDictionary<NSString *, NSString *> *)userInfo
                                      mode:(CKUpdateMode)mode;

@end

@interface CKComponentScopeRoot : NSObject

/**
 Creates a conceptually brand new scope root. Prefer to use CKComponentScopeRootWithDefaultPredicates instead of this.
 
 @param listener A listener for state updates that flow through the scope root.
 @param componentPredicates A vector of C functions that are executed on each component constructed within the scope
                            root. By passing in the predicates on initialization, we are able to cache which components
                            match the predicate for rapid enumeration later.
 @param componentControllerPredicates Same as componentPredicates above, but for component controllers.
 */
+ (instancetype)rootWithListener:(id<CKComponentStateListener>)listener
             componentPredicates:(const std::unordered_set<CKComponentScopePredicate> &)componentPredicates
   componentControllerPredicates:(const std::unordered_set<CKComponentControllerScopePredicate> &)componentControllerPredicates;

/** Creates a new version of an existing scope root, ready to be used for building a component tree */
- (instancetype)newRoot;

/** Must be called when initializing a component or controller. */
- (void)registerComponentController:(id<CKScopedComponentController>)componentController;
- (void)registerComponent:(id<CKScopedComponent>)component;

/**
 Allows rapid enumeration over the components or controllers that matched a predicate. The predicate should be provided
 in the initializer of the scope root in order to reduce the runtime costs of the enumeration.
 
 There is no guaranteed ordering of arguments that are provided to the enumerators.
 */
- (void)enumerateComponentsMatchingPredicate:(CKComponentScopePredicate)predicate
                                       block:(CKComponentScopeEnumerator)block;
- (void)enumerateComponentControllersMatchingPredicate:(CKComponentControllerScopePredicate)predicate
                                                 block:(CKComponentControllerScopeEnumerator)block;

@property (nonatomic, weak, readonly) id<CKComponentStateListener> listener;
@property (nonatomic, readonly) CKComponentScopeRootIdentifier globalIdentifier;
@property (nonatomic, strong, readonly) CKComponentScopeFrame *rootFrame;

@end
