/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentPreparationQueue.h"
#import "CKComponentPreparationQueueInternal.h"

#import <ComponentKit/CKAssert.h>
#import <ComponentKit/CKMacros.h>

#import "CKMutex.h"
#import "CKComponentLifecycleManager.h"
#import "CKComponentPreparationQueueListenerAnnouncer.h"

@implementation CKComponentPreparationInputItem
{
  CKSizeRange _constrainedSize;
}

- (instancetype)initWithReplacementModel:(id<NSObject>)replacementModel
                        lifecycleManager:(CKComponentLifecycleManager *)lifecycleManager
                         constrainedSize:(CKSizeRange)constrainedSize
                                 oldSize:(CGSize)oldSize
                                    UUID:(NSString *)UUID
                         sourceIndexPath:(NSIndexPath *)sourceIndexPath
                    destinationIndexPath:(NSIndexPath *)destinationIndexPath
                              changeType:(CKArrayControllerChangeType)changeType
                             passthrough:(BOOL)passthrough
                                 context:(id<NSObject>)context
{
  if (self = [super init]) {
    _replacementModel = replacementModel;
    _lifecycleManager = lifecycleManager;
    _constrainedSize = constrainedSize;
    _UUID = [UUID copy];
    _sourceIndexPath = [sourceIndexPath copy];
    _destinationIndexPath = [destinationIndexPath copy];
    _changeType = changeType;
    _passthrough = passthrough;
    _oldSize = oldSize;
    _context = context;
  }
  return self;
}

- (instancetype)init
{
  CK_NOT_DESIGNATED_INITIALIZER();
}

@synthesize replacementModel = _replacementModel;
@synthesize lifecycleManager = _lifecycleManager;
@synthesize UUID = _UUID;
@synthesize sourceIndexPath = _sourceIndexPath;
@synthesize destinationIndexPath = _destinationIndexPath;
@synthesize changeType = _changeType;
@synthesize passthrough = _passthrough;
@synthesize oldSize = _oldSize;
@synthesize context = _context;

- (CKSizeRange)constrainedSize
{
  return _constrainedSize;
}

@end

@implementation CKComponentPreparationOutputItem
{
  CKComponentLifecycleManagerState _lifecycleManagerState;
}

- (instancetype)initWithReplacementModel:(id<NSObject>)replacementModel
                        lifecycleManager:(CKComponentLifecycleManager *)lifecycleManager
                   lifecycleManagerState:(CKComponentLifecycleManagerState)lifecycleManagerState
                                 oldSize:(CGSize)oldSize
                                    UUID:(NSString *)UUID
                         sourceIndexPath:(NSIndexPath *)sourceIndexPath
                    destinationIndexPath:(NSIndexPath *)destinationIndexPath
                              changeType:(CKArrayControllerChangeType)changeType
                             passthrough:(BOOL)passthrough
                                 context:(id<NSObject>)context
{
  if (self = [super init]) {
    _replacementModel = replacementModel;
    _lifecycleManager = lifecycleManager;
    _lifecycleManagerState = lifecycleManagerState;
    _UUID = [UUID copy];
    _sourceIndexPath = [sourceIndexPath copy];
    _destinationIndexPath = [destinationIndexPath copy];
    _changeType = changeType;
    _passthrough = passthrough;
    _oldSize = oldSize;
    _context = context;
  }
  return self;
}

- (instancetype)init
{
  CK_NOT_DESIGNATED_INITIALIZER();
}

@synthesize replacementModel = _replacementModel;
@synthesize lifecycleManager = _lifecycleManager;
@synthesize UUID = _UUID;
@synthesize sourceIndexPath = _sourceIndexPath;
@synthesize destinationIndexPath = _destinationIndexPath;
@synthesize changeType = _changeType;
@synthesize passthrough = _passthrough;
@synthesize oldSize = _oldSize;
@synthesize context = _context;

- (CKComponentLifecycleManagerState)lifecycleManagerState
{
  return _lifecycleManagerState;
}

@end

@interface CKComponentPreparationQueueJob : NSObject {
  @public
  CKComponentPreparationInputBatch _batch;
  CKComponentPreparationQueueCallback _block;
}

- (instancetype)initWithBatch:(const CKComponentPreparationInputBatch &)batch
                        block:(CKComponentPreparationQueueCallback)block;
@end

@implementation CKComponentPreparationQueueJob

- (instancetype)initWithBatch:(const CKComponentPreparationInputBatch &)batch
                        block:(CKComponentPreparationQueueCallback)block
{
  self = [super init];
  if (self) {
    _batch = batch;
    _block = block;
  }
  return self;
}
@end

@implementation CKComponentPreparationQueue
{
  dispatch_queue_t _concurrentQueue;
  dispatch_queue_t _inputQueue;
  NSUInteger _queueWidth;

  CK::Mutex _lock;

  CKComponentPreparationQueueListenerAnnouncer *_announcer;
}

- (instancetype)initWithQueueWidth:(NSInteger)queueWidth
{
  if (self = [super init]) {
    _announcer = [[CKComponentPreparationQueueListenerAnnouncer alloc] init];
    _concurrentQueue = dispatch_queue_create("org.componentkit.component-preparation-queue.concurrent", DISPATCH_QUEUE_CONCURRENT);
    _inputQueue = dispatch_queue_create("org.componentkit.component-preparation-queue.serial", DISPATCH_QUEUE_SERIAL);
    if (queueWidth > 0) {
      _queueWidth = queueWidth;
    } else {
      CKFailAssert(@"The queue width is zero, the queue is blocked and no items will be computed");
      // Fallback to a sensible value
      _queueWidth = 5;
    }
  }
  return self;
}

- (instancetype)init 
{
  CK_NOT_DESIGNATED_INITIALIZER();
}

