/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKComponentLifecycleManager.h>

@protocol CKComponentSizeRangeProviding;

@interface CKComponentLifecycleManager (Private)

/**
 If there is a sizeRangeProvider, then every state change will be
 computed using the constraint from the sizeRangeProvider,
 allowing the state to resize if needed. Otherwise state change will
 be computed using the constraint from the previous state,
 resulting in fixed state size.
 */
- (instancetype)initWithComponentProvider:(Class<CKComponentProvider>)componentProvider
                        sizeRangeProvider:(id<CKComponentSizeRangeProviding>)sizeRangeProvider;

@end
