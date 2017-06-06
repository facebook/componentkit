/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKTransactionalComponentDataSourceConfiguration.h>

@interface CKTransactionalComponentDataSourceConfiguration ()

/**
 @param componentProvider See @protocol(CKComponentProvider)
 @param context Passed to methods exposed by @protocol(CKComponentProvider).
 @param sizeRange Used for the root layout.
 @param workThreadOverride The optional thread used by the data source to perform its work instead of the internal
                           dispatch queue; if provided this thread must be executing.
 */
- (instancetype)initWithComponentProvider:(Class<CKComponentProvider>)componentProvider
                                  context:(id<NSObject>)context
                                sizeRange:(const CKSizeRange &)sizeRange
                       workThreadOverride:(NSThread *)workThreadOverride;

@property (nonatomic, strong, readonly) NSThread *workThreadOverride;

@end
