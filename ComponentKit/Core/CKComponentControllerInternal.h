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

#import <UIKit/UIKit.h>

#import <ComponentKit/CKComponentController.h>

@interface CKComponentController ()

/**
 The latest generation of component. This makes sure `self.component` is always
 referring to the latest generation of component when components are managed by
 `CKDataSource`.
 */
@property (nonatomic, weak) CKComponent *latestComponent;

/**
 Provides a thread safe access to underlying component.
 This should only be used by ComponentKit infra in a very rare case.
 */
- (CKComponent *)threadSafe_component;

/**
 This gives us the ability to avoid acquiring lock when `threadSafe_component` is not needed.
 */
+ (BOOL)shouldAcquireLockWhenUpdatingComponent;

- (void)componentWillMount:(CKComponent *)component;
- (void)componentDidMount:(CKComponent *)component;
- (void)componentWillUnmount:(CKComponent *)component;
- (void)componentDidUnmount:(CKComponent *)component;
- (void)component:(CKComponent *)component willRelinquishView:(UIView *)view;
- (void)component:(CKComponent *)component didAcquireView:(UIView *)view;

@end

#endif
