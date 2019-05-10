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
#import <ComponentKit/CKComponentAttachController.h>
#import <ComponentKit/CKComponentScopeTypes.h>

@protocol CKComponentRootLayoutProvider;

/** This is exposed for unit tests. */
@interface CKComponentAttachState : NSObject

@property (nonatomic, strong, readonly) NSSet *mountedComponents;
@property (nonatomic, readonly) CKComponentScopeRootIdentifier scopeIdentifier;

- (instancetype)initWithScopeIdentifier:(CKComponentScopeRootIdentifier)scopeIdentifier
                      mountedComponents:(NSSet *)mountedComponents
                    animationApplicator:(const std::shared_ptr<CK::AnimationApplicator<>> &)animationApplicator;

- (const std::shared_ptr<CK::AnimationApplicator<>> &)animationApplicator;

@end

const CKComponentRootLayout &CKComponentAttachStateRootLayout(const CKComponentAttachState *const self);
void CKComponentAttachStateSetRootLayout(CKComponentAttachState *const self, const CKComponentRootLayout &rootLayout);

@interface CKComponentAttachController ()

- (CKComponentAttachState *)attachStateForScopeIdentifier:(CKComponentScopeRootIdentifier)scopeIdentifier;
- (id<CKComponentRootLayoutProvider>)layoutProviderForScopeIdentifier:(CKComponentScopeRootIdentifier)scopeIdentifier;

@end

auto CKGetAttachStateForView(UIView *view) -> CKComponentAttachState *;
auto CKSetAttachStateForView(UIView *view, CKComponentAttachState *attachState) -> void;
