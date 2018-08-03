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

#import <ComponentKit/CKAnimationApplicator.h>
#import <ComponentKit/CKComponentDataSourceAttachController.h>
#import <ComponentKit/CKComponentScopeTypes.h>

/** This is exposed for unit tests. */
@interface CKComponentDataSourceAttachState : NSObject

@property (nonatomic, strong, readonly) NSSet *mountedComponents;
@property (nonatomic, readonly) CKComponentScopeRootIdentifier scopeIdentifier;

- (instancetype)initWithScopeIdentifier:(CKComponentScopeRootIdentifier)scopeIdentifier
                      mountedComponents:(NSSet *)mountedComponents
                    animationApplicator:(const std::shared_ptr<CK::AnimationApplicator<CK::ComponentAnimationsController>> &)animationApplicator;

- (const std::shared_ptr<CK::AnimationApplicator<CK::ComponentAnimationsController>> &)animationApplicator;

@end

const CKComponentRootLayout &CKComponentDataSourceAttachStateRootLayout(const CKComponentDataSourceAttachState *const self);
void CKComponentDataSourceAttachStateSetRootLayout(CKComponentDataSourceAttachState *const self, const CKComponentRootLayout &rootLayout);

@interface CKComponentDataSourceAttachController ()

- (CKComponentDataSourceAttachState *)attachStateForScopeIdentifier:(CKComponentScopeRootIdentifier)scopeIdentifier;

@end

@interface UIView (CKComponentDataSourceAttachController)

@property (nonatomic, strong, setter=ck_setAttachState:) CKComponentDataSourceAttachState *ck_attachState;

@end
