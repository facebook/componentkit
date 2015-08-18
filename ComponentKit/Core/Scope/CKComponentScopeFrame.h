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

#import <ComponentKit/CKComponentScopeTypes.h>

@class CKComponentScopeFrame;
@class CKComponentScopeHandle;
@class CKComponentScopeRoot;

struct CKComponentScopeFramePair {
  CKComponentScopeFrame *frame;
  CKComponentScopeFrame *equivalentPreviousFrame;
};

@interface CKComponentScopeFrame : NSObject

+ (CKComponentScopeFramePair)childPairForPair:(const CKComponentScopeFramePair &)pair
                                      newRoot:(CKComponentScopeRoot *)newRoot
                               componentClass:(Class)componentClass
                                   identifier:(id)identifier
                          initialStateCreator:(id (^)(void))initialStateCreator
                                 stateUpdates:(const CKComponentStateUpdateMap &)stateUpdates;

- (instancetype)initWithHandle:(CKComponentScopeHandle *)handle;

@property (nonatomic, strong, readonly) CKComponentScopeHandle *handle;

struct _CKChildScopeFrameRet {
  Class cls;
  id identifier;
  CKComponentScopeFrame *frame;
};

- (_CKChildScopeFrameRet)childScopeFrameForOldIdentifier:(CKComponentScopeHandleIdentifier)globalIdentifier;

- (void)injectScopeHierarchy:(_CKChildScopeFrameRet)oldFrame;

- (BOOL)anyDescendentHasPendingUpdates:(const CKComponentStateUpdateMap &)stateUpdates;

@end