#pragma mark - Public

- (void)enqueueBatch:(const CKComponentPreparationInputBatch &)batch
               block:(CKComponentPreparationQueueCallback)block
{
  CKAssertMainThread();
  CKComponentPreparationQueueJob *job = [[CKComponentPreparationQueueJob alloc] initWithBatch:batch block:block];
  // We dispatch every batch processing operation to a serial queue as
  // each batch needs to be processed in order.
  dispatch_async(_inputQueue, ^{
    [self _processJob:job];
  });
}

#pragma mark - Private

- (void)_processJob:(CKComponentPreparationQueueJob *)job
{
  // All announcments are scheduled on the main thread
  dispatch_async(dispatch_get_main_queue(), ^{
    [_announcer componentPreparationQueue:self
             didStartPreparingBatchOfSize:job->_batch.items.size()
                                  batchID:(NSUInteger)job->_batch.ID];
  });

  // Each item in the batch is dispatched on a concurrent queue, we use a semaphore to regulate the width of the queue
  // and avoid contention.
  NSMutableArray *outputBatch = [NSMutableArray arrayWithCapacity:job->_batch.items.size()];
  dispatch_semaphore_t regulationSemaphore = dispatch_semaphore_create(_queueWidth);
  dispatch_group_t group = dispatch_group_create();
  for (CKComponentPreparationInputItem *inputItem : job->_batch.items) {
    dispatch_semaphore_wait(regulationSemaphore, DISPATCH_TIME_FOREVER);
    dispatch_group_async(group, _concurrentQueue, ^{
      CKComponentPreparationOutputItem *result = [[self class] prepare:inputItem];
      {
        CK::MutexLocker l(_lock);
        [outputBatch addObject:result];
      }
      dispatch_semaphore_signal(regulationSemaphore);
    });
  }

  // We have to wait until all the items are computed before calling back.
  // As soon as we return from this method _inputQueue may begin processing the next job.
  dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
  dispatch_async(dispatch_get_main_queue(), ^{
    [_announcer componentPreparationQueue:self
            didFinishPreparingBatchOfSize:job->_batch.items.size()
                                  batchID:(NSUInteger)job->_batch.ID];
    NSArray *outputBatchCopy = [outputBatch copy];
    if (job->_block) {
      job->_block(job->_batch.sections, job->_batch.ID, outputBatchCopy, job->_batch.isContiguousTailInsertion);
    }
  });
}

#pragma mark - Concurrent Queue

+ (CKComponentPreparationOutputItem *)prepare:(CKComponentPreparationInputItem *)inputItem
{
  CKComponentPreparationOutputItem *outputItem = nil;
  if (![inputItem isPassthrough]) {
    CKArrayControllerChangeType changeType = [inputItem changeType];
    if (changeType == CKArrayControllerChangeTypeInsert ||
        changeType == CKArrayControllerChangeTypeUpdate ||
        changeType == CKArrayControllerChangeTypeMove) {
      
      // Grab the lifecycle manager and use it to generate an layout the component tree
      CKComponentLifecycleManager *lifecycleManager = [inputItem lifecycleManager];
      CKComponentLifecycleManagerState state = [lifecycleManager prepareForUpdateWithModel:[inputItem replacementModel]
                                                                           constrainedSize:[inputItem constrainedSize]
                                                                                   context:[inputItem context]];

      outputItem = [[CKComponentPreparationOutputItem alloc] initWithReplacementModel:[inputItem replacementModel]
                                                                     lifecycleManager:lifecycleManager
                                                                lifecycleManagerState:state
                                                                              oldSize:[inputItem oldSize]
                                                                                 UUID:[inputItem UUID]
                                                                      sourceIndexPath:[inputItem sourceIndexPath]
                                                                 destinationIndexPath:[inputItem destinationIndexPath]
                                                                           changeType:[inputItem changeType]
                                                                          passthrough:[inputItem isPassthrough]
                                                                              context:[inputItem context]];
    } else if (changeType == CKArrayControllerChangeTypeDelete) {
      outputItem = [[CKComponentPreparationOutputItem alloc] initWithReplacementModel:[inputItem replacementModel]
                                                                     lifecycleManager:nil
                                                                lifecycleManagerState:CKComponentLifecycleManagerStateEmpty
                                                                              oldSize:[inputItem oldSize]
                                                                                 UUID:[inputItem UUID]
                                                                      sourceIndexPath:[inputItem sourceIndexPath]
                                                                 destinationIndexPath:[inputItem destinationIndexPath]
                                                                           changeType:[inputItem changeType]
                                                                          passthrough:[inputItem isPassthrough]
                                                                              context:[inputItem context]];
    } else {
      CKFailAssert(@"Unimplemented %d", changeType);
    }
  } else {
    outputItem = [[CKComponentPreparationOutputItem alloc] initWithReplacementModel:[inputItem replacementModel]
                                                                   lifecycleManager:[inputItem lifecycleManager]
                                                              lifecycleManagerState:CKComponentLifecycleManagerStateEmpty
                                                                            oldSize:[inputItem oldSize]
                                                                               UUID:[inputItem UUID]
                                                                    sourceIndexPath:[inputItem sourceIndexPath]
                                                               destinationIndexPath:[inputItem destinationIndexPath]
                                                                         changeType:[inputItem changeType]
                                                                        passthrough:[inputItem isPassthrough]
                                                                            context:[inputItem context]];
  }
  return outputItem;
}

#pragma mark - Listeners

- (void)addListener:(id<CKComponentPreparationQueueListener>)listener
{
  [_announcer addListener:listener];
}
- (void)removeListener:(id<CKComponentPreparationQueueListener>)listener
{
  [_announcer removeListener:listener];
}

@end
