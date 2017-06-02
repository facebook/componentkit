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

#import <ComponentKit/CKComponentScopeTypes.h>
#import <ComponentKit/CKScopedComponentController.h>
#import <ComponentKit/CKUpdateMode.h>

@class CKComponent;
@class CKComponentScopeRoot;
@class CKScopedResponder;

@protocol CKComponentStateListener;
@protocol CKScopedComponent;

@interface CKComponentScopeHandle<__covariant ControllerType:id<CKScopedComponentController>> : NSObject

/**
 This method looks to see if the currently defined scope matches that of the given component; if so it returns the
 handle corresponding to the current scope. Otherwise it returns nil.
 This is only meant to be called when constructing a component and as part of the implementation itself.
 */
+ (instancetype)handleForComponent:(id<CKScopedComponent>)component;

/** Creates a conceptually brand new scope handle */
- (instancetype)initWithListener:(id<CKComponentStateListener>)listener
                  rootIdentifier:(CKComponentScopeRootIdentifier)rootIdentifier
                  componentClass:(Class<CKScopedComponent>)componentClass
             initialStateCreator:(id (^)(void))initialStateCreator;

/** Creates a new instance of the scope handle that incorporates the given state updates. */
- (instancetype)newHandleWithStateUpdates:(const CKComponentStateUpdateMap &)stateUpdates
                       componentScopeRoot:(CKComponentScopeRoot *)componentScopeRoot;

/** Creates a new, but identical, instance of the scope handle that will be reacquired due to a scope collision. */
- (instancetype)newHandleToBeReacquiredDueToScopeCollision;

/** Enqueues a state update to be applied to the scope with the given mode. */
- (void)updateState:(id (^)(id))updateBlock
           userInfo:(NSDictionary<NSString *, NSString *> *)userInfo
               mode:(CKUpdateMode)mode;

/** Informs the scope handle that it should complete its configuration. This will generate the controller */
- (void)resolve;

/**
 Should not be called until after handleForComponent:. The controller will assert (if assertions are compiled), and
 return nil until `resolve` is called.
 */
@property (nonatomic, strong, readonly) ControllerType controller;

@property (nonatomic, assign, readonly) Class<CKScopedComponent> componentClass;

@property (nonatomic, strong, readonly) id state;
@property (nonatomic, readonly) CKComponentScopeHandleIdentifier globalIdentifier;

/**
 Provides a responder corresponding with this scope handle. The controller will assert if called before resolution.
 */
- (CKScopedResponder *)scopedResponder;

@end

typedef int32_t CKScopedResponderUniqueIdentifier;

@interface CKScopedResponder : NSObject

@property (nonatomic, readonly, assign) CKScopedResponderUniqueIdentifier uniqueIdentifier;

- (id)responder;

@end
