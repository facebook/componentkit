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

@class CKTransactionalComponentDataSource;
@class CKTransactionalComponentDataSourceState;
@protocol CKComponentProvider;
@protocol CKComponentStateListener;

CKTransactionalComponentDataSourceState *CKTransactionalComponentDataSourceTestState(Class<CKComponentProvider> provider,
                                                                                     id<CKComponentStateListener> listener,
                                                                                     NSUInteger numberOfSections,
                                                                                     NSUInteger numberOfItemsPerSection);

/** Returns a data source with one item and one section. */
CKTransactionalComponentDataSource *CKTransactionalComponentTestDataSource(Class<CKComponentProvider> provider);

NSDictionary *CKTestIndexPaths(NSUInteger numberOfSections, NSUInteger numberOfItemsPerSection);