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

#import <ComponentKit/CKComponentProvider.h>
#import <ComponentKit/CKComponentEvents.h>
#import <ComponentKit/CKDataSource.h>
#import <ComponentKit/CKDataSourceConfigurationInternal.h>

@class CKDataSourceState;
@protocol CKComponentStateListener;
@protocol CKDataSourceListener;

CKDataSourceState *CKDataSourceTestState(CKComponentProviderFunc provider,
                                         id<CKComponentStateListener> listener,
                                         NSUInteger numberOfSections,
                                         NSUInteger numberOfItemsPerSection);

/** Returns a data source with one item and one section. */
CKDataSource *CKComponentTestDataSource(CKComponentProviderFunc provider,
                                        id<CKDataSourceListener> listener,
                                        CKDataSourceOptions options = {});

NSSet *CKTestIndexPaths(NSUInteger numberOfSections, NSUInteger numberOfItemsPerSection);
