/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <UIKit/UIKit.h>

#import <ComponentKit/CKComponentBoundsAnimation.h>
#import <ComponentKit/CKComponentScope.h>

@class CKComponent;
@class CKComponentController;
@protocol CKComponentStateListener;

typedef NS_ENUM(NSUInteger, CKComponentAnnouncedEvent) {
  CKComponentAnnouncedEventTreeWillAppear,
  CKComponentAnnouncedEventTreeDidDisappear,
};

@interface CKComponentScopeFrame : NSObject

+ (int32_t)nextGlobalIdentifier;

/**
 Construct a state-scope frame with a given listener.
 This is the only way to create a root-frame since the other constructor
 derives a name frame within the scope of the given parent.
 */
+ (instancetype)rootFrameWithListener:(id<CKComponentStateListener>)listener
                     globalIdentifier:(int32_t)globalIdentifier;

/**
 Create a new child state-scope frame resident within the scope of parent. This
 will modify the state-scope tree so that parent[key] = theNewFrame.
 */
- (instancetype)childFrameWithComponentClass:(Class __unsafe_unretained)aClass
                                  identifier:(id)identifier
                                       state:(id)state
                                  controller:(CKComponentController *)controller
                            globalIdentifier:(int32_t)globalIdentifier;

@property (nonatomic, readonly, weak) id<CKComponentStateListener> listener;
@property (nonatomic, readonly, strong) Class componentClass;
@property (nonatomic, readonly, strong) id identifier;
@property (nonatomic, readonly, strong) id state;
@property (nonatomic, readonly, strong) CKComponentController *controller;
@property (nonatomic, readonly, assign) int32_t globalIdentifier;

@property (nonatomic, readonly, strong) id updatedState;

/**
 These are to prevent a component from potentially acquiring the state of a
 parent component (since they might have the same class). We mark the state
 as acquired and pass a reference to the component to assist in debugging.
 */
- (void)markAcquiredByComponent:(CKComponent *)component;

@property (nonatomic, readonly) BOOL acquired;
@property (nonatomic, readonly, weak) CKComponent *owningComponent;

- (CKComponentScopeFrame *)existingChildFrameWithClass:(Class __unsafe_unretained)aClass identifier:(id)identifier;

- (void)updateState:(id (^)(id))updateFunction tryAsynchronousUpdate:(BOOL)tryAsynchronousUpdate;

/** For internal use only; sends the given event to all component controllers that implement it. */
- (void)announceEventToControllers:(CKComponentAnnouncedEvent)event;

/**
 For internal use only; when called on the root frame, returns all contained components that override
 -boundsAnimationFromPreviousComponent:.
 */
- (NSHashTable *)boundsAnimationComponents;

- (CKComponentBoundsAnimation)boundsAnimationFromPreviousRootScopeFrame:(CKComponentScopeFrame *)previousRoot;

@end
