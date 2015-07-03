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

#import <ComponentKit/CKAsyncTransactionContainer.h>

@class CKAsyncTransaction;

/// A group of transaction container layers, for which the current transactions are committed together at the end of the next runloop tick.
@interface CKAsyncTransactionGroup : NSObject

/// The main transaction group is scheduled to commit on every tick of the main runloop.
+ (instancetype)mainTransactionGroup;

/// Add a transaction container to be committed.
/// @param containerLayer A layer containing a transaction to be commited. May or may not be a container layer.
/// @see CKAsyncTransactionContainer
- (void)addTransactionContainer:(CALayer *)containerLayer;

/// Remove a transaction container that no longer has pending transactions.
/// All layers added with addTransactionContainer: should be removed with removeTransactionContainer: once all
/// its transactions have been completed or canceled for flushPendingTransactions: to work correctly.
/// Only one call to removeTransactionContainer: is needed to remove the layer, even if addTransactionContainer:
/// has been called multiple times.
/// @param containerLayer A layer for which all transactions have been completed or canceled.
- (void)removeTransactionContainer:(CALayer *)containerLayer;

/// Force layout and display and signal when all the pending transactions have completed.
/// When the app is in background mode, UIKit suspends layout and display calls until it takes a screenshot.
/// Call flushPendingTransactions to force async layers to render and display a consistent UI for the snapshot.
/// @param completionHandler A block that is called on the main thread after all transactions have completed.
- (void)flushPendingTransactions:(dispatch_block_t)completionHandler;

@end
