/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKAsyncTransactionContainer+Private.h"

#import <ComponentKit/CKAssert.h>

#import "CKAsyncTransaction.h"
#import "CKAsyncTransactionGroup.h"

#import <objc/runtime.h>

@implementation CALayer (CKAsyncTransactionContainerTransactions)
@dynamic ck_asyncLayerTransactions;
@dynamic ck_currentAsyncLayerTransaction;

// No-ops in the base class. Mostly exposed for testing.
- (void)ck_asyncTransactionContainerWillBeginTransaction:(CKAsyncTransaction *)transaction {}
- (void)ck_asyncTransactionContainerDidCompleteTransaction:(CKAsyncTransaction *)transaction {}
@end

@implementation CALayer (CKAsyncTransactionContainer)

@dynamic ck_asyncTransactionContainer;

- (CKAsyncTransactionContainerState)ck_asyncTransactionContainerState
{
  return ([self.ck_asyncLayerTransactions count] == 0) ? CKAsyncTransactionContainerStateNoTransactions : CKAsyncTransactionContainerStatePendingTransactions;
}

- (void)ck_cancelAsyncTransactions
{
  // If there was an open transaction, commit and clear the current transaction. Otherwise:
  // (1) The run loop observer will try to commit a canceled transaction which is not allowed
  // (2) We leave the canceled transaction attached to the layer, dooming future operations
  CKAsyncTransaction *currentTransaction = self.ck_currentAsyncLayerTransaction;
  [currentTransaction commit];
  self.ck_currentAsyncLayerTransaction = nil;

  for (CKAsyncTransaction *transaction in [self.ck_asyncLayerTransactions copy]) {
    [transaction cancel];
  }
}

- (void)ck_asyncTransactionContainerStateDidChange
{
  id delegate = self.delegate;
  if ([delegate respondsToSelector:@selector(ck_asyncTransactionContainerStateDidChange)]) {
    [delegate ck_asyncTransactionContainerStateDidChange];
  }
}

- (CKAsyncTransaction *)ck_asyncTransaction
{
  CKAsyncTransaction *transaction = self.ck_currentAsyncLayerTransaction;
  if (transaction == nil) {
    NSHashTable *transactions = self.ck_asyncLayerTransactions;
    if (transactions == nil) {
      transactions = [[NSHashTable alloc] initWithOptions:NSHashTableStrongMemory|NSHashTableObjectPointerPersonality capacity:0];
      self.ck_asyncLayerTransactions = transactions;
    }
    transaction = [[CKAsyncTransaction alloc] initWithCallbackQueue:dispatch_get_main_queue() completionBlock:^(CKAsyncTransaction *completedTransaction, BOOL cancelled) {
      [transactions removeObject:completedTransaction];
      [self ck_asyncTransactionContainerDidCompleteTransaction:completedTransaction];
      if ([transactions count] == 0) {
        [self ck_asyncTransactionContainerStateDidChange];
      }
    }];
    [transactions addObject:transaction];
    self.ck_currentAsyncLayerTransaction = transaction;
    [self ck_asyncTransactionContainerWillBeginTransaction:transaction];
    if ([transactions count] == 1) {
      [self ck_asyncTransactionContainerStateDidChange];
    }
  }
  [[CKAsyncTransactionGroup mainTransactionGroup] addTransactionContainer:self];
  return transaction;
}

- (CALayer *)ck_parentTransactionContainer
{
  CALayer *containerLayer = self;
  while (containerLayer && !containerLayer.ck_isAsyncTransactionContainer) {
    containerLayer = containerLayer.superlayer;
  }
  return containerLayer;
}

@end

@implementation UIView (CKAsyncTransactionContainer)

- (BOOL)ck_isAsyncTransactionContainer
{
  return self.layer.ck_isAsyncTransactionContainer;
}

- (void)ck_setAsyncTransactionContainer:(BOOL)asyncTransactionContainer
{
  self.layer.ck_asyncTransactionContainer = asyncTransactionContainer;
}

- (CKAsyncTransactionContainerState)ck_asyncTransactionContainerState
{
  return self.layer.ck_asyncTransactionContainerState;
}

- (void)ck_cancelAsyncTransactions
{
  [self.layer ck_cancelAsyncTransactions];
}

- (void)ck_asyncTransactionContainerStateDidChange
{
  // No-op in the base class.
}

@end

static void *ck_asyncTransactionContainerKey = &ck_asyncTransactionContainerKey;

@implementation CALayer (CKAsyncTransactionContainerStorage)

- (BOOL)ck_isAsyncTransactionContainer
{
  return [objc_getAssociatedObject(self, ck_asyncTransactionContainerKey) boolValue];
}

- (void)ck_setAsyncTransactionContainer:(BOOL)asyncTransactionContainer
{
  objc_setAssociatedObject(self, ck_asyncTransactionContainerKey, @(asyncTransactionContainer), OBJC_ASSOCIATION_RETAIN);
}

@end
