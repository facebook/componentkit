/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKAsyncTransactionContainer.h>

@interface CALayer (CKAsyncTransactionContainerTransactions)
@property (nonatomic, retain, setter = ck_setAsyncLayerTransactions:) NSHashTable *ck_asyncLayerTransactions;
@property (nonatomic, retain, setter = ck_setCurrentAsyncLayerTransaction:) CKAsyncTransaction *ck_currentAsyncLayerTransaction;

- (void)ck_asyncTransactionContainerWillBeginTransaction:(CKAsyncTransaction *)transaction;
- (void)ck_asyncTransactionContainerDidCompleteTransaction:(CKAsyncTransaction *)transaction;
@end
