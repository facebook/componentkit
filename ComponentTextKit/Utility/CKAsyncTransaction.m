/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant 
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKAsyncTransaction.h>

#import <ComponentKit/CKAssert.h>

@interface CKAsyncTransactionOperation : NSObject
- (id)initWithOperationCompletionBlock:(ck_async_transaction_operation_completion_block_t)operationCompletionBlock;
@property (nonatomic, copy) ck_async_transaction_operation_completion_block_t operationCompletionBlock;
@property (atomic, retain) id<NSObject> value; // set on bg queue by the operation block
@end

@implementation CKAsyncTransactionOperation

- (id)initWithOperationCompletionBlock:(ck_async_transaction_operation_completion_block_t)operationCompletionBlock
{
  if ((self = [super init])) {
    _operationCompletionBlock = [operationCompletionBlock copy];
  }
  return self;
}

- (void)dealloc
{
  CKAssertNil(_operationCompletionBlock, @"Should have been called and released before -dealloc");
}

- (void)callAndReleaseCompletionBlock:(BOOL)canceled;
{
  if (_operationCompletionBlock) {
    _operationCompletionBlock(self.value, canceled);
    // Guarantee that _operationCompletionBlock is released on _callbackQueue:
    self.operationCompletionBlock = nil;
  }
}

@end

@implementation CKAsyncTransaction
{
  dispatch_group_t _group;
  NSMutableArray *_operations;
}

#pragma mark - Lifecycle

- (id)initWithCallbackQueue:(dispatch_queue_t)callbackQueue
            completionBlock:(void(^)(CKAsyncTransaction *, BOOL))completionBlock
{
  if ((self = [self init])) {
    if (callbackQueue == NULL) {
      callbackQueue = dispatch_get_main_queue();
    }
    _callbackQueue = callbackQueue;
    _completionBlock = [completionBlock copy];

    _state = CKAsyncTransactionStateOpen;
  }
  return self;
}

- (void)dealloc
{
  // Uncommitted transactions break our guarantees about releasing completion blocks on callbackQueue.
  CKAssert(_state != CKAsyncTransactionStateOpen, @"Uncommitted CKAsyncTransactions are not allowed");
}

#pragma mark - Transaction Management

- (void)addAsyncOperationWithBlock:(ck_async_transaction_async_operation_block_t)block
                             queue:(dispatch_queue_t)queue
                        completion:(ck_async_transaction_operation_completion_block_t)completion
{
  CKAssertMainThread();
  CKAssert(_state == CKAsyncTransactionStateOpen, @"You can only add operations to open transactions");

  [self _ensureTransactionData];

  CKAsyncTransactionOperation *operation = [[CKAsyncTransactionOperation alloc] initWithOperationCompletionBlock:completion];
  [_operations addObject:operation];
  dispatch_group_async(_group, queue, ^{
    if (_state != CKAsyncTransactionStateCanceled) {
      dispatch_group_enter(_group);
      block(^(id<NSObject> value){
        operation.value = value;
        dispatch_group_leave(_group);
      });
    }
  });
}

- (void)addOperationWithBlock:(ck_async_transaction_operation_block_t)block
                        queue:(dispatch_queue_t)queue
                   completion:(ck_async_transaction_operation_completion_block_t)completion
{
  CKAssertMainThread();
  CKAssert(_state == CKAsyncTransactionStateOpen, @"You can only add operations to open transactions");

  [self _ensureTransactionData];

  CKAsyncTransactionOperation *operation = [[CKAsyncTransactionOperation alloc] initWithOperationCompletionBlock:completion];
  [_operations addObject:operation];
  dispatch_group_async(_group, queue, ^{
    if (_state != CKAsyncTransactionStateCanceled) {
      operation.value = block();
    }
  });
}

- (void)addCompletionBlock:(ck_async_transaction_completion_block_t)completion
{
  __weak typeof(self) weakSelf = self;
  [self addOperationWithBlock:^(){return (id<NSObject>)nil;} queue:_callbackQueue completion:^(id<NSObject> value, BOOL canceled) {
    typeof(self) strongSelf = weakSelf;
    completion(strongSelf, canceled);
  }];
}

- (void)cancel
{
  CKAssertMainThread();
  CKAssert(_state != CKAsyncTransactionStateOpen, @"You can only cancel a committed or already-canceled transaction");
  _state = CKAsyncTransactionStateCanceled;
}

- (void)commit
{
  CKAssertMainThread();
  CKAssert(_state == CKAsyncTransactionStateOpen, @"You cannot double-commit a transaction");
  _state = CKAsyncTransactionStateCommitted;

  if ([_operations count] == 0) {
    // Fast path: if a transaction was opened, but no operations were added, execute completion block synchronously.
    if (_completionBlock) {
      _completionBlock(self, NO);
    }
  } else {
    CKAssert(_group != NULL, @"If there are operations, dispatch group should have been created");
    dispatch_group_notify(_group, _callbackQueue, ^{
      BOOL isCanceled = (_state == CKAsyncTransactionStateCanceled);
      for (CKAsyncTransactionOperation *operation in _operations) {
        [operation callAndReleaseCompletionBlock:isCanceled];
      }
      if (_completionBlock) {
        _completionBlock(self, isCanceled);
      }
    });
  }
}

#pragma mark - Helper Methods

- (void)_ensureTransactionData
{
  // Lazily initialize _group and _operations to avoid overhead in the case where no operations are added to the transaction
  if (_group == NULL) {
    _group = dispatch_group_create();
  }
  if (_operations == nil) {
    _operations = [[NSMutableArray alloc] init];
  }
}

@end
