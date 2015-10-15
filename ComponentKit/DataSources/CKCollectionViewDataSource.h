/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <UIKit/UIKit.h>

#import <ComponentKit/CKArrayControllerChangeset.h>
#import <ComponentKit/CKSupplementaryViewDataSource.h>

#import <ComponentKit/CKMacros.h>
#import <ComponentKit/CKDimension.h>

@protocol CKComponentProvider;
@protocol CKSupplementaryViewDataSource;

typedef void(*CKCellConfigurationFunction)(UICollectionViewCell *cell, NSIndexPath *indexPath, id<NSObject> model);

/**
 This class is an implementation of a `UICollectionViewDataSource` that can be used along with components. For each set of changes (i.e insertion/deletion/update
 of items and/or insertion/deletion of sections) the datasource will compute asynchronously on a background thread the corresponding component trees and then
 apply the corresponding UI changes to the collection view leveraging automatically view reuse.
 
 Doing so this reverses the traditional approach for a `UICollectionViewDataSource`. Usually the controller layer will *tell* the `UICollectionView` to update and
 then the `UICollectionView` *ask* the datasource for the data. Here the model is  more Reactive, from an external prospective, the datasource is *told* what
 changes to apply and then *tell* the collection view to apply the corresponding changes.
 */
@interface CKCollectionViewDataSource : NSObject

/**
 Designated initializer
 
 @param supplementaryViewDataSource @see the `supplementaryViewDataSource` property. Will be held weakly, pass nil if you don't need supplementary views.
 @param componentProvider Class implementing the pure function turning a model into components.@see CKComponentProvider.
 @param context Will be passed to your componentProvider. @see CKComponentProvider.
 @param cellConfigurationFunction Pointer to a function applying custom configuration to the UICollectionViewCell where the component
 tree is mounted. We use a function pointer and not a block to enforce the purity of said function.
 @warning Reuse won't be handled for you when modifying view parameters through this function, reserve it for small configurations.
 */
- (instancetype)initWithCollectionView:(UICollectionView *)collectionView
           supplementaryViewDataSource:(id<CKSupplementaryViewDataSource>)supplementaryViewDataSource
                     componentProvider:(Class<CKComponentProvider>)componentProvider
                               context:(id<NSObject>)context
             cellConfigurationFunction:(CKCellConfigurationFunction)cellConfigurationFunction;

/**
 Method to enqueue commands in the datasource.
 
 @param changeset The set of commands to apply to the collection view, e.g :
 `
 CKArrayControllerSections sections;
 CKArrayControllerInputItems items;
 sections.insert(1); // Insert section at index 1
 items.insert({1,0}, modelX); // Insert a row at index 0 in section 1 containing the UI corresponding to modelX
 item.update({0,0}, modelY); // Update row at index 0 in section 0 using modelY
 [_dataSource enqueueChangeset:{sections, items} constrainedSize:{{0,0},{50,50}}];
 
 @warning In a batch update:
 - deletes are applied first relatively to the index space before the batch update
 - inserts are then applied relatively to the "post deletion" index space:
 https://developer.apple.com/library/ios/documentation/UIKit/Reference/UICollectionView_class/#//apple_ref/occ/instm/UICollectionView/performBatchUpdates:completion:
 `
 @param constrainedSize The constrained size {{minWidth, minHeight},{maxWidth, maxHeight}} that will be used to compute
 your component tree.
 */
- (void)enqueueChangeset:(const CKArrayControllerInputChangeset &)changeset
         constrainedSize:(const CKSizeRange &)constrainedSize;

/**
 Updates context to the new value and enqueues update changeset in order to rebuild component tree.
 */
- (void)updateContextAndEnqueueReload:(id)newContext;

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

/**
 Sends -componentTreeWillAppear to all CKComponentControllers for the given cell.
 If needed, call this from -collectionView:willDisplayCell:forItemAtIndexPath:
 */
- (void)announceWillAppearForItemInCell:(UICollectionViewCell *)cell;

/**
 Sends -componentTreeDidDisappear to all CKComponentControllers for the given cell.
 If needed, call this from -collectionView:didEndDisplayingCell:forItemAtIndexPath:
 */
- (void)announceDidDisappearForItemInCell:(UICollectionViewCell *)cell;

@property (readonly, nonatomic, strong) UICollectionView *collectionView;
/**
 Supplementary views are not handled with components; the datasource will forward any call to
 `collectionView:viewForSupplementaryElementOfKind:atIndexPath` to this object.
 */
@property (readonly, nonatomic, weak) id<CKSupplementaryViewDataSource> supplementaryViewDataSource;

- (instancetype)init CK_NOT_DESIGNATED_INITIALIZER_ATTRIBUTE;

@end

