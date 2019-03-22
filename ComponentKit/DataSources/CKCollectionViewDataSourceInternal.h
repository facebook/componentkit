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

@class CKDataSource;
@class CKDataSourceState;
@protocol CKCollectionViewDataSourceListener;

@interface CKCollectionViewDataSource ()

/**
 The underlying `CKDataSource` that `CKCollectionViewDataSource` is holding. @see CKDataSource
 A new instance of `componentDataSource` will be created if a new state is set to `CKCollectionViewDataSource`.
 */
@property (nonatomic, readonly, strong) CKDataSource *componentDataSource;

/**
 Set a new `CKDataSourceState` and reload data of the underlying collection view.
 A new instance of `componentDataSource` will be created.
 */
- (void)setState:(CKDataSourceState *)state;

- (void)addListener:(id<CKCollectionViewDataSourceListener>)listener;
- (void)removeListener:(id<CKCollectionViewDataSourceListener>)listener;

@end
