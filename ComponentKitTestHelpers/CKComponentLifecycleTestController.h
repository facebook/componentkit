/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKComponentBoundsAnimation.h>
#import <ComponentKit/CKComponentLayout.h>
#import <ComponentKit/CKDimension.h>

@class CKComponentScopeRoot;

@protocol CKComponentProvider;
@protocol CKComponentSizeRangeProviding;

struct CKComponentLifecycleTestControllerState {
  id model;
  id<NSObject> context;
  CKSizeRange constrainedSize;
  CKComponentLayout componentLayout;
  CKComponentScopeRoot *scopeRoot;
  CKComponentBoundsAnimation boundsAnimation;
};

@interface CKComponentLifecycleTestController : NSObject

- (instancetype)initWithComponentProvider:(Class<CKComponentProvider>)componentProvider
                        sizeRangeProvider:(id<CKComponentSizeRangeProviding>)sizeRangeProvider NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

- (CKComponentLifecycleTestControllerState)prepareForUpdateWithModel:(id)model
                                                     constrainedSize:(CKSizeRange)constrainedSize
                                                             context:(id<NSObject>)context;

- (void)updateWithState:(const CKComponentLifecycleTestControllerState &)state;

- (void)updateWithStateWithoutMounting:(const CKComponentLifecycleTestControllerState &)state;

- (void)attachToView:(UIView *)view;

- (void)detachFromView;

- (const CKComponentLifecycleTestControllerState &)state;

@end
