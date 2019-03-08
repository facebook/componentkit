/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKCollectionViewDataSource.h>

@protocol CKDataSourceListener;
@class CKDataSourceChange;

@interface CKCollectionViewDataSource ()

/**
 Apply a pre-computed `CKDataSourceChange` to the datasource.
 `NO` will be returned if the change is computed based on a outdated state.
 @param change pre-computed `CKDataSourceChange`
 @return YES if the applied change is legit.
 */
- (BOOL)applyChange:(CKDataSourceChange *)change;

- (void)addListener:(id<CKDataSourceListener>)listener;
- (void)removeListener:(id<CKDataSourceListener>)listener;

@end
