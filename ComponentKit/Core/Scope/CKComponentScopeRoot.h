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

#import <ComponentKit/CKComponentBoundsAnimation.h>
#import <ComponentKit/CKComponentScopeTypes.h>
#import <ComponentKit/CKUpdateMode.h>

@class CKComponent;
@class CKComponentScopeFrame;
@class CKComponentScopeRoot;

typedef NS_ENUM(NSUInteger, CKComponentAnnouncedEvent) {
  CKComponentAnnouncedEventTreeWillAppear,
  CKComponentAnnouncedEventTreeDidDisappear,
};

@protocol CKComponentStateListener <NSObject>
/** Always sent on the main thread. */
- (void)componentScopeHandleWithIdentifier:(CKComponentScopeHandleIdentifier)globalIdentifier
                            rootIdentifier:(CKComponentScopeRootIdentifier)rootIdentifier
                     didReceiveStateUpdate:(id (^)(id))stateUpdate
                                      mode:(CKUpdateMode)mode;
@end

struct CKBuildComponentResult {
  CKComponent *component;
  CKComponentScopeRoot *scopeRoot;
  CKComponentBoundsAnimation boundsAnimation;
};

CKBuildComponentResult CKBuildComponent(CKComponentScopeRoot *previousRoot,
                                        const CKComponentStateUpdateMap &stateUpdates,
                                        CKComponent *(^function)(void));

@interface CKComponentScopeRoot : NSObject

/** Creates a conceptually brand new scope root */
+ (instancetype)rootWithListener:(id<CKComponentStateListener>)listener;

/** Creates a new version of an existing scope root, ready to be used for building a component tree */
- (instancetype)newRoot;

/** Sends the given event to all component controllers that implement it. */
- (void)announceEventToControllers:(CKComponentAnnouncedEvent)event;

- (CKComponentBoundsAnimation)boundsAnimationFromPreviousScopeRoot:(CKComponentScopeRoot *)previousRoot;

@property (nonatomic, weak, readonly) id<CKComponentStateListener> listener;
@property (nonatomic, readonly) CKComponentScopeRootIdentifier globalIdentifier;
@property (nonatomic, strong, readonly) CKComponentScopeFrame *rootFrame;

@end
