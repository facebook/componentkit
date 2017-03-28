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

#import <vector>

#import <ComponentKit/CKComponentBoundsAnimation.h>
#import <ComponentKit/CKComponentScopeTypes.h>
#import <ComponentKit/CKUpdateMode.h>

@protocol CKScopedComponent;
@protocol CKScopedComponentController;

@class CKComponentScopeFrame;
@class CKComponentScopeRoot;

typedef BOOL (*CKComponentScopePredicate)(id<CKScopedComponent>);
typedef BOOL (*CKComponentControllerScopePredicate)(id<CKScopedComponentController>);

typedef void (^CKComponentScopeEnumerator)(id<CKScopedComponent>);
typedef void (^CKComponentControllerScopeEnumerator)(id<CKScopedComponentController>);

/** Component state announcements will always be made on the main thread. */
@protocol CKComponentStateListener <NSObject>

- (void)componentScopeHandleWithIdentifier:(CKComponentScopeHandleIdentifier)globalIdentifier
                            rootIdentifier:(CKComponentScopeRootIdentifier)rootIdentifier
                     didReceiveStateUpdate:(id (^)(id))stateUpdate
                                      mode:(CKUpdateMode)mode;

@end

@interface CKComponentScopeRoot : NSObject

/** Creates a conceptually brand new scope root */
+ (instancetype)rootWithListener:(id<CKComponentStateListener>)listener
             componentPredicates:(const std::vector<CKComponentScopePredicate> &)componentPredicates
   componentControllerPredicates:(const std::vector<CKComponentControllerScopePredicate> &)componentControllerPredicates;

/** Creates a new version of an existing scope root, ready to be used for building a component tree */
- (instancetype)newRoot;

- (void)registerComponentController:(id<CKScopedComponentController>)componentController;

- (void)registerComponent:(id<CKScopedComponent>)component;

- (void)enumerateComponentsMatchingPredicate:(CKComponentScopePredicate)predicate
                                       block:(CKComponentScopeEnumerator)block;

- (void)enumerateComponentControllersMatchingPredicate:(CKComponentControllerScopePredicate)predicate
                                                 block:(CKComponentControllerScopeEnumerator)block;

@property (nonatomic, weak, readonly) id<CKComponentStateListener> listener;
@property (nonatomic, readonly) CKComponentScopeRootIdentifier globalIdentifier;
@property (nonatomic, strong, readonly) CKComponentScopeFrame *rootFrame;

@end
