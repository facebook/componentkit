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

#import <ComponentKit/CKComponentController.h>

@interface CKComponentController ()

- (void)componentWillMount:(CKComponent *)component;
- (void)componentDidMount:(CKComponent *)component;
- (void)componentWillUnmount:(CKComponent *)component;
- (void)componentDidUnmount:(CKComponent *)component;
- (void)component:(CKComponent *)component willRelinquishView:(UIView *)view;
- (void)component:(CKComponent *)component didAcquireView:(UIView *)view;

@end
