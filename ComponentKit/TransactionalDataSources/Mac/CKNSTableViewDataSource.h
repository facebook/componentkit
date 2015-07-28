/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <Cocoa/Cocoa.h>

#import <ComponentKit/CKPlatform.h>


#import <ComponentKit/CKMacros.h>
#import <ComponentKit/CKDimension.h>

#import <ComponentKit/CKTransactionalComponentDataSource.h>

@protocol CKComponentProvider;
@class CKTransactionalComponentDataSourceChangeset;

/**
 This class is an implementation of a `NSTableViewDataSource` and `NSTableViewDataDelegate` that can be used along with components. For each set of changes (i.e insertion/deletion/update
 of items and/or insertion/deletion of sections) the datasource will compute asynchronously on a background thread the corresponding component trees and then
 apply the corresponding UI changes to the table view leveraging automatically view reuse.
 
 Doing so this reverses the traditional approach for a `NSTableViewDataSource`. Usually the controller layer will *tell* the `NSTableView` to update and
 then the `NSTableView` *ask* the datasource for the data. Here the model is more Reactive, from an external prospective, the datasource is *told* what
 changes to apply and then *tell* the collection view to apply the corresponding changes.
 */
@interface CKNSTableViewDataSource : NSObject <NSTableViewDataSource, NSTableViewDelegate>

/**
 Designated initializer.

 
 @param componentProvider Class implementing the pure function turning a model into components.@see CKComponentProvider.
 @param context Will be passed to your componentProvider. @see CKComponentProvider.
 */
- (instancetype)initWithTableView:(NSTableView *)tableView
                componentProvider:(Class<CKComponentProvider>)componentProvider
                          context:(id<NSObject>)context;


/**
 * At the moment, is verboten to add more than one section (any beyond the first will not be displayed).
 * In the future, we could add multi-section emulation and add floating separators a la UITableView.
 */
- (void)applyChangeset:(CKTransactionalComponentDataSourceChangeset *)changeset
                  mode:(CKUpdateMode)mode
              userInfo:(NSDictionary *)userInfo;

/**
 Updates context to the new value and enqueues update changeset in order to rebuild component tree.
 */
//TODO: - (void)updateContextAndEnqeueReload:(id)newContext;

/**
 @return The model associated with a certain index path in the collectionView.
 
 As stated above components are generated asynchronously and on a background thread. This means that a changeset is enqueued
 and applied asynchronously when the corresponding component tree is generated. For this reason always use this method when you
 want to retrieve the model associated to a certain index path in the table view (e.g in didSelectRowAtIndexPath: )
 */
- (id<NSObject>)modelForRow:(NSInteger)rowIndex;

/**
 @return The layout size of the component tree at a certain indexPath. Use this to access the component sizes for instance in a
 `UICollectionViewLayout(s)` or in a `UICollectionViewDelegateFlowLayout`.
 */
- (CGFloat)heightForRow:(NSInteger)rowIndex;

@property (readonly, nonatomic, strong) NSTableView *tableView;

- (instancetype)init CK_NOT_DESIGNATED_INITIALIZER_ATTRIBUTE;

@end
