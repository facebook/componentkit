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

#import <ComponentKit/CKDimension.h>

@protocol CKComponentProvider;

/** Immutable value object that configures a data source */
@interface CKTransactionalComponentDataSourceConfiguration : NSObject

/**
 @param componentProvider See @protocol(CKComponentProvider)
 @param context Passed to methods exposed by @protocol(CKComponentProvider).
 @param sizeRange Used for the root layout.
 */
- (instancetype)initWithComponentProvider:(Class<CKComponentProvider>)componentProvider
                                  context:(id<NSObject>)context
                                sizeRange:(const CKSizeRange &)sizeRange;

/**
 @param componentProvider See @protocol(CKComponentProvider)
 @param context Passed to methods exposed by @protocol(CKComponentProvider).
 @param sizeRange Used for the root layout.
 @param alwaysSendComponentUpdate If set to YES, CKTransactionalComponentDataSource with this config
        will send component update events to component controllers even when they aren't in viewport
 */
- (instancetype)initWithComponentProvider:(Class<CKComponentProvider>)componentProvider
                                  context:(id<NSObject>)context
                                sizeRange:(const CKSizeRange &)sizeRange
                alwaysSendComponentUpdate:(BOOL)alwaysSendComponentUpdate;

@property (nonatomic, strong, readonly) Class<CKComponentProvider> componentProvider;
@property (nonatomic, strong, readonly) id<NSObject> context;
@property (nonatomic, assign, readonly) BOOL alwaysSendComponentUpdate;

- (const CKSizeRange &)sizeRange;

@end
