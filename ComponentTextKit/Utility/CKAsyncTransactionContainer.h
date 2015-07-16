/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant 
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

@class CKAsyncTransaction;

typedef NS_ENUM(NSUInteger, CKAsyncTransactionContainerState) {
  /**
   The async container has no outstanding transactions.
   Whatever it is displaying is up-to-date.
   */
  CKAsyncTransactionContainerStateNoTransactions = 0,
  /**
   The async container has one or more outstanding async transactions.
   Its contents may be out of date or showing a placeholder, depending on the configuration of the contained CKAsyncLayers.
   */
  CKAsyncTransactionContainerStatePendingTransactions,
};

@protocol CKAsyncTransactionContainer

/**
 @summary If YES, the receiver is marked as a container for async display, grouping all of the async display calls
 in the layer hierarchy below the receiver together in a single CKAsyncTransaction.

 @default NO
 */
@property (nonatomic, assign, getter = ck_isAsyncTransactionContainer, setter = ck_setAsyncTransactionContainer:) BOOL ck_asyncTransactionContainer;

/**
 @summary The current state of the receiver; indicates if it is currently performing asynchronous operations or if all operations have finished/canceled.
 */
@property (nonatomic, assign, readonly) CKAsyncTransactionContainerState ck_asyncTransactionContainerState;

/**
 @summary Cancels all async transactions on the receiver.
 */
- (void)ck_cancelAsyncTransactions;

/**
 @summary Invoked when the ck_asyncTransactionContainerState property changes.
 @desc You may want to override this in a CALayer or UIView subclass to take appropriate action (such as hiding content while it renders).
 */
- (void)ck_asyncTransactionContainerStateDidChange;

@end

@interface CALayer (CKAsyncTransactionContainer) <CKAsyncTransactionContainer>
/**
 @summary Returns the current async transaction for this container layer. A new transaction is created if one
 did not already exist. This method will always return an open, uncommitted transaction.
 @desc ck_isAsyncTransactionContainer does not need to be YES for this to return a transaction.
 */
@property (nonatomic, retain, readonly) CKAsyncTransaction *ck_asyncTransaction;

/**
 @summary Goes up the superlayer chain until it finds the first layer with ck_isAsyncTransactionContainer=YES (including the receiver) and returns it.
 Returns nil if no parent container is found.
 */
@property (nonatomic, retain, readonly) CALayer *ck_parentTransactionContainer;
@end

@interface UIView (CKAsyncTransactionContainer) <CKAsyncTransactionContainer>
@end
