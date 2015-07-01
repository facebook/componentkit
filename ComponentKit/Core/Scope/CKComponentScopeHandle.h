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
 This is only meant to be called when constructing a component and as part of the implementation
 itself. This method looks to see if the currently defined scope matches that of the argument and
 if so it returns the state-scope frame corresponding to the current scope. Otherwise it returns nil.
 */
+ (instancetype)handleForComponent:(CKComponent *)component;

/** Creates a conceptually brand new scope handle */
- (instancetype)initWithListener:(id<CKComponentStateListener>)listener
                  rootIdentifier:(CKComponentScopeRootIdentifier)rootIdentifier
                  componentClass:(Class)componentClass
             initialStateCreator:(id (^)(void))initialStateCreator;

/** Creates a new version of an existing scope handle that incorporates the given state updates */
- (instancetype)newHandleWithStateUpdates:(const CKComponentStateUpdateMap &)stateUpdates;

@property (nonatomic, strong, readonly) CKComponentController *controller;
@property (nonatomic, strong, readonly) id state;
@property (nonatomic, readonly) CKComponentScopeHandleIdentifier globalIdentifier;

- (void)updateState:(id (^)(id))updateFunction mode:(CKUpdateMode)mode;

@end
