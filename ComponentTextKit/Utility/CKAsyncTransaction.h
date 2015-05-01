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

@class CKAsyncTransaction;

typedef void(^ck_async_transaction_completion_block_t)(CKAsyncTransaction *completedTransaction, BOOL canceled);
typedef id<NSObject>(^ck_async_transaction_operation_block_t)(void);
typedef void(^ck_async_transaction_operation_completion_block_t)(id<NSObject> value, BOOL canceled);
typedef void(^ck_async_transaction_complete_async_operation_block_t)(id<NSObject> value);
typedef void(^ck_async_transaction_async_operation_block_t)(ck_async_transaction_complete_async_operation_block_t completeOperationBlock);

/**
 State is initially CKAsyncTransactionStateOpen.
 Every transaction MUST be committed. It is an error to fail to commit a transaction.
 A committed transaction MAY be canceled. You cannot cancel an open (uncommitted) transaction.
 */
typedef NS_ENUM(NSUInteger, CKAsyncTransactionState) {
  CKAsyncTransactionStateOpen = 0,
  CKAsyncTransactionStateCommitted,
  CKAsyncTransactionStateCanceled,
};

/**
 @summary CKAsyncTransaction provides lightweight transaction semantics for asynchronous operations.

 @desc CKAsyncTransaction provides the following properties:

 - Transactions group an arbitrary number of operations, each consisting of an execution block and a completion block.
 - The execution block returns a single object that will be passed to the completion block.
 - Execution blocks added to a transaction will run in parallel on the global background dispatch queues;
   the completion blocks are dispatched to the callback queue.
 - Every operation completion block is guaranteed to execute, regardless of cancelation.
   However, execution blocks may be skipped if the transaction is canceled.
 - Operation completion blocks are always executed in the order they were added to the transaction, assuming the
   callback queue is serial of course.
 */
@interface CKAsyncTransaction : NSObject

/**
 @summary Initialize a transaction that can start collecting async operations.

 @see initWithCallbackQueue:commitBlock:completionBlock:executeConcurrently:
 @param callbackQueue The dispatch queue that the completion blocks will be called on.
 @param completionBlock A block that is called when the transaction is completed. May be NULL.
 */
- (id)initWithCallbackQueue:(dispatch_queue_t)callbackQueue
            completionBlock:(ck_async_transaction_completion_block_t)completionBlock;

/**
 The dispatch queue that the completion blocks will be called on.
 */
@property (nonatomic, retain, readonly) dispatch_queue_t callbackQueue;

/**
 A block that is called when the transaction is completed.
 */
@property (nonatomic, copy, readonly) ck_async_transaction_completion_block_t completionBlock;

/**
 The state of the transaction.
 @see CKAsyncTransactionState
 */
@property (nonatomic, readonly) CKAsyncTransactionState state;

/**
 @summary Adds a synchronous operation to the transaction.  The execution block will be executed immediately.

 @desc The block will be executed on the specified queue and is expected to complete synchronously.  The async
 transaction will wait for all operations to execute on their appropriate queues, so the blocks may still be executing
 async if they are running on a concurrent queue, even though the work for this block is synchronous.

 @param block The execution block that will be executed on a background queue.  This is where the expensive work goes.
 @param queue The dispatch queue on which to execute the block.
 @param completion The completion block that will be executed with the output of the execution block when all of the
 operations in the transaction are completed. Executed and released on callbackQueue.
 */
- (void)addOperationWithBlock:(ck_async_transaction_operation_block_t)block
                        queue:(dispatch_queue_t)queue
                   completion:(ck_async_transaction_operation_completion_block_t)completion;

/**
 @summary Adds an async operation to the transaction.  The execution block will be executed immediately.

 @desc The block will be executed on the specified queue and is expected to complete asynchronously.  The block will be
 supplied with a completion block that can be executed once its async operation is completed.  This is useful for
 network downloads and other operations that have an async API.

 WARNING: Consumers MUST call the completeOperationBlock passed into the work block, or objects will be leaked!

 @param block The execution block that will be executed on a background queue.  This is where the expensive work goes.
 @param queue The dispatch queue on which to execute the block.
 @param completion The completion block that will be executed with the output of the execution block when all of the
 operations in the transaction are completed. Executed and released on callbackQueue.
 */
- (void)addAsyncOperationWithBlock:(ck_async_transaction_async_operation_block_t)block
                             queue:(dispatch_queue_t)queue
                        completion:(ck_async_transaction_operation_completion_block_t)completion;


/**
 @summary Adds a block to run on the completion of the async transaction.

 @param queue The dispatch queue on which to execute the block.
 @param completion The completion block that will be executed with the output of the execution block when all of the
 operations in the transaction are completed. Executed and released on callbackQueue.
 */

- (void)addCompletionBlock:(ck_async_transaction_completion_block_t)completion;

/**
 @summary Cancels all operations in the transaction.

 @desc You can only cancel a commmitted transaction.

 All completion blocks are always called, regardless of cancelation. Execution blocks may be skipped if canceled.
 */
- (void)cancel;

/**
 @summary Marks the end of adding operations to the transaction.

 @desc You MUST commit every transaction you create. It is an error to create a transaction that is never committed.

 When all of the operations that have been added have completed the transaction will execute their completion
 blocks.

 If no operations were added to this transaction, invoking commit will execute the transaction's completion block synchronously.
 */
- (void)commit;

@end
