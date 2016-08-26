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
#import <ComponentKit/CKUpdateMode.h>

@class CKComponent;
@class CKComponentController;
@class CKComponentScopeRoot;

@protocol CKComponentStateListener;

@interface CKComponentScopeHandle : NSObject

/**
 This method looks to see if the currently defined scope matches that of the given component; if so it returns the
 handle corresponding to the current scope. Otherwise it returns nil.
 This is only meant to be called when constructing a component and as part of the implementation itself.
 */
+ (instancetype)handleForComponent:(CKComponent *)component;

/** Creates a conceptually brand new scope handle */
- (instancetype)initWithListener:(id<CKComponentStateListener>)listener
                  rootIdentifier:(CKComponentScopeRootIdentifier)rootIdentifier
                  componentClass:(Class)componentClass
             initialStateCreator:(id (^)(void))initialStateCreator;

/** Creates a new instance of the scope handle that incorporates the given state updates. */
- (instancetype)newHandleWithStateUpdates:(const CKComponentStateUpdateMap &)stateUpdates;

/** Creates a new, but identical, instance of the scope handle that will be reacquired due to a scope collision. */
- (instancetype)newHandleToBeReacquiredDueToScopeCollision;

- (void)updateState:(id (^)(id))updateFunction mode:(CKUpdateMode)mode;

/** Informs the scope handle that it should complete its configuration. This will generate the controller */
- (void)resolve;

/**
 Should not be called until after handleForComponent:. The controller will assert (if assertions are compiled), and
 return nil until `resolve` is called.
 */
@property (nonatomic, strong, readonly) CKComponentController *controller;
@property (nonatomic, strong, readonly) id state;
@property (nonatomic, readonly) CKComponentScopeHandleIdentifier globalIdentifier;

@end
