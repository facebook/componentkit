/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKComponent.h>

@interface CKAnimationController : NSObject

- (void)componentWillStartMounting:(CKComponent * const _Nonnull)component;
- (void)componentWillStartRemounting:(CKComponent * const _Nonnull)component
                   previousComponent:(CKComponent * const _Nullable)prevComponent;
- (void)componentDidMount;
- (void)componentWillUnmount;
- (void)componentWillRelinquishView;

@end
