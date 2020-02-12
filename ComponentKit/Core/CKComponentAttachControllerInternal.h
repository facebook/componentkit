/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKDefines.h>

#if CK_NOT_SWIFT

#import <Foundation/Foundation.h>

#import <ComponentKit/CKAnimationApplicator.h>
#import <ComponentKit/CKComponentAttachController.h>
#import <ComponentKit/CKComponentScopeTypes.h>
#import <ComponentKit/CKNonNull.h>

@protocol CKComponentRootLayoutProvider;

/** This is exposed for unit tests. */
@interface CKComponentAttachState : NSObject

@property (nonatomic, assign, readonly) CK::NonNull<NSSet *> mountedComponents;
@property (nonatomic, readonly) CKComponentScopeRootIdentifier scopeIdentifier;

- (instancetype)initWithScopeIdentifier:(CKComponentScopeRootIdentifier)scopeIdentifier
                      mountedComponents:(CK::NonNull<NSSet *>)mountedComponents
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

/**
 Update root view host according to given root view category by trying to retrieve a root view from root view pool
 of `attachController`. `rootView` and `rootViewCategory` of root view host will be updated if the given `rootViewCategory`
 is different from the existing `rootViewCategory`.
 @param rootViewHost The host of root view that its root view can be replaced based on its category.
 @param rootViewCategory Category of the root view which will be used for retrieving a root view from root view pool.
 @param attachController The `CKComponentAttachController` that is used for detaching components from the existing
 root view if it's going to be replaced.
 */
auto CKUpdateComponentRootViewHost(CK::NonNull<id<CKComponentRootViewHost>> rootViewHost,
                                   CK::NonNull<NSString *> rootViewCategory,
                                   CK::NonNull<CKComponentAttachController *> attachController) -> void;

#endif
