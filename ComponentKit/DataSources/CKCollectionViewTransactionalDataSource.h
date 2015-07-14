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

#import "CKTransactionalComponentDataSource.h"

/**
 This class is an implementation of a `UICollectionViewDataSource` that can be used along with components. For each set of changes (i.e insertion/deletion/update
 of items and/or insertion/deletion of sections) the datasource will compute asynchronously on a background thread the corresponding component trees and then
 apply the corresponding UI changes to the collection view leveraging automatically view reuse.
 
 Doing so this reverses the traditional approach for a `UICollectionViewDataSource`. Usually the controller layer will *tell* the `UICollectionView` to update and
 then the `UICollectionView` *ask* the datasource for the data. Here the model is  more Reactive, from an external prospective, the datasource is *told* what
 changes to apply and then *tell* the collection view to apply the corresponding changes.
 */
@interface CKCollectionViewTransactionalDataSource : NSObject

/**
 @param collectionView The collectionView is held strongly and its datasource property will be set to the receiver.
 */
- (instancetype)initWithCollectionView:(UICollectionView *)collectionView
                         configuration:(CKTransactionalComponentDataSourceConfiguration *)configuration NS_DESIGNATED_INITIALIZER;

/** 
 Applies a changeset either synchronously or asynchronously to the collection view.
 If a synchronous changeset is applied while asynchronous changesets are still pending, then the pending changesets will be applied synchronously
 before the new changeset is applied.
 */
- (void)applyChangeset:(CKTransactionalComponentDataSourceChangeset *)changeset
                  mode:(CKUpdateMode)mode
              userInfo:(NSDictionary *)userInfo;

/**
 @return The layout size of the component tree at a certain indexPath. Use this to access the component sizes for instance in a
 `UICollectionViewLayout(s)` or in a `UICollectionViewDelegateFlowLayout`.
 */
- (CGSize)sizeForItemAtIndexPath:(NSIndexPath *)indexPath;

/** @see `CKTransactionalComponentDataSource` */
- (void)reloadWithMode:(CKUpdateMode)mode
              userInfo:(NSDictionary *)userInfo;

/** @see `CKTransactionalComponentDataSource` */
- (void)updateConfiguration:(CKTransactionalComponentDataSourceConfiguration *)configuration
                       mode:(CKUpdateMode)mode
                   userInfo:(NSDictionary *)userInfo;

@property (readonly, nonatomic, strong) UICollectionView *collectionView;

@end