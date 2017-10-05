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
#import <ComponentKit/CKComponentScopeEnumeratorProvider.h>
#import <ComponentKit/CKScopedComponentController.h>
#import <ComponentKit/CKUpdateMode.h>

@protocol CKScopedComponent;
@protocol CKScopedComponentController;

@class CKComponentScopeFrame;
@class CKComponentScopeRoot;

/** Component state announcements will always be made on the main thread. */
@protocol CKComponentStateListener <NSObject>

- (void)componentScopeHandleWithIdentifier:(CKComponentScopeHandleIdentifier)globalIdentifier
                            rootIdentifier:(CKComponentScopeRootIdentifier)rootIdentifier
                     didReceiveStateUpdate:(id (^)(id))stateUpdate
                                  userInfo:(NSDictionary<NSString *, NSString *> *)userInfo
                                      mode:(CKUpdateMode)mode;

@end

@interface CKComponentScopeRoot : NSObject <CKComponentScopeEnumeratorProvider>

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

@property (nonatomic, weak, readonly) id<CKComponentStateListener> listener;
@property (nonatomic, readonly) CKComponentScopeRootIdentifier globalIdentifier;
@property (nonatomic, strong, readonly) CKComponentScopeFrame *rootFrame;

@end
