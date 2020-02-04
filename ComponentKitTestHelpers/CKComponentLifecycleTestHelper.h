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

struct CKComponentLifecycleTestHelperState {
  id model;
  id<NSObject> context;
  CKSizeRange constrainedSize;
  CKComponentLayout componentLayout;
  CKComponentScopeRoot *scopeRoot;
  CKComponentBoundsAnimation boundsAnimation;
};

// This class allows us to test Component lifecycle methods.
// It can act as Data source and attach itself to views
@interface CKComponentLifecycleTestHelper<__covariant ModelType: id<NSObject>, __covariant ContextType: id<NSObject>> : NSObject

- (instancetype)initWithComponentProvider:(CKComponent *(*)(ModelType model, ContextType context))componentProvider
                        sizeRangeProvider:(id<CKComponentSizeRangeProviding>)sizeRangeProvider NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

- (CKComponentLifecycleTestHelperState)prepareForUpdateWithModel:(ModelType)model
                                                 constrainedSize:(CKSizeRange)constrainedSize
                                                         context:(ContextType)context;

- (void)updateWithState:(const CKComponentLifecycleTestHelperState &)state;

- (void)updateWithStateWithoutMounting:(const CKComponentLifecycleTestHelperState &)state;

- (void)attachToView:(UIView *)view;

- (void)detachFromView;

- (const CKComponentLifecycleTestHelperState &)state;

@end
