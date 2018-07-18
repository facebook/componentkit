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

#import <vector>

@class CKComponentScopeFrame;
@class CKComponentScopeHandle;
@class CKComponentScopeRoot;
@protocol CKComponentProtocol;

struct CKComponentScopeFramePair {
  CKComponentScopeFrame *frame;
  CKComponentScopeFrame *equivalentPreviousFrame;
};

@interface CKComponentScopeFrame : NSObject

+ (CKComponentScopeFramePair)childPairForPair:(const CKComponentScopeFramePair &)pair
                                      newRoot:(CKComponentScopeRoot *)newRoot
                               componentClass:(Class<CKComponentProtocol>)aClass
                                   identifier:(id)identifier
                                         keys:(const std::vector<id<NSObject>> &)keys
                          initialStateCreator:(id (^)(void))initialStateCreator
                                 stateUpdates:(const CKComponentStateUpdateMap &)stateUpdates;

- (instancetype)initWithHandle:(CKComponentScopeHandle *)handle;

@property (nonatomic, strong, readonly) CKComponentScopeHandle *handle;

+ (void)setAlwaysUseStateKeyCounter:(BOOL)alwaysUseStateKeyCounter;

- (size_t)childrenSize;

@end
