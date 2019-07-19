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
@protocol CKTreeNodeComponentProtocol;
@protocol CKTreeNodeProtocol;

@protocol CKComponentScopeFrameProtocol;

struct CKComponentScopeFramePair {
  id<CKComponentScopeFrameProtocol> frame;
  id<CKComponentScopeFrameProtocol> previousFrame;
};

@protocol CKComponentScopeFrameProtocol

+ (CKComponentScopeFramePair)childPairForPair:(const CKComponentScopeFramePair &)pair
                                      newRoot:(CKComponentScopeRoot *)newRoot
                               componentClass:(Class<CKComponentProtocol>)aClass
                                   identifier:(id)identifier
                                         keys:(const std::vector<id<NSObject>> &)keys
                          initialStateCreator:(id (^)(void))initialStateCreator
                                 stateUpdates:(const CKComponentStateUpdateMap &)stateUpdates;

@property (nonatomic, strong, readonly) CKComponentScopeHandle *handle;

- (size_t)childrenSize;

// Render support
+ (void)willBuildComponentTreeWithTreeNode:(id<CKTreeNodeProtocol>)node;
+ (void)didBuildComponentTreeWithNode:(id<CKTreeNodeProtocol>)node;
+ (void)didReuseRenderWithTreeNode:(id<CKTreeNodeProtocol>)node;

#if DEBUG
- (NSArray<NSString *> *)debugDescriptionComponents;
#endif

@end

@interface CKComponentScopeFrame : NSObject <CKComponentScopeFrameProtocol>

@property (nonatomic, strong, readonly) CKComponentScopeHandle *handle;

- (instancetype)initWithHandle:(CKComponentScopeHandle *)handle;

@end
