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

#import <UIKit/UIKit.h>

#import <ComponentKit/CKDataSource.h>
#import <ComponentKit/CKSupplementaryViewDataSource.h>

/**
 This class is an implementation of a `UICollectionViewDataSource` that can be used along with components. For each set of changes (i.e insertion/deletion/update
 of items and/or insertion/deletion of sections) the datasource will compute asynchronously on a background thread the corresponding component trees and then
 apply the corresponding UI changes to the collection view leveraging automatic view reuse.

 Doing so this reverses the traditional approach for a `UICollectionViewDataSource`. Usually the controller layer will *tell* the `UICollectionView` to update and
 then the `UICollectionView` *ask* the datasource for the data. Here the model is  more Reactive, from an external prospective, the datasource is *told* what
 changes to apply and then *tell* the collection view to apply the corresponding changes.
 */
@interface CKCollectionViewDataSource : NSObject

/**
 @param collectionView The collectionView is held strongly and its datasource property will be set to the receiver.
 @param supplementaryViewDataSource Will be held weakly, pass nil if you don't need supplementary views. @see the `supplementaryViewDataSource` property.
 */
- (instancetype)initWithCollectionView:(UICollectionView *)collectionView
           supplementaryViewDataSource:(id<CKSupplementaryViewDataSource>)supplementaryViewDataSource
                         configuration:(CKDataSourceConfiguration *)configuration NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

/**
 Applies a changeset either synchronously or asynchronously to the collection view.
 If a synchronous changeset is applied while asynchronous changesets are still pending, then the pending changesets will be applied synchronously
 before the new changeset is applied.
 */
- (void)applyChangeset:(CKDataSourceChangeset *)changeset
                  mode:(CKUpdateMode)mode
              userInfo:(NSDictionary *)userInfo;

/**
 @return The model associated with a certain index path in the collectionView.

 As stated above components are generated asynchronously and on a backgorund thread. This means that a changeset is enqueued
 and applied asynchronously when the corresponding component tree is generated. For this reason always use this method when you
 want to retrieve the model associated to a certain index path in the table view (e.g in didSelectRowAtIndexPath: )
 */
- (id<NSObject>)modelForItemAtIndexPath:(NSIndexPath *)indexPath;

/**
 @return The layout size of the component tree at a certain indexPath. Use this to access the component sizes for instance in a
 `UICollectionViewLayout(s)` or in a `UICollectionViewDelegateFlowLayout`.
 */
- (CGSize)sizeForItemAtIndexPath:(NSIndexPath *)indexPath;

/** @see `CKDataSource` */
- (void)reloadWithMode:(CKUpdateMode)mode
              userInfo:(NSDictionary *)userInfo;

/** @see `CKDataSource` */
- (void)updateConfiguration:(CKDataSourceConfiguration *)configuration
                       mode:(CKUpdateMode)mode
                   userInfo:(NSDictionary *)userInfo;

/**
 Sends -componentTreeWillAppear to all CKComponentControllers for the given cell.
 If needed, call this from -collectionView:willDisplayCell:forItemAtIndexPath:
 */
- (void)announceWillDisplayCell:(UICollectionViewCell *)cell;

/**
 Sends -componentTreeDidDisappear to all CKComponentControllers for the given cell.
 If needed, call this from -collectionView:didEndDisplayingCell:forItemAtIndexPath:
 */
- (void)announceDidEndDisplayingCell:(UICollectionViewCell *)cell;

@property (readonly, nonatomic, strong) UICollectionView *collectionView;
/**
 Supplementary views are not handled with components; the datasource will forward any call to
 `collectionView:viewForSupplementaryElementOfKind:atIndexPath` to this object.
 */
@property (readonly, nonatomic, weak) id<CKSupplementaryViewDataSource> supplementaryViewDataSource;

@end

#endif
