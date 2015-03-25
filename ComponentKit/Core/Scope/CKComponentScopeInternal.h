/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant 
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <unordered_map>
#import <vector>

#import <ComponentKit/CKComponentBoundsAnimation.h>
#import <ComponentKit/CKComponentScope.h>
#import <ComponentKit/CKComponentScopeFrame.h>

@class CKComponent;

@class CKComponentScopeFrame;

@protocol CKComponentStateListener <NSObject>
- (void)componentStateDidEnqueueStateModificationWithTryAsynchronousUpdate:(BOOL)tryAsynchronousUpdate;
@end

struct CKBuildComponentResult {
  CKComponent *component;
  CKComponentScopeFrame *scopeFrame;
  CKComponentBoundsAnimation boundsAnimation;
};

CKBuildComponentResult CKBuildComponent(id<CKComponentStateListener> listener,
                                        CKComponentScopeFrame *previousRootFrame,
                                        CKComponent *(^function)(void));

/**
 This is only meant to be called when constructing a component and as part of the implementation
 itself. This method looks to see if the currently defined scope matches that of the argument and
 if so it returns the state-scope frame corresponding to the current scope. Otherwise it returns nil.
 */
CKComponentScopeFrame *CKComponentScopeFrameForComponent(CKComponent *component);
