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

#import <ComponentKit/CKComponentProvider.h>
#import <RenderCore/RCDimension.h>

/** Immutable value object that configures a data source */
@interface CKDataSourceConfiguration<__covariant ModelType: id<NSObject>, __covariant ContextType: id<NSObject>> : NSObject

/**
 @param componentProvider A function that generates the root component.
 @param context Passed to the component provider.
 @param sizeRange Used for the root layout.
 */
- (instancetype)initWithComponentProviderFunc:(CKComponent *(*)(ModelType model, ContextType context))componentProvider
                                      context:(id<NSObject>)context
                                    sizeRange:(const CKSizeRange &)sizeRange;

@property (nonatomic, strong, readonly) ContextType context;

- (const CKSizeRange &)sizeRange;

/** Guaranteed to be non-null. (A dummy provider is substituted if necessary.) */
- (CKComponentProviderFunc)componentProvider;
- (BOOL)hasSameComponentProviderAndContextAs:(CKDataSourceConfiguration *)other;

@end

#endif
